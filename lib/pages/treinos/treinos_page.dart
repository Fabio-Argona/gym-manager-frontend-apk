import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_treinoabc/services/treino_service.dart';
import 'package:flutter_application_treinoabc/services/exercicio_service.dart';
import 'package:flutter_application_treinoabc/services/exercicio_realizado_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg1 = Color(0xFF0D0D1A);
const _bg2 = Color(0xFF1A1040);
const _card = Color(0xFF1C1B2E);
const _cardEx = Color(0xFF201F35);
const _primary = Color(0xFF7C3AED);
const _primaryDark = Color(0xFF5B21B6);
const _accent = Color(0xFF06B6D4);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _error = Color(0xFFEF4444);
const _inputBg = Color(0xFF252438);
const _border = Color(0xFF3A3857);
const _textHint = Color(0xFF8884A8);
const _textSub = Color(0xFFB0ADCC);

class TreinosPage extends StatefulWidget {
  final String nome;
  const TreinosPage({super.key, required this.nome});

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

// Função auxiliar para obter o dia da semana em português
String _getDiaSemana(DateTime data) {
  const diasSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  return diasSemana[data.weekday - 1];
}

// Cor de fundo sutil do card por grupo muscular
Color _corCardGrupo(String? grupo) {
  switch (grupo?.toLowerCase()) {
    case 'peito':
      return const Color(0xFF231E3A);
    case 'costas':
      return const Color(0xFF1A2035);
    case 'pernas':
      return const Color(0xFF1A2530);
    case 'ombros':
      return const Color(0xFF28202A);
    case 'bíceps':
      return const Color(0xFF281E1A);
    case 'tríceps':
      return const Color(0xFF1A2620);
    case 'abdômen':
      return const Color(0xFF272015);
    case 'glúteos':
      return const Color(0xFF28182A);
    default:
      return _cardEx;
  }
}

// Cor do badge/tag por grupo muscular
Color _corTagGrupo(String? grupo) {
  switch (grupo?.toLowerCase()) {
    case 'peito':
      return const Color(0xFFA07AFF);
    case 'costas':
      return const Color(0xFF7AABFF);
    case 'pernas':
      return const Color(0xFF7ADFB8);
    case 'ombros':
      return const Color(0xFFFF9EA0);
    case 'bíceps':
      return const Color(0xFFFFCA7A);
    case 'tríceps':
      return const Color(0xFF90EE90);
    case 'abdômen':
      return const Color(0xFFFFE57A);
    case 'glúteos':
      return const Color(0xFFFF9BE0);
    default:
      return _textHint;
  }
}

class _TreinosPageState extends State<TreinosPage> {
  List<Map<String, dynamic>> _grupos = [];
  final Set<String> _gruposExpandidos = {};
  bool _carregando = true;
  final Map<String, bool> _exerciciosEmExecucao = {};

  final Map<String, int> _tempoExercicio = {};
  final Map<String, Timer?> _cronometros = {};

  final Map<String, DateTime> _ultimaConclusao = {};
  final Map<String, String> _treinoIdPorGrupo = {};
  final Map<String, int> _tempoRealPorGrupo = {};

  @override
  void initState() {
    super.initState();
    _carregarConclusoes();
    _carregarGrupos();
  }

  /// Carrega do disco as datas de conclusão salvas anteriormente
  Future<void> _carregarConclusoes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('conclusao_'));
    final Map<String, DateTime> carregados = {};
    for (final key in keys) {
      final valor = prefs.getString(key);
      if (valor != null) {
        final dt = DateTime.tryParse(valor);
        if (dt != null) {
          final id = key.replaceFirst('conclusao_', '');
          carregados[id] = dt;
        }
      }
    }
    if (mounted) {
      setState(() => _ultimaConclusao.addAll(carregados));
    }
  }

  /// Persiste a data de conclusão de um exercício no disco
  Future<void> _salvarConclusao(String exercicioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'conclusao_$exercicioId',
      DateTime.now().toIso8601String(),
    );
  }

  // ─── Snackbar padronizado ────────────────────────────────────────────────
  void showCustomSnackBar(
    BuildContext context,
    String mensagem, {
    Color? backgroundColor,
    bool success = false,
    bool warning = false,
  }) {
    final isSuccess =
        success ||
        (backgroundColor == Colors.greenAccent ||
            backgroundColor == Colors.green);
    final isWarning = warning;
    final color = isSuccess ? _success : (isWarning ? _warning : _error);
    final icon = isSuccess
        ? Icons.check_circle_outline_rounded
        : (isWarning
              ? Icons.warning_amber_rounded
              : Icons.error_outline_rounded);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mensagem,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  @override
  void dispose() {
    // Cancela todos os cronômetros ativos
    for (var timer in _cronometros.values) {
      timer?.cancel();
    }

    // Limpa os mapas para evitar referências antigas
    _cronometros.clear();
    _tempoExercicio.clear();
    _exerciciosEmExecucao.clear();
    _ultimaConclusao.clear();

    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _carregarGruposComExercicios() async {
    final grupos = await TreinoService().listarGrupos();

    List<Map<String, dynamic>> exercicios = [];
    try {
      exercicios = await ExercicioService().listarExercicios();
    } catch (e) {
      // Se exercícios falharem, ainda mostra os grupos vazios
      debugPrint('Aviso: não foi possível carregar exercícios: $e');
    }

    final Map<String, List<Map<String, dynamic>>> exerciciosPorGrupo = {};
    for (var ex in exercicios) {
      final grupoId = (ex['grupoId'] ?? ex['grupo_id'])?.toString();
      if (grupoId != null) {
        exerciciosPorGrupo.putIfAbsent(grupoId, () => []).add(ex);
      }
    }

    for (var grupo in grupos) {
      final id = grupo['id']?.toString();
      var listaExercicios = (exerciciosPorGrupo[id] ?? [])
          .where((ex) => ex['ativo'] == true)
          .toList();

      listaExercicios.sort((a, b) {
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

      grupo['exercicios'] = listaExercicios;
    }

    return grupos;
  }

  Future<void> _criarGrupo() async {
    final nome = await _mostrarDialogoGrupo();
    if (nome != null && nome.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final novoGrupo = await TreinoService().criarGrupo(nome);

        if (mounted) {
          Navigator.pop(context); // fecha o loading

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
            backgroundColor: Colors.greenAccent,
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
    final novoNome = await _mostrarDialogoGrupo(nomeAtual);
    if (novoNome != null && novoNome.isNotEmpty) {
      try {
        await TreinoService().editarGrupo(id, novoNome);
        await _carregarGrupos();

        if (!mounted) return;
        showCustomSnackBar(
          context,
          'Grupo editado com sucesso!',
          backgroundColor: Colors.greenAccent,
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
      builder: (context) => _buildConfirmDialog(
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
            backgroundColor: Colors.greenAccent,
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

  Future<void> _confirmarExclusaoExercicio(
    Map<String, dynamic> exercicio,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
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
      showCustomSnackBar(
        context,
        'Exercício excluído com sucesso!',
        backgroundColor: Colors.greenAccent,
      );
    }
  }

  Future<void> _adicionarExercicio(String grupoId) async {
    final nomeController = TextEditingController();
    final seriesController = TextEditingController(text: '3');
    final repeticoesController = TextEditingController(text: '10');
    final pesoController = TextEditingController(text: '10');
    final obsController = TextEditingController();

    final gruposMusculares = [
      'Peito',
      'Costas',
      'Pernas',
      'Ombros',
      'Bíceps',
      'Tríceps',
      'Abdômen',
      'Glúteos',
    ];
    String grupoSelecionado = gruposMusculares.first;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => _buildExercicioDialog(
        titulo: 'Adicionar Exercício',
        nomeController: nomeController,
        seriesController: seriesController,
        repeticoesController: repeticoesController,
        pesoController: pesoController,
        obsController: obsController,
        gruposMusculares: gruposMusculares,
        grupoInicial: grupoSelecionado,
        onGrupoChanged: (v) => grupoSelecionado = v ?? grupoSelecionado,
        autofocus: true,
      ),
    );

    if (confirmar == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ExercicioService().criarExercicio({
        'nome': nomeController.text.trim(),
        'grupoMuscular': grupoSelecionado,
        'series': int.tryParse(seriesController.text) ?? 0,
        'repeticoes': int.tryParse(repeticoesController.text) ?? 0,
        'pesoInicial': double.tryParse(pesoController.text) ?? 0.0,
        'observacao': obsController.text.trim(),
        'grupoId': grupoId,
      });

      if (mounted) {
        await _carregarGrupos();
        Navigator.pop(context);
        showCustomSnackBar(
          context,
          'Exercício adicionado com sucesso!',
          backgroundColor: Colors.greenAccent,
        );
      }
    }
  }

  Future<void> _editarExercicio(Map<String, dynamic> exercicio) async {
    final nomeController = TextEditingController(text: exercicio['nome'] ?? '');
    final seriesController = TextEditingController(
      text: exercicio['series']?.toString() ?? '',
    );
    final repeticoesController = TextEditingController(
      text: exercicio['repeticoes']?.toString() ?? '',
    );
    final pesoController = TextEditingController(
      text: exercicio['pesoInicial']?.toString() ?? '',
    );
    final obsController = TextEditingController(
      text: exercicio['observacao'] ?? '',
    );

    final gruposMusculares = [
      'Peito',
      'Costas',
      'Pernas',
      'Ombros',
      'Bíceps',
      'Tríceps',
      'Abdômen',
      'Glúteos',
    ];
    String grupoSelecionado =
        exercicio['grupoMuscular'] ??
        exercicio['grupo_muscular'] ??
        gruposMusculares.first;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => _buildExercicioDialog(
        titulo: 'Editar Exercício',
        nomeController: nomeController,
        seriesController: seriesController,
        repeticoesController: repeticoesController,
        pesoController: pesoController,
        obsController: obsController,
        gruposMusculares: gruposMusculares,
        grupoInicial: grupoSelecionado,
        onGrupoChanged: (v) => grupoSelecionado = v ?? grupoSelecionado,
      ),
    );

    if (confirmar == true) {
      await ExercicioService().editarExercicio({
        'id': exercicio['id'],
        'grupoId': exercicio['grupoId'],
        'nome': nomeController.text.trim(),
        'grupoMuscular': grupoSelecionado,
        'series': int.tryParse(seriesController.text.trim()) ?? 0,
        'repeticoes': int.tryParse(repeticoesController.text.trim()) ?? 0,
        'pesoInicial': double.tryParse(pesoController.text.trim()) ?? 0.0,
        'observacao': obsController.text.trim(),
        'ativo': true,
      });
      await _carregarGrupos();
      showCustomSnackBar(
        context,
        'Exercício editado com sucesso!',
        backgroundColor: Colors.greenAccent,
      );
    }
  }

  Future<String?> _mostrarDialogoGrupo([String nomeInicial = '']) {
    final controller = TextEditingController(text: nomeInicial);
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: _primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    nomeInicial.isEmpty ? 'Criar Grupo' : 'Editar Grupo',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: controller,
                label: 'Nome do grupo',
                icon: Icons.label_outline_rounded,
                autofocus: true,
                capitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: _textHint),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  _primaryButton(
                    label: 'Salvar',
                    onPressed: () => Navigator.pop(context, controller.text),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // INICIAR TREINO
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
    } else {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Erro ao iniciar treino',
          backgroundColor: Colors.redAccent.shade100,
        );
      }
      return null;
    }
  }

  // EXIBIR DIALOG COM EXERCÍCIOS DO GRUPO
  void _exibirDialogoExercicios(
    String grupoId,
    String grupoNome,
    String treinoId,
    String dataFormatada,
  ) {
    final grupo = _grupos.firstWhere((g) => g['id'] == grupoId);
    final exercicios = (grupo['exercicios'] as List)
        .where((ex) => ex['ativo'] == true)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Treino: $grupoNome'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: exercicios.length,
            itemBuilder: (context, index) {
              final ex = exercicios[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.grey[900],
                child: ListTile(
                  title: Text(
                    ex['nome'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${ex['series']}x${ex['repeticoes']} - ${(ex['pesoInicial'] ?? 0.0).toStringAsFixed(1)}kg',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: () {
                    final ultima = _ultimaConclusao[ex['id']];
                    final hoje = DateTime.now();

                    // Se já foi concluído hoje → botão desabilitado
                    if (ultima != null &&
                        ultima.year == hoje.year &&
                        ultima.month == hoje.month &&
                        ultima.day == hoje.day) {
                      return ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Concluído',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    // Se está em execução → mostra botão Encerrar
                    if (_exerciciosEmExecucao[ex['id']] == true) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (context) => _buildConfirmDialog(
                              title: 'Encerrar exercício',
                              message:
                                  'Tem certeza que deseja encerrar este exercício?',
                              confirmLabel: 'Encerrar',
                              danger: true,
                            ),
                          );

                          if (confirmar == true) {
                            await _salvarRegistroExercicio(
                              ex,
                              treinoId,
                              dataFormatada,
                              TextEditingController(
                                text: ex['series'].toString(),
                              ),
                              TextEditingController(
                                text: ex['repeticoes'].toString(),
                              ),
                              TextEditingController(
                                text: ex['pesoInicial'].toString(),
                              ),
                              TextEditingController(),
                            );

                            if (!mounted) return; // segurança
                            setState(() {
                              _tempoRealPorGrupo[grupoId] =
                                  (_tempoRealPorGrupo[grupoId] ?? 0) +
                                  (_tempoExercicio[ex['id']] ?? 0);
                              _cronometros[ex['id']]?.cancel();
                              _cronometros[ex['id']] = null;
                              _exerciciosEmExecucao[ex['id']] = false;
                              _ultimaConclusao[ex['id']] = DateTime.now();
                            });
                          }
                        },
                        child: const Text(
                          'Encerrar',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    // Caso contrário → mostra botão Iniciar
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (!mounted) return; // segurança
                        setState(() {
                          _exerciciosEmExecucao[ex['id']] = true;
                        });
                      },
                      child: const Text(
                        'Iniciar',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }(),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // DIALOG PARA REGISTRAR EXERCÍCIO
  void _exibirDialogoRegistroExercicio(
    Map<String, dynamic> exercicio,
    String treinoId,
    String dataFormatada,
  ) {
    final seriesController = TextEditingController(
      text: exercicio['series']?.toString() ?? '3',
    );
    final repeticoesController = TextEditingController(
      text: exercicio['repeticoes']?.toString() ?? '10',
    );
    final pesoController = TextEditingController(
      text: exercicio['pesoInicial']?.toString() ?? '0',
    );
    final obsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: _primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Registrar: ${exercicio['nome']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildField(
                  controller: seriesController,
                  label: 'Séries realizadas',
                  icon: Icons.repeat_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: repeticoesController,
                  label: 'Repetições realizadas',
                  icon: Icons.format_list_numbered_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: pesoController,
                  label: 'Peso utilizado (kg)',
                  icon: Icons.monitor_weight_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: obsController,
                  label: 'Observações',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textSub,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          if (!mounted) return;
                          await _salvarRegistroExercicio(
                            exercicio,
                            treinoId,
                            dataFormatada,
                            seriesController,
                            repeticoesController,
                            pesoController,
                            obsController,
                          );
                        },
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // SALVAR REGISTRO DE EXERCÍCIO
  Future<void> _salvarRegistroExercicio(
    Map<String, dynamic> exercicio,
    String treinoId,
    String dataFormatada,
    TextEditingController seriesController,
    TextEditingController repeticoesController,
    TextEditingController pesoController,
    TextEditingController obsController,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final sucesso = await ExercicioRealizadoService().registrarExercicio(
      treinoRealizadoId: treinoId,
      exercicioId: exercicio['id'] ?? '',
      seriesRealizadas: int.tryParse(seriesController.text) ?? 0,
      repeticoesRealizadas: int.tryParse(repeticoesController.text) ?? 0,
      pesoUtilizado: double.tryParse(pesoController.text) ?? 0.0,
      dataSessao: dataFormatada,
      observacoes: obsController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context); // fecha loading

    if (sucesso) {
      showCustomSnackBar(
        context,
        '${exercicio['nome']} registrado com sucesso!',
        backgroundColor: Colors.greenAccent,
      );
    } else {
      showCustomSnackBar(
        context,
        'Erro ao registrar exercício',
        backgroundColor: Colors.redAccent.shade100,
      );
    }
  }

  // DIALOG DE REGISTRO AO ENCERRAR EXERCÍCIO
  Future<void> _mostrarDialogRegistroExercicio(
    Map<String, dynamic> ex,
    String grupoId,
    String grupoNome,
  ) async {
    // Garante que existe um TreinoRealizado para este grupo
    final treinoId =
        _treinoIdPorGrupo[grupoId] ?? await _iniciarTreino(grupoId, grupoNome);
    if (treinoId == null || !mounted) return;

    final hoje = DateTime.now();
    final dataFormatada =
        '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

    final seriesController = TextEditingController(
      text: ex['series']?.toString() ?? '',
    );
    final repeticoesController = TextEditingController(
      text: ex['repeticoes']?.toString() ?? '',
    );
    final pesoController = TextEditingController(
      text: (ex['pesoInicial'] ?? 0.0).toString(),
    );
    final obsController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      color: _accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ex['nome'] ?? 'Registrar Exercício',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: seriesController,
                label: 'Séries realizadas',
                icon: Icons.repeat_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: repeticoesController,
                label: 'Repetições realizadas',
                icon: Icons.format_list_numbered_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: pesoController,
                label: 'Peso utilizado (kg)',
                icon: Icons.monitor_weight_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: obsController,
                label: 'Observações (opcional)',
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: _textHint),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  _primaryButton(
                    label: 'Salvar',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar != true || !mounted) return;

    await _salvarRegistroExercicio(
      ex,
      treinoId,
      dataFormatada,
      seriesController,
      repeticoesController,
      pesoController,
      obsController,
    );

    if (!mounted) return;

    // Atualiza status no servidor para REALIZADO
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

  // ─── Shared widget helpers ──────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool autofocus = false,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: capitalization,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: _primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: _textHint, size: 20),
        filled: true,
        fillColor: _inputBg,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.8),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_primary, _primaryDark]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Widget _buildConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) {
    final color = danger ? _error : _primary;
    return Dialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                danger
                    ? Icons.delete_outline_rounded
                    : Icons.warning_amber_rounded,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: _textSub, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSub,
                      side: const BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercicioDialog({
    required String titulo,
    required TextEditingController nomeController,
    required TextEditingController seriesController,
    required TextEditingController repeticoesController,
    required TextEditingController pesoController,
    required TextEditingController obsController,
    required List<String> gruposMusculares,
    required String grupoInicial,
    required ValueChanged<String?> onGrupoChanged,
    bool autofocus = false,
  }) {
    return Dialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports_gymnastics_rounded,
                    color: _accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: nomeController,
              label: 'Nome do exercício',
              icon: Icons.label_outline_rounded,
              autofocus: autofocus,
              capitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            // Dropdown grupo muscular
            StatefulBuilder(
              builder: (context, setStateLocal) {
                return DropdownButtonFormField<String>(
                  value: gruposMusculares.contains(grupoInicial)
                      ? grupoInicial
                      : gruposMusculares.first,
                  key: ValueKey(grupoInicial),
                  dropdownColor: _inputBg,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Grupo muscular',
                    labelStyle: const TextStyle(color: _textHint, fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.accessibility_new_rounded,
                      color: _textHint,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: _inputBg,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primary, width: 1.8),
                    ),
                  ),
                  items: gruposMusculares
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(
                            g,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onGrupoChanged(v);
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: seriesController,
                    label: 'Séries',
                    icon: Icons.repeat_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    controller: repeticoesController,
                    label: 'Repetições',
                    icon: Icons.format_list_numbered_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: pesoController,
              label: 'Peso inicial (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: obsController,
              label: 'Observações (opcional)',
              icon: Icons.notes_rounded,
              maxLines: 2,
              capitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: _textHint),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                _primaryButton(
                  label: 'Salvar',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrupoCard(Map<String, dynamic> grupo) {
    final grupoId = grupo['id'];
    final exercicios = (grupo['exercicios'] as List)
        .where((ex) => ex['ativo'] == true)
        .toList();
    final count = exercicios.length;
    final tempoAcumulado =
        (_tempoRealPorGrupo[grupoId] ?? 0) +
        exercicios
            .where((ex) => _exerciciosEmExecucao[ex['id']] == true)
            .fold<int>(0, (sum, ex) => sum + (_tempoExercicio[ex['id']] ?? 0));
    final tempoLabel = tempoAcumulado > 0
        ? (tempoAcumulado >= 60
              ? '${tempoAcumulado ~/ 60}min ${tempoAcumulado % 60}s'
              : '${tempoAcumulado}s')
        : '~${count * 5} min';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grupo['nome'] ?? 'Grupo sem nome',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '$count exercício${count == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: _textHint,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: _accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tempoLabel,
                            style: const TextStyle(
                              color: _textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _iconBtn(
                  icon: Icons.settings_outlined,
                  color: _primary,
                  size: 18,
                  tooltip: 'Editar',
                  onPressed: () => _editarGrupo(grupoId, grupo['nome']),
                ),
                _iconBtn(
                  icon: Icons.close_rounded,
                  color: _error,
                  size: 18,
                  tooltip: 'Excluir',
                  onPressed: () => _excluirGrupo(grupoId, grupo['nome']),
                ),
                _iconBtn(
                  icon: _gruposExpandidos.contains(grupoId)
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _textHint,
                  size: 20,
                  tooltip: _gruposExpandidos.contains(grupoId)
                      ? 'Recolher'
                      : 'Expandir',
                  onPressed: () => setState(() {
                    if (_gruposExpandidos.contains(grupoId)) {
                      _gruposExpandidos.remove(grupoId);
                    } else {
                      _gruposExpandidos.add(grupoId);
                    }
                  }),
                ),
              ],
            ),
          ),
          Divider(thickness: 0.5, height: 1, color: _border.withOpacity(0.5)),
          if (_gruposExpandidos.contains(grupoId)) ...[
            if (exercicios.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: _textHint,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Nenhum exercício neste grupo.',
                      style: TextStyle(color: _textHint, fontSize: 13),
                    ),
                  ],
                ),
              ),
            for (var ex in exercicios)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Builder(
                  builder: (context) {
                    final ultima = _ultimaConclusao[ex['id']];
                    final hoje = DateTime.now();
                    final concluidoHoje =
                        ultima != null &&
                        ultima.year == hoje.year &&
                        ultima.month == hoje.month &&
                        ultima.day == hoje.day;
                    final emExecucao = _exerciciosEmExecucao[ex['id']] == true;

                    return Stack(
                      children: [
                        Opacity(
                          opacity: concluidoHoje ? 0.45 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _corCardGrupo(
                                ex['grupoMuscular'] ?? ex['grupo_muscular'],
                              ),
                              border: Border.all(
                                color: concluidoHoje
                                    ? _success.withOpacity(0.4)
                                    : emExecucao
                                    ? _accent.withOpacity(0.4)
                                    : _border.withOpacity(0.6),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          height: 22,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: Icon(
                                              Icons.keyboard_arrow_up_rounded,
                                              size: 18,
                                              color: exercicios.indexOf(ex) > 0
                                                  ? _textHint
                                                  : _textHint.withOpacity(0.2),
                                            ),
                                            onPressed:
                                                exercicios.indexOf(ex) > 0
                                                ? () => _reordenarExercicios(
                                                    grupo,
                                                    exercicios.indexOf(ex),
                                                    exercicios.indexOf(ex) - 1,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 28,
                                          height: 22,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 18,
                                              color:
                                                  exercicios.indexOf(ex) <
                                                      exercicios.length - 1
                                                  ? _textHint
                                                  : _textHint.withOpacity(0.2),
                                            ),
                                            onPressed:
                                                exercicios.indexOf(ex) <
                                                    exercicios.length - 1
                                                ? () => _reordenarExercicios(
                                                    grupo,
                                                    exercicios.indexOf(ex),
                                                    exercicios.indexOf(ex) + 1,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Text(
                                        ex['nome'] ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: emExecucao
                                              ? _accent
                                              : Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Botão play / stop
                                    if (emExecucao)
                                      _iconBtn(
                                        icon: Icons.stop_circle_rounded,
                                        color: _error,
                                        size: 20,
                                        tooltip: 'Encerrar',
                                        onPressed: () async {
                                          await _mostrarDialogRegistroExercicio(
                                            ex,
                                            grupoId,
                                            grupo['nome'] ?? '',
                                          );
                                        },
                                      )
                                    else if (concluidoHoje)
                                      Tooltip(
                                        message: 'Concluído hoje',
                                        child: _iconBtn(
                                          icon:
                                              Icons.play_circle_outline_rounded,
                                          color: _textHint,
                                          size: 20,
                                          onPressed: null,
                                        ),
                                      )
                                    else
                                      _iconBtn(
                                        icon: Icons.play_circle_fill_rounded,
                                        color: _accent,
                                        size: 20,
                                        tooltip: 'Iniciar',
                                        onPressed: () async {
                                          if (_treinoIdPorGrupo[grupoId] ==
                                              null) {
                                            final tid = await _iniciarTreino(
                                              grupoId,
                                              grupo['nome'] ?? '',
                                            );
                                            if (tid == null || !mounted) return;
                                          }
                                          final sucesso = await ExercicioService()
                                              .atualizarStatus(
                                                ex['treinoExercicioAlunoId'] ??
                                                    ex['id'],
                                                'EM_EXECUCAO',
                                              );
                                          if (sucesso) {
                                            setState(() {
                                              _exerciciosEmExecucao[ex['id']] =
                                                  true;
                                              _cronometros[ex['id']]?.cancel();
                                              _cronometros[ex['id']] = Timer.periodic(
                                                const Duration(seconds: 1),
                                                (timer) {
                                                  setState(() {
                                                    _tempoExercicio[ex['id']] =
                                                        (_tempoExercicio[ex['id']] ??
                                                            0) +
                                                        1;
                                                  });
                                                },
                                              );
                                            });
                                          }
                                        },
                                      ),
                                    // Menu de ações
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: _textHint,
                                        size: 20,
                                      ),
                                      color: _card,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: _border.withOpacity(0.7),
                                        ),
                                      ),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'editar',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.settings_outlined,
                                                color: _primary,
                                                size: 18,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Editar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'excluir',
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.close_rounded,
                                                color: _error,
                                                size: 18,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Excluir',
                                                style: TextStyle(color: _error),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'editar') {
                                          _editarExercicio(ex);
                                        } else if (value == 'excluir') {
                                          _confirmarExclusaoExercicio(ex);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${ex['series']}x${ex['repeticoes']}',
                                        style: const TextStyle(
                                          color: _accent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(ex['pesoInicial'] ?? 0.0).toStringAsFixed(1)} kg',
                                      style: const TextStyle(
                                        color: _textSub,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if ((ex['grupoMuscular'] ??
                                            ex['grupo_muscular']) !=
                                        null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _corTagGrupo(
                                            ex['grupoMuscular'] ??
                                                ex['grupo_muscular'],
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: _corTagGrupo(
                                              ex['grupoMuscular'] ??
                                                  ex['grupo_muscular'],
                                            ).withOpacity(0.25),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          ex['grupoMuscular'] ??
                                              ex['grupo_muscular'] ??
                                              '',
                                          style: TextStyle(
                                            color: _corTagGrupo(
                                              ex['grupoMuscular'] ??
                                                  ex['grupo_muscular'],
                                            ).withOpacity(0.65),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 13,
                                      color: _primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _tempoExercicio[ex['id']] != null
                                          ? '${(_tempoExercicio[ex['id']]! ~/ 60).toString().padLeft(2, '0')}:${(_tempoExercicio[ex['id']]! % 60).toString().padLeft(2, '0')}'
                                          : '00:00',
                                      style: TextStyle(
                                        color: emExecucao ? _accent : _textHint,
                                        fontSize: 12,
                                        fontWeight: emExecucao
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((ex['observacao'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '\u2139\uFE0F ${ex['observacao']}',
                                    style: const TextStyle(
                                      color: _textHint,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (concluidoHoje)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.black.withOpacity(0.3),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _success.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Concluído hoje',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Adicionar Exercício'),
                  onPressed: () => _adicionarExercicio(grupoId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _border, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ], // fecha if (_gruposExpandidos.contains(grupoId))
        ],
      ),
    );
  }

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

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    String? tooltip,
    double size = 26,
  }) {
    final btn = SizedBox(
      width: size + 4,
      height: size + 4,
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 16,
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final diaSemana = _getDiaSemana(hoje);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // ─── Cabeçalho interno da aba ──────────────────────────────
            Padding(
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
                            color: _textHint,
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
                  // Botão novo grupo
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 340) {
                          return const SizedBox.shrink(); // só ícone
                        }
                        return const Text('Novo Treino');
                      },
                    ),
                    onPressed: _criarGrupo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _border, width: 1.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
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
            ),
            const SizedBox(height: 4),
            // ─── Lista de grupos ───────────────────────────────────────
            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary),
                    )
                  : _grupos.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _carregarGrupos,
                      color: _primary,
                      backgroundColor: _card,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24, top: 4),
                        itemCount: _grupos.length,
                        itemBuilder: (context, index) =>
                            _buildGrupoCard(_grupos[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: _primary,
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
            'Toque em "Novo Grupo" para começar',
            style: TextStyle(color: _textHint, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
