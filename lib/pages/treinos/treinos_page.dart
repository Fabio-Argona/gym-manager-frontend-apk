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
        'repMin': exercicio['repMin'],
        'repMax': exercicio['repMax'],
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
        'repMin': int.tryParse(repMinController.text) ?? 0,
        'repMax': int.tryParse(repMaxController.text) ?? 0,
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
      await ExercicioService().editarExercicio({
        'id': exercicio['id'],
        'grupoId': exercicio['grupoId'],
        'nome': nomeController.text.trim(),
        'grupoMuscular': grupoSelecionado,
        'series': int.tryParse(seriesController.text.trim()) ?? 0,
        'repMin': int.tryParse(repMinController.text.trim()) ?? 0,
        'repMax': int.tryParse(repMaxController.text.trim()) ?? 0,
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.redAccent),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Text('Editar')),
                const PopupMenuItem(
                  value: 'desativar',
                  child: Text(
                    'Desativar',
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
            Text('$count exercício${count == 1 ? '' : 's'}'),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text('$tempoTotal min'),
          ],
        ),
        children: [
          // Divider para separar título dos exercícios
          const Divider(thickness: 1, height: 1, color: Colors.grey),
          if (exercicios.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum exercício neste grupo.'),
            ),
          for (var ex in exercicios)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Nome do exercício
                  Expanded(
                    child: Text(
                      ex['nome'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color.fromARGB(255, 93, 167, 209),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Séries, repetições e carga com tonalidades diferentes
                  Row(
                    children: [
                      Text(
                        '${ex['series']}x',
                        style: const TextStyle(
                          color: Color(0xFF1976D2), // azul médio
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('|', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 4),
                      Text(
                        '${ex['repMin']} rep.',
                        style: const TextStyle(
                          color: Color(0xFF42A5F5), 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('|', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 4),
                      Text(
                        '${ex['pesoInicial']}kg',
                        style: const TextStyle(
                          color: Color(0xFF90CAF9), 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Botão de mais opções
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.redAccent),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                            
                              title: const Text('Editar'),
                              onTap: () {
                                Navigator.pop(context);
                                _editarExercicio(ex);
                              },
                            ),
                            ListTile(
                             
                              title: const Text(
                                'Excluir',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _confirmarExclusaoExercicio(ex);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              onPressed: () => _adicionarExercicio(grupoId),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Exercício'),
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Olá, ${widget.nome}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
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
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
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
