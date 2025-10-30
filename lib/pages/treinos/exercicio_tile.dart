import 'package:flutter/material.dart';

class ExercicioTile extends StatelessWidget {
  final Map<String, dynamic> exercicio;
  final VoidCallback onEditar;
  final VoidCallback onDesativar;

  const ExercicioTile({
    super.key,
    required this.exercicio,
    required this.onEditar,
    required this.onDesativar,
  });

  @override
  Widget build(BuildContext context) {
    final String nomeExercicio = exercicio['nome'] ?? 'Exercício';
    final String grupoMuscular = exercicio['grupoMuscular'] ?? '';
    final int series = exercicio['series'] ?? 0;
    final int repMin = exercicio['repMin'] ?? 0;
    final int repMax = exercicio['repMax'] ?? 0;
    final double pesoInicial = (exercicio['pesoInicial'] ?? 0).toDouble();

    return ListTile(
      title: Text(nomeExercicio, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        '$grupoMuscular • ${series}x $repMin-$repMax • ${pesoInicial.toStringAsFixed(1)}kg',
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'editar', child: Text('Editar')),
          const PopupMenuItem(
            value: 'desativar',
            child: Text('Desativar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
        onSelected: (value) {
          if (value == 'editar') {
            onEditar();
          } else if (value == 'desativar') {
            onDesativar();
          }
        },
      ),
    );
  }
}
