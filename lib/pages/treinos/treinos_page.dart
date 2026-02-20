import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_treinoabc/services/treino_service.dart';
import 'package:flutter_application_treinoabc/services/exercicio_service.dart';
import 'package:flutter_application_treinoabc/services/exercicio_realizado_service.dart';

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

class _TreinosPageState extends State<TreinosPage> {
  List<Map<String, dynamic>> _grupos = [];
  final Set<String> _gruposExpandidos = {};
  bool _carregando = true;
  final Map<String, bool> _exerciciosEmExecucao = {};

  final Map<String, int> _tempoExercicio = {};
  final Map<String, Timer?> _cronometros = {};

  final Map<String, DateTime> _ultimaConclusao = {};

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

  // Função utilitária para SnackBar
  void showCustomSnackBar(
    BuildContext context,
    String mensagem, {
    Color backgroundColor = Colors.black87,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _carregarGrupos() async {
  if (!mounted) return;
  setState(() => _carregando = true);

  try {
    final grupos = await _carregarGruposComExercicios();

    const ordemGrupos = [
      'Peito','Costas','Tríceps','Bíceps','Ombro','Perna','Abdômen','Panturrilha',
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
    final exercicios = await ExercicioService().listarExercicios();

    final Map<String, List<Map<String, dynamic>>> exerciciosPorGrupo = {};
    for (var ex in exercicios) {
      final grupoId = ex['grupoId'] ?? ex['grupo_id'];
      if (grupoId != null) {
        exerciciosPorGrupo.putIfAbsent(grupoId, () => []).add(ex);
      }
    }

    for (var grupo in grupos) {
      final id = grupo['id'];
      var listaExercicios = (exerciciosPorGrupo[id] ?? [])
          .where((ex) => ex['ativo'] == true)
          .toList();

      listaExercicios.sort((a, b) {
        final ga = a['grupoMuscular']?.toString() ?? '';
        final gb = b['grupoMuscular']?.toString() ?? '';
        return ga.compareTo(gb);
      });

      for (var ex in listaExercicios) {
        ex.remove('grupoMuscular');
      }

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
            backgroundColor: Colors.green,
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
          backgroundColor: Colors.greenAccent.shade100,
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
      builder: (context) => AlertDialog(
        title: const Text('Excluir grupo'),
        content: Text(
          'Tem certeza que deseja excluir "$nomeGrupo"? Todos os exercícios serão removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
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
            backgroundColor: Colors.green,
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
      builder: (context) => AlertDialog(
        title: const Text('Excluir exercício'),
        content: const Text('Tem certeza que deseja excluir este exercício?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
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
        backgroundColor: Colors.green,
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
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Exercício'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              DropdownButtonFormField<String>(
                initialValue: grupoSelecionado,
                decoration: const InputDecoration(labelText: 'Grupo muscular'),
                items: gruposMusculares
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) =>
                    grupoSelecionado = value ?? grupoSelecionado,
              ),
              TextField(
                controller: seriesController,
                decoration: const InputDecoration(labelText: 'Séries'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repeticoesController,
                decoration: const InputDecoration(labelText: 'Repetições'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: pesoController,
                decoration: const InputDecoration(
                  labelText: 'Peso inicial (kg)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: obsController,
                decoration: const InputDecoration(labelText: 'Observações'),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(' Salvar '),
          ),
        ],
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
          backgroundColor: Colors.green,
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
        exercicio['grupoMuscular'] ?? gruposMusculares.first;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Exercício'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              DropdownButtonFormField<String>(
                value: grupoSelecionado,
                decoration: const InputDecoration(labelText: 'Grupo muscular'),
                items: gruposMusculares
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) =>
                    grupoSelecionado = value ?? grupoSelecionado,
              ),
              TextField(
                controller: seriesController,
                decoration: const InputDecoration(labelText: 'Séries'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repeticoesController,
                decoration: const InputDecoration(labelText: 'Repetições'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: pesoController,
                decoration: const InputDecoration(
                  labelText: 'Peso inicial (kg)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: obsController,
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
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
        backgroundColor: Colors.green,
      );
    }
  }

  Future<String?> _mostrarDialogoGrupo([String nomeInicial = '']) {
    final controller = TextEditingController(text: nomeInicial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          nomeInicial.isEmpty ? 'Criar Grupo' : 'Editar Nome do Grupo',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome do grupo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // INICIAR TREINO
  Future<void> _iniciarTreino(String grupoId, String grupoNome) async {
  final hoje = DateTime.now();
  final dataFormatada =
      '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

  final treinoId = await ExercicioRealizadoService().iniciarTreino(grupoId, dataFormatada);

  if (treinoId != null) {
    showCustomSnackBar(
      context,
      'Treino de "$grupoNome" iniciado!',
      backgroundColor: Colors.green,
    );

    if (!mounted) return;
    setState(() {
      for (var ex in _grupos.firstWhere((g) => g['id'] == grupoId)['exercicios']) {
        final ultima = _ultimaConclusao[ex['id']];
        if (ultima == null ||
            ultima.year != hoje.year ||
            ultima.month != hoje.month ||
            ultima.day != hoje.day) {
          _exerciciosEmExecucao[ex['id']] = false;
        }
      }
    });
  } else {
    showCustomSnackBar(
      context,
      'Erro ao iniciar treino',
      backgroundColor: Colors.redAccent.shade100,
    );
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
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Encerrar exercício'),
                            content: const Text(
                              'Tem certeza que deseja encerrar este exercício?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Encerrar'),
                              ),
                            ],
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
                      backgroundColor: Colors.amber,
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
                      style: TextStyle(color: Colors.black),
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
    builder: (context) => AlertDialog(
      title: Text('Registrar: ${exercicio['nome']}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: seriesController,
              decoration: const InputDecoration(
                labelText: 'Séries realizadas',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repeticoesController,
              decoration: const InputDecoration(
                labelText: 'Repetições realizadas',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pesoController,
              decoration: const InputDecoration(
                labelText: 'Peso utilizado (kg)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: obsController,
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);

            // segurança: só prossegue se o widget ainda está montado
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
      ],
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
      backgroundColor: Colors.green,
    );
  } else {
    showCustomSnackBar(
      context,
      'Erro ao registrar exercício',
      backgroundColor: Colors.redAccent.shade100,
    );
  }
}


  Widget _buildGrupoCard(Map<String, dynamic> grupo) {
    final grupoId = grupo['id'];
    final exercicios = (grupo['exercicios'] as List)
        .where((ex) => ex['ativo'] == true)
        .toList();
    final count = exercicios.length;
    final tempoTotal = count * 5;

    return Card(
      elevation: 0,
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[800]!, width: 1),
      ),
      child: ExpansionTile(
        key: PageStorageKey(grupoId),
        initiallyExpanded: _gruposExpandidos.contains(grupoId),
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _gruposExpandidos.add(grupoId);
            } else {
              _gruposExpandidos.remove(grupoId);
            }
          });
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                grupo['nome'] ?? 'Grupo sem nome',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.redAccent),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Text('Editar')),
                const PopupMenuItem(
                  value: 'desativar',
                  child: Text(
                    'Excluir',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'editar') {
                  _editarGrupo(grupoId, grupo['nome']);
                } else if (value == 'desativar') {
                  _excluirGrupo(grupoId, grupo['nome']);
                }
              },
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              '$count exercício${count == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              '$tempoTotal min',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const Spacer(),
          ],
        ),
        children: [
          Divider(thickness: 0.5, height: 1, color: Colors.grey[800]),
          if (exercicios.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum exercício neste grupo.'),
            ),
          for (var ex in exercicios)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Builder(
                builder: (context) {
                  final ultima = _ultimaConclusao[ex['id']];
                  final hoje = DateTime.now();
                  final concluidoHoje = ultima != null &&
                      ultima.year == hoje.year &&
                      ultima.month == hoje.month &&
                      ultima.day == hoje.day;

                  return Stack(
                    children: [
                      // ── Card principal ──
                      Opacity(
                        opacity: concluidoHoje ? 0.45 : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: concluidoHoje
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.grey[800]!,
                              width: concluidoHoje ? 1.0 : 0.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[850],
                          ),
                          padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha principal: nome + ícones + menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ex['nome'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color.fromARGB(255, 100, 180, 220),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            if (_exerciciosEmExecucao[ex['id']] == true)
                              // ── Em execução: mostra STOP ──
                              IconButton(
                                icon: const Icon(Icons.stop, color: Colors.red),
                                tooltip: 'Parar',
                                onPressed: () async {
                                  final sucesso = await ExercicioService()
                                      .atualizarStatus(ex['id'], 'REALIZADO');
                                  if (sucesso) {
                                    setState(() {
                                      _exerciciosEmExecucao[ex['id']] = false;
                                      // registra conclusão com a data/hora atual
                                      _ultimaConclusao[ex['id']] = DateTime.now();
                                      // para cronômetro
                                      _cronometros[ex['id']]?.cancel();
                                      _cronometros[ex['id']] = null;
                                    });
                                  }
                                },
                              )
                            else if (() {
                              final ultima = _ultimaConclusao[ex['id']];
                              if (ultima == null) return false;
                              final hoje = DateTime.now();
                              return ultima.year == hoje.year &&
                                  ultima.month == hoje.month &&
                                  ultima.day == hoje.day;
                            }())
                              // ── Concluído hoje: play desabilitado ──
                              Tooltip(
                                message: 'Concluído hoje',
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.grey,
                                  ),
                                  onPressed: null,
                                ),
                              )
                            else
                              // ── Normal: play ativo ──
                              IconButton(
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.green,
                                ),
                                tooltip: 'Iniciar',
                                onPressed: () async {
                                  final sucesso = await ExercicioService()
                                      .atualizarStatus(ex['id'], 'EM_EXECUCAO');
                                  if (sucesso) {
                                    setState(() {
                                      _exerciciosEmExecucao[ex['id']] = true;
                                      _tempoExercicio[ex['id']] = 0;

                                      // inicia cronômetro em tempo real
                                      _cronometros[ex['id']]?.cancel();
                                      _cronometros[ex['id']] = Timer.periodic(
                                        const Duration(seconds: 1),
                                        (timer) {
                                          setState(() {
                                            _tempoExercicio[ex['id']] =
                                                (_tempoExercicio[ex['id']] ?? 0) +
                                                1;
                                          });
                                        },
                                      );
                                    });
                                  }
                                },
                              ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.amber,
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'editar',
                                  child: Text('Editar'),
                                ),
                                const PopupMenuItem(
                                  value: 'excluir',
                                  child: Text(
                                    'Excluir',
                                    style: TextStyle(color: Colors.redAccent),
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
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Text(
                          '${ex['series']}x${ex['repeticoes']} - ${(ex['pesoInicial'] ?? 0.0).toStringAsFixed(1)}kg',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.timer, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          _tempoExercicio[ex['id']] != null
                              ? '${(_tempoExercicio[ex['id']]! ~/ 60).toString().padLeft(2, '0')}:${(_tempoExercicio[ex['id']]! % 60).toString().padLeft(2, '0')}'
                              : '00:00',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    // Observação
                    if ((ex['observacao'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Obs: ${ex['observacao']}',
                        style: const TextStyle(
                          color: Colors.grey,
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
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withOpacity(0.35),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
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
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.add, color: Colors.amber),
                label: const Text(
                  'Adicionar Exercício',
                  style: TextStyle(color: Colors.amber),
                ),
                onPressed: () => _adicionarExercicio(grupoId),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black54,
          title: const SizedBox.shrink(),
          actions: [
            TextButton.icon(
              onPressed: _criarGrupo,
              icon: const Icon(
                Icons.add,
                color: Color.fromARGB(255, 189, 156, 245),
              ),
              label: const Text(
                'Treino',
                style: TextStyle(color: Color.fromARGB(255, 189, 156, 245)),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 18,
                ),
              ),
            ),
          ],
        ),

        body: Stack(
          children: [
            // Imagem de fundo
            SizedBox.expand(
              child: Image.asset(
                'assets/images/Copilot_20251029_183912.png',
                fit: BoxFit.cover,
              ),
            ),
            // Conteúdo por cima da imagem
            _carregando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _carregarGrupos,
                child: ListView.builder(
                  itemCount: _grupos.length,
                  itemBuilder: (context, index) {
                   return _buildGrupoCard(_grupos[index]);
                 },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
