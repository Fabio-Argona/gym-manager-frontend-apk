import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/services/treino_service.dart';
import 'package:flutter_application_treinoabc/services/exercicio_service.dart';

class TreinosPage extends StatefulWidget {
  final String nome;
  const TreinosPage({super.key, required this.nome});

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  List<Map<String, dynamic>> _grupos = [];
  final Set<String> _gruposExpandidos = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarGrupos();
  }

  Future<void> _carregarGrupos() async {
  setState(() => _carregando = true);

  try {
    final grupos = await _carregarGruposComExercicios();

    // Ordena conforme a ordem desejada
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao carregar grupos: $e')),
    );
  }
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
      grupo['exercicios'] = (exerciciosPorGrupo[id] ?? [])
          .where((ex) => ex['ativo'] == true)
          .toList();
    }

    return grupos;
  }

 Future<void> _criarGrupo() async {
  final nome = await _mostrarDialogoGrupo();
  if (nome != null && nome.isNotEmpty) {
    try {
      await TreinoService().criarGrupo(nome);

      // Recarrega os grupos e força atualização
      await _carregarGrupos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo criado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar grupo: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo editado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao editar grupo: $e')),
      );
    }
  }
}


  Future<void> _excluirGrupo(String id, String nomeGrupo) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Excluir grupo'),
      content: Text('Tem certeza que deseja excluir "$nomeGrupo"?'),
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
      await TreinoService().excluirGrupo(id);

      await _carregarGrupos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo excluído com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir grupo: $e')),
      );
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
      ExercicioService().desativarExercicio(
        context,
        exercicio,
        _carregarGrupos,
      );
    }
  }

  Future<void> _adicionarExercicio(String grupoId) async {
    final nomeController = TextEditingController();
    final seriesController = TextEditingController(text: '3');
    final repMinController = TextEditingController(text: '10');
    final repMaxController = TextEditingController(text: '12');
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
                controller: repMinController,
                decoration: const InputDecoration(
                  labelText: 'Repetições mínimas',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repMaxController,
                decoration: const InputDecoration(
                  labelText: 'Repetições máximas',
                ),
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Mostra loading enquanto cria
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ExercicioService().criarExercicio({
        'nome': nomeController.text.trim(),
        'grupoMuscular': grupoSelecionado,
        'series': int.tryParse(seriesController.text) ?? 0,
        'repMin': int.tryParse(repMinController.text) ?? 0,
        'repMax': int.tryParse(repMaxController.text) ?? 0,
        'pesoInicial': double.tryParse(pesoController.text) ?? 0.0,
        'observacao': obsController.text.trim(),
        'grupoId': grupoId,
      });

      await _carregarGrupos();

      if (mounted) {
        Navigator.pop(context); // fecha o loading
        setState(() {}); // força atualização imediata
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercício adicionado com sucesso!')),
      );
    }
  }

  Future<void> _editarExercicio(Map<String, dynamic> exercicio) async {
    final nomeController = TextEditingController(text: exercicio['nome'] ?? '');
    final grupoController = TextEditingController(
      text: exercicio['grupoMuscular'] ?? '',
    );
    final seriesController = TextEditingController(
      text: exercicio['series']?.toString() ?? '',
    );
    final repMinController = TextEditingController(
      text: exercicio['repMin']?.toString() ?? '',
    );
    final repMaxController = TextEditingController(
      text: exercicio['repMax']?.toString() ?? '',
    );
    final pesoController = TextEditingController(
      text: exercicio['pesoInicial']?.toString() ?? '',
    );
    final obsController = TextEditingController(
      text: exercicio['observacao'] ?? '',
    );

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
              TextField(
                controller: grupoController,
                decoration: const InputDecoration(labelText: 'Grupo muscular'),
              ),
              TextField(
                controller: seriesController,
                decoration: const InputDecoration(labelText: 'Séries'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repMinController,
                decoration: const InputDecoration(
                  labelText: 'Repetições mínimas',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repMaxController,
                decoration: const InputDecoration(
                  labelText: 'Repetições máximas',
                ),
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
      try {
        await ExercicioService().editarExercicio({
          'id': exercicio['id'],
          'grupoId': exercicio['grupoId'],
          'nome': nomeController.text.trim(),
          'grupoMuscular': grupoController.text.trim(),
          'series': int.tryParse(seriesController.text.trim()) ?? 0,
          'repMin': int.tryParse(repMinController.text.trim()) ?? 0,
          'repMax': int.tryParse(repMaxController.text.trim()) ?? 0,
          'pesoInicial': double.tryParse(pesoController.text.trim()) ?? 0.0,
          'observacao': obsController.text.trim(),
          'ativo': true,
        });

        await _carregarGrupos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercício editado com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao editar exercício: $e')));
      }
    }
  }

  Future<String?> _mostrarDialogoGrupo([String nomeInicial = '']) {
    final controller = TextEditingController(text: nomeInicial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nomeInicial.isEmpty ? 'Criar Grupo' : 'Editar Grupo'),
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

  Widget _buildGrupoCard(Map<String, dynamic> grupo) {
    final grupoId = grupo['id'];
    final exercicios = (grupo['exercicios'] as List)
        .where((ex) => ex['ativo'] == true)
        .toList();
    final count = exercicios.length;
    final tempoTotal = count * 5;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        leading: const Icon(Icons.fitness_center, color: Colors.deepPurple),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                grupo['nome'] ?? 'Grupo sem nome',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.grey[700]),
                  onPressed: () => _editarGrupo(grupoId, grupo['nome']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _excluirGrupo(grupoId, grupo['nome']),
                ),
              ],
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text('$count exercício${count == 1 ? '' : 's'}'),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text('$tempoTotal min'),
          ],
        ),
        children: [
          if (exercicios.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Text('Nenhum exercício neste grupo'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _adicionarExercicio(grupoId),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar exercício'),
                  ),
                ],
              ),
            ),
          ...exercicios.map<Widget>((ex) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black54, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ex['nome'] ?? 'Exercício',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
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
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'editar') _editarExercicio(ex);
                              if (value == 'excluir')
                                _confirmarExclusaoExercicio(ex);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${ex['grupoMuscular'] ?? '-'}   '
                        'Séries: ${ex['series'] ?? '-'}   '
                        'Repet: ${ex['repMin'] ?? '-'}-${ex['repMax'] ?? '-'}   '
                        'Peso: ${ex['pesoInicial'] != null ? double.parse(ex['pesoInicial'].toString()).toStringAsFixed(1) : '-'} kg',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if ((ex['observacao'] ?? '').toString().isNotEmpty)
                        Text(
                          'Obs: ${ex['observacao']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.amber,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              onPressed: () => _adicionarExercicio(grupoId),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar exercício'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.transparent,
      child: ListView.builder(
        itemCount: _grupos.length,
        itemBuilder: (context, index) {
          final grupo = _grupos[index];
          return _buildGrupoCard(grupo);
        },
      ),
    );
  }
}
