import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/services/exercicio_service.dart';
import 'exercicio_form_field.dart';

void mostrarCriarExercicio(
  BuildContext context,
  String grupoId,
  VoidCallback onAtualizar,
) {
  final nomeController = TextEditingController();
  final grupoController = TextEditingController();
  final seriesController = TextEditingController();
  final repMinController = TextEditingController();
  final repMaxController = TextEditingController();
  final pesoController = TextEditingController();
  final obsController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.black,
      title: const Text(
        'Novo Exercício',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            buildField('Nome', nomeController),
            buildField('Grupo Muscular', grupoController),
            buildField('Séries', seriesController, isNumber: true),
            buildField('Repetições Mín', repMinController, isNumber: true),
            buildField('Repetições Máx', repMaxController, isNumber: true),
            buildField('Peso (kg)', pesoController, isNumber: true),
            buildField('Observação', obsController),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
          ),
          onPressed: () async {
            final novo = {
              'grupoId': grupoId,
              'nome': nomeController.text,
              'grupoMuscular': grupoController.text,
              'series': int.tryParse(seriesController.text) ?? 0,
              'repMin': int.tryParse(repMinController.text) ?? 0,
              'repMax': int.tryParse(repMaxController.text) ?? 0,
              'pesoInicial': double.tryParse(pesoController.text) ?? 0.0,
              'observacao': obsController.text,
            };

            try {
              await ExercicioService().criarExercicio(novo);
              Navigator.pop(context);
              onAtualizar(); // ✅ força atualização da lista

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exercício criado com sucesso'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao criar exercício: $e'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}


void mostrarEditarExercicio(BuildContext context, Map<String, dynamic> exercicio, VoidCallback onAtualizar) {
  final nomeController = TextEditingController(text: exercicio['nome'] ?? '');
  final grupoController = TextEditingController(text: exercicio['grupoMuscular'] ?? '');
  final seriesController = TextEditingController(text: exercicio['series']?.toString() ?? '');
  final repMinController = TextEditingController(text: exercicio['repMin']?.toString() ?? '');
  final repMaxController = TextEditingController(text: exercicio['repMax']?.toString() ?? '');
  final pesoController = TextEditingController(text: exercicio['pesoInicial']?.toString() ?? '');
  final obsController = TextEditingController(text: exercicio['observacao'] ?? '');
  final String? id = exercicio['id'] ?? exercicio['exercicioId'];
if (id == null || id.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Este exercício não pode ser editado. ID ausente.')),
  );
  return;
}

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.black,
      title: const Text('Editar Exercício', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          children: [
            buildField('Nome', nomeController),
            buildField('Grupo Muscular', grupoController),
            buildField('Séries', seriesController, isNumber: true),
            buildField('Repetições Mín', repMinController, isNumber: true),
            buildField('Repetições Máx', repMaxController, isNumber: true),
            buildField('Peso (kg)', pesoController, isNumber: true),
            buildField('Observação', obsController),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
          onPressed: () async {
            final dadosAtualizados = {
              'id': id,
              'nome': nomeController.text,
              'grupoMuscular': grupoController.text,
              'series': int.tryParse(seriesController.text) ?? 0,
              'repMin': int.tryParse(repMinController.text) ?? 0,
              'repMax': int.tryParse(repMaxController.text) ?? 0,
              'pesoInicial': double.tryParse(pesoController.text) ?? 0.0,
              'observacao': obsController.text,
            };

            try {
              await ExercicioService().editarExercicio(dadosAtualizados);
              Navigator.pop(context);
              onAtualizar();
            } catch (e) {
              print('Erro ao editar: $e');
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}
