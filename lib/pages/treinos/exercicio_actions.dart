import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/services/exercicio_service.dart';

/// Exclui logicamente (desativa) um exercício
void excluirExercicio(
  BuildContext context,
  Map<String, dynamic> exercicio,
  VoidCallback onAtualizar,
) async {
  try {
    await ExercicioService().desativarExercicio(context, exercicio, onAtualizar);
    // O próprio service já mostra o SnackBar de sucesso
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }
}

/// Alternativa: atualizar status diretamente (se quiser apenas toggle)
void desativarExercicio(
  BuildContext context,
  String id,
  VoidCallback onAtualizar,
) async {
  try {
    await ExercicioService().atualizarStatus(id, false); // desativa
    onAtualizar();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercício desativado com sucesso'),
          backgroundColor: Colors.redAccent, // destaque visual
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao desativar: $e')),
      );
    }
  }
}
