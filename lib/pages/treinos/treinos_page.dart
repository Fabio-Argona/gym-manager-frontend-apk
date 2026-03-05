import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_treinoabc/services/treino_service.dart';
import 'package:flutter_application_treinoabc/services/exercicio_service.dart';
import 'package:flutter_application_treinoabc/services/exercicio_realizado_service.dart';

import 'treinos_design_tokens.dart';
import 'treinos_shared_widgets.dart';
import 'treinos_dialogs.dart';
import 'grupo_card_widget.dart';

class TreinosPage extends StatefulWidget {
  final String nome;
  const TreinosPage({super.key, required this.nome});

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  // ─── State ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _grupos = [];
  final Set<String> _gruposExpandidos = {};
  bool _carregando = true;

  final Map<String, bool> _exerciciosEmExecucao = {};
  final Map<String, int> _tempoExercicio = {};
  final Map<String, Timer?> _cronometros = {};
  final Map<String, DateTime> _ultimaConclusao = {};
  final Map<String, String> _treinoIdPorGrupo = {};
  final Map<String, int> _tempoRealPorGrupo = {};

  // ─── Lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _carregarConclusoes();
    _carregarGrupos();
  }

  @override
  void dispose() {
    for (final timer in _cronometros.values) {
      timer?.cancel();
    }
    _cronometros.clear();
    _tempoExercicio.clear();
    _exerciciosEmExecucao.clear();
    _ultimaConclusao.clear();
    super.dispose();
  }

  // ─── Persistence ────────────────────────────────────────────────────────

  Future<void> _carregarConclusoes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('conclusao_'));
    final Map<String, DateTime> carregados = {};
    for (final key in keys) {
      final valor = prefs.getString(key);
      if (valor != null) {
        final dt = DateTime.tryParse(valor);
        if (dt != null) {
          carregados[key.replaceFirst('conclusao_', '')] = dt;
        }
      }
    }
    if (mounted) setState(() => _ultimaConclusao.addAll(carregados));
  }

  Future<void> _salvarConclusao(String exercicioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'conclusao_$exercicioId',
      DateTime.now().toIso8601String(),
    );
  }

  // ─── Data loading ────────────────────────────────────────────────────────

  Future<void> _carregarGrupos() async {
    if (!mounted) return;
    setState(() => _carregando = true);

    try {
      final grupos = await _carregarGruposComExercicios();

      const ordemGrupos = [
        'Peito',
        'Costas',
        'Tríceps',
        'Bíceps',
        'Ombro',
        'Perna',
        'Abdômen',
        'Panturrilha',
      ];
      grupos.sort((a, b) {
        final ia = ordemGrupos.indexOf(a['nome']);
        final ib = ordemGrupos.indexOf(b['nome']);
        return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
      });

      if (!mounted) return;
      setState(() {
        _grupos = grupos;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      showCustomSnackBar(
        context,
        'Erro ao carregar grupos: $e',
        backgroundColor: Colors.redAccent.shade100,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _carregarGruposComExercicios() async {
    final grupos = await TreinoService().listarGrupos();

    List<Map<String, dynamic>> exercicios = [];
    try {
      exercicios = await ExercicioService().listarExercicios();
    } catch (e) {
      debugPrint('Aviso: não foi possível carregar exercícios: $e');
    }

    final Map<String, List<Map<String, dynamic>>> exerciciosPorGrupo = {};
    for (final ex in exercicios) {
      final grupoId = (ex['grupoId'] ?? ex['grupo_id'])?.toString();
      if (grupoId != null) {
        exerciciosPorGrupo.putIfAbsent(grupoId, () => []).add(ex);
      }
    }

    for (final grupo in grupos) {
      final id = grupo['id']?.toString();
      final lista = (exerciciosPorGrupo[id] ?? [])
          .where((ex) => ex['ativo'] == true)
          .toList();

      lista.sort((a, b) {
        final ga = (a['grupoMuscular'] ?? a['grupo_muscular'] ?? '')
            .toString()
            .toLowerCase();
        final gb = (b['grupoMuscular'] ?? b['grupo_muscular'] ?? '')
            .toString()
            .toLowerCase();

        int prioridade(String g) {
          if (g == 'peito') return 0;
          if (g == 'costas') return 1;
          return 2;
        }

        final pa = prioridade(ga);
        final pb = prioridade(gb);
        if (pa != pb) return pa.compareTo(pb);
        return ga.compareTo(gb);
      });

      grupo['exercicios'] = lista;
    }

    return grupos;
  }

  // ─── Grupo actions ───────────────────────────────────────────────────────

  Future<void> _criarGrupo() async {
    final controller = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => GrupoDialog(nomeInicial: '', controller: controller),
    );

    if (nome != null && nome.isNotEmpty) {
      _showLoading();
      try {
        final novoGrupo = await TreinoService().criarGrupo(nome);
        if (mounted) {
          Navigator.pop(context);
          setState(() {
            _grupos.add({
              'id': novoGrupo['id'],
              'nome': novoGrupo['nome'],
              'exercicios': [],
            });
          });
          showCustomSnackBar(
            context,
            'Grupo "${novoGrupo['nome']}" criado com sucesso!',
            success: true,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          showCustomSnackBar(
            context,
            'Erro ao criar grupo: $e',
            backgroundColor: Colors.redAccent.shade100,
          );
        }
      }
    }
  }

  Future<void> _editarGrupo(String id, String nomeAtual) async {
    final controller = TextEditingController(text: nomeAtual);
    final novoNome = await showDialog<String>(
      context: context,
      builder: (_) =>
          GrupoDialog(nomeInicial: nomeAtual, controller: controller),
    );

    if (novoNome != null && novoNome.isNotEmpty) {
      try {
        await TreinoService().editarGrupo(id, novoNome);
        await _carregarGrupos();
        if (!mounted) return;
        showCustomSnackBar(
          context,
          'Grupo editado com sucesso!',
          success: true,
        );
      } catch (e) {
        if (!mounted) return;
        showCustomSnackBar(
          context,
          'Erro ao editar grupo',
          backgroundColor: Colors.redAccent.shade100,
        );
      }
    }
  }

  Future<void> _excluirGrupo(String id, String nomeGrupo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Excluir grupo',
        message: 'Excluir "$nomeGrupo"?\nTodos os exercícios serão removidos.',
        confirmLabel: 'Excluir',
        danger: true,
      ),
    );

    if (confirmar == true) {
      try {
        await TreinoService().excluirGrupoComExercicios(id);
        await _carregarGrupos();
        if (mounted) {
          showCustomSnackBar(
            context,
            'Grupo e exercícios excluídos com sucesso',
            success: true,
          );
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(
            context,
            'Erro ao excluir grupo: $e',
            backgroundColor: Colors.redAccent.shade100,
          );
        }
      }
    }
  }

  // ─── Exercício actions ───────────────────────────────────────────────────

  static const _gruposMusculares = [
    'Peito',
    'Costas',
    'Pernas',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Abdômen',
    'Glúteos',
  ];

  Future<void> _adicionarExercicio(String grupoId) async {
    final nomeCtrl = TextEditingController();
    final seriesCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    final pesoCtrl = TextEditingController(text: '10');
    final obsCtrl = TextEditingController();

    final grupoMuscular = await showDialog<String>(
      context: context,
      builder: (_) => ExercicioFormDialog(
        titulo: 'Adicionar Exercício',
        nomeController: nomeCtrl,
        seriesController: seriesCtrl,
        repeticoesController: repsCtrl,
        pesoController: pesoCtrl,
        obsController: obsCtrl,
        gruposMusculares: _gruposMusculares,
        grupoInicial: _gruposMusculares.first,
        autofocus: true,
      ),
    );

    if (grupoMuscular != null) {
      _showLoading();
      await ExercicioService().criarExercicio({
        'nome': nomeCtrl.text.trim(),
        'grupoMuscular': grupoMuscular,
        'series': int.tryParse(seriesCtrl.text) ?? 0,
        'repeticoes': int.tryParse(repsCtrl.text) ?? 0,
        'pesoInicial': double.tryParse(pesoCtrl.text) ?? 0.0,
        'observacao': obsCtrl.text.trim(),
        'grupoId': grupoId,
      });
      if (mounted) {
        await _carregarGrupos();
        if (!mounted) return;
        Navigator.pop(context);
        showCustomSnackBar(
          context,
          'Exercício adicionado com sucesso!',
          success: true,
        );
      }
    }
  }

  Future<void> _editarExercicio(Map<String, dynamic> exercicio) async {
    final nomeCtrl = TextEditingController(text: exercicio['nome'] ?? '');
    final seriesCtrl = TextEditingController(
      text: exercicio['series']?.toString() ?? '',
    );
    final repsCtrl = TextEditingController(
      text: exercicio['repeticoes']?.toString() ?? '',
    );
    final pesoCtrl = TextEditingController(
      text: exercicio['pesoInicial']?.toString() ?? '',
    );
    final obsCtrl = TextEditingController(text: exercicio['observacao'] ?? '');

    final grupoAtual =
        exercicio['grupoMuscular'] ??
        exercicio['grupo_muscular'] ??
        _gruposMusculares.first;

    final grupoMuscular = await showDialog<String>(
      context: context,
      builder: (_) => ExercicioFormDialog(
        titulo: 'Editar Exercício',
        nomeController: nomeCtrl,
        seriesController: seriesCtrl,
        repeticoesController: repsCtrl,
        pesoController: pesoCtrl,
        obsController: obsCtrl,
        gruposMusculares: _gruposMusculares,
        grupoInicial: grupoAtual,
      ),
    );

    if (grupoMuscular != null) {
      await ExercicioService().editarExercicio({
        'id': exercicio['id'],
        'grupoId': exercicio['grupoId'],
        'nome': nomeCtrl.text.trim(),
        'grupoMuscular': grupoMuscular,
        'series': int.tryParse(seriesCtrl.text.trim()) ?? 0,
        'repeticoes': int.tryParse(repsCtrl.text.trim()) ?? 0,
        'pesoInicial': double.tryParse(pesoCtrl.text.trim()) ?? 0.0,
        'observacao': obsCtrl.text.trim(),
        'ativo': true,
      });
      await _carregarGrupos();
      if (mounted) {
        showCustomSnackBar(
          context,
          'Exercício editado com sucesso!',
          success: true,
        );
      }
    }
  }

  Future<void> _confirmarExclusaoExercicio(
    Map<String, dynamic> exercicio,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Excluir exercício',
        message: 'Excluir "${exercicio['nome']}"?',
        confirmLabel: 'Excluir',
        danger: true,
      ),
    );

    if (confirmar == true) {
      await ExercicioService().editarExercicio({
        'id': exercicio['id'],
        'grupoId': exercicio['grupoId'],
        'nome': exercicio['nome'],
        'grupoMuscular': exercicio['grupoMuscular'],
        'series': exercicio['series'],
        'repeticoes': exercicio['repeticoes'],
        'pesoInicial': exercicio['pesoInicial'],
        'observacao': exercicio['observacao'],
        'ativo': false,
      });
      await _carregarGrupos();
      if (mounted) {
        showCustomSnackBar(
          context,
          'Exercício excluído com sucesso!',
          success: true,
        );
      }
    }
  }

  // ─── Treino session ──────────────────────────────────────────────────────

  Future<String?> _iniciarTreino(String grupoId, String grupoNome) async {
    final hoje = DateTime.now();
    final dataFormatada =
        '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

    final treinoId = await ExercicioRealizadoService().iniciarTreino(
      grupoId,
      dataFormatada,
      grupoNome: grupoNome,
    );

    if (treinoId != null) {
      _treinoIdPorGrupo[grupoId] = treinoId;
      return treinoId;
    }
    if (mounted) {
      showCustomSnackBar(
        context,
        'Erro ao iniciar treino',
        backgroundColor: Colors.redAccent.shade100,
      );
    }
    return null;
  }

  Future<void> _iniciarExercicio(
    Map<String, dynamic> ex,
    String grupoId,
    String grupoNome,
  ) async {
    if (_treinoIdPorGrupo[grupoId] == null) {
      final tid = await _iniciarTreino(grupoId, grupoNome);
      if (tid == null || !mounted) return;
    }

    final sucesso = await ExercicioService().atualizarStatus(
      ex['treinoExercicioAlunoId'] ?? ex['id'],
      'EM_EXECUCAO',
    );
    if (sucesso) {
      setState(() {
        _exerciciosEmExecucao[ex['id']] = true;
        _cronometros[ex['id']]?.cancel();
        _cronometros[ex['id']] = Timer.periodic(
          const Duration(seconds: 1),
          (_) => setState(
            () => _tempoExercicio[ex['id']] =
                (_tempoExercicio[ex['id']] ?? 0) + 1,
          ),
        );
      });
    }
  }

  Future<void> _mostrarDialogRegistroExercicio(
    Map<String, dynamic> ex,
    String grupoId,
    String grupoNome,
  ) async {
    final treinoId =
        _treinoIdPorGrupo[grupoId] ?? await _iniciarTreino(grupoId, grupoNome);
    if (treinoId == null || !mounted) return;

    final hoje = DateTime.now();
    final dataFormatada =
        '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

    final seriesCtrl = TextEditingController(
      text: ex['series']?.toString() ?? '',
    );
    final repsCtrl = TextEditingController(
      text: ex['repeticoes']?.toString() ?? '',
    );
    final pesoCtrl = TextEditingController(
      text: (ex['pesoInicial'] ?? 0.0).toString(),
    );
    final obsCtrl = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => RegistroExercicioDialog(
        nomeExercicio: ex['nome'] ?? 'Registrar Exercício',
        seriesController: seriesCtrl,
        repeticoesController: repsCtrl,
        pesoController: pesoCtrl,
        obsController: obsCtrl,
      ),
    );

    if (confirmar != true || !mounted) return;

    await _salvarRegistroExercicio(
      ex,
      treinoId,
      dataFormatada,
      seriesCtrl,
      repsCtrl,
      pesoCtrl,
      obsCtrl,
    );

    if (!mounted) return;

    await ExercicioService().atualizarStatus(
      ex['treinoExercicioAlunoId'] ?? ex['id'],
      'REALIZADO',
    );

    setState(() {
      _tempoRealPorGrupo[grupoId] =
          (_tempoRealPorGrupo[grupoId] ?? 0) + (_tempoExercicio[ex['id']] ?? 0);
      _exerciciosEmExecucao[ex['id']] = false;
      _ultimaConclusao[ex['id']] = DateTime.now();
      _cronometros[ex['id']]?.cancel();
      _cronometros[ex['id']] = null;
    });
    await _salvarConclusao(ex['id']);
  }

  Future<void> _salvarRegistroExercicio(
    Map<String, dynamic> exercicio,
    String treinoId,
    String dataFormatada,
    TextEditingController seriesCtrl,
    TextEditingController repsCtrl,
    TextEditingController pesoCtrl,
    TextEditingController obsCtrl,
  ) async {
    _showLoading();

    final sucesso = await ExercicioRealizadoService().registrarExercicio(
      treinoRealizadoId: treinoId,
      exercicioId: exercicio['id'] ?? '',
      seriesRealizadas: int.tryParse(seriesCtrl.text) ?? 0,
      repeticoesRealizadas: int.tryParse(repsCtrl.text) ?? 0,
      pesoUtilizado: double.tryParse(pesoCtrl.text) ?? 0.0,
      dataSessao: dataFormatada,
      observacoes: obsCtrl.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);

    showCustomSnackBar(
      context,
      sucesso
          ? '${exercicio['nome']} registrado com sucesso!'
          : 'Erro ao registrar exercício',
      success: sucesso,
      backgroundColor: sucesso ? null : Colors.redAccent.shade100,
    );
  }

  // ─── Reorder ─────────────────────────────────────────────────────────────

  void _reordenarExercicios(
    Map<String, dynamic> grupo,
    int oldIndex,
    int newIndex,
  ) {
    setState(() {
      final ativos = (grupo['exercicios'] as List)
          .where((ex) => ex['ativo'] == true)
          .toList();
      final inativos = (grupo['exercicios'] as List)
          .where((ex) => ex['ativo'] != true)
          .toList();
      final item = ativos.removeAt(oldIndex);
      ativos.insert(newIndex, item);
      grupo['exercicios'] = [...ativos, ...inativos];
    });
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final diaSemana = getDiaSemana(hoje);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _TreinosHeader(diaSemana: diaSemana, onNovaTreino: _criarGrupo),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (_grupos.isEmpty) return const _EmptyState();
    return RefreshIndicator(
      onRefresh: _carregarGrupos,
      color: kPrimary,
      backgroundColor: kCard,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24, top: 4),
        itemCount: _grupos.length,
        itemBuilder: (context, index) => _buildGrupoCard(_grupos[index]),
      ),
    );
  }

  Widget _buildGrupoCard(Map<String, dynamic> grupo) {
    final grupoId = grupo['id']?.toString() ?? '';
    return GrupoCard(
      grupo: grupo,
      expandido: _gruposExpandidos.contains(grupoId),
      exerciciosEmExecucao: _exerciciosEmExecucao,
      ultimaConclusao: _ultimaConclusao,
      tempoExercicio: _tempoExercicio,
      tempoRealPorGrupo: _tempoRealPorGrupo,
      onEditar: () => _editarGrupo(grupoId, grupo['nome'] ?? ''),
      onExcluir: () => _excluirGrupo(grupoId, grupo['nome'] ?? ''),
      onToggleExpand: () => setState(() {
        if (_gruposExpandidos.contains(grupoId)) {
          _gruposExpandidos.remove(grupoId);
        } else {
          _gruposExpandidos.add(grupoId);
        }
      }),
      onAdicionarExercicio: () => _adicionarExercicio(grupoId),
      onEditarExercicio: _editarExercicio,
      onExcluirExercicio: _confirmarExclusaoExercicio,
      onIniciarExercicio: (ex) =>
          _iniciarExercicio(ex, grupoId, grupo['nome'] ?? ''),
      onEncerrarExercicio: (ex) =>
          _mostrarDialogRegistroExercicio(ex, grupoId, grupo['nome'] ?? ''),
      onReordenar: (oldIdx, newIdx) =>
          _reordenarExercicios(grupo, oldIdx, newIdx),
    );
  }
}

// ─── Page-level widgets ───────────────────────────────────────────────────────

class _TreinosHeader extends StatelessWidget {
  final String diaSemana;
  final VoidCallback onNovaTreino;

  const _TreinosHeader({required this.diaSemana, required this.onNovaTreino});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diaSemana,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextHint,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  'Meus Treinos',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 340) {
                  return const SizedBox.shrink();
                }
                return const Text('Novo Treino');
              },
            ),
            onPressed: onNovaTreino,
            style: OutlinedButton.styleFrom(
              foregroundColor: kAccent,
              side: const BorderSide(color: kBorder, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              minimumSize: const Size(36, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: kPrimary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum grupo ainda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque em "Novo Treino" para começar',
            style: TextStyle(color: kTextHint, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
