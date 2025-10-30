import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/services/exercicio_service.dart';

void excluirExercicio(BuildContext context, String id, VoidCallback onAtualizar) async {
  try {
    await ExercicioService().excluirLogicamenteExercicio(id);
    onAtualizar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercício excluído com sucesso')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao excluir: $e')),
    );
  }
}

void desativarExercicio(BuildContext context, String id, VoidCallback onAtualizar) async {
  try {
    await ExercicioService().atualizarStatus(id, false); // desativa
    onAtualizar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercício desativado com sucesso')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao desativar: $e')),
    );
  }
}
