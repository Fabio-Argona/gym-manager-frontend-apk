import 'package:flutter/material.dart';
import 'package:flutter_application_treinoabc/services/exercicio_service.dart';
import '../../constants/app_theme.dart';
import 'exercicio_form_field.dart';

void mostrarCriarExercicio(
  BuildContext context,
  String grupoId,
  VoidCallback onAtualizar,
) {
  final nomeController = TextEditingController();
  final grupoController = TextEditingController();
  final seriesController = TextEditingController();
  final repeticoesController = TextEditingController();
  final pesoController = TextEditingController();
  final obsController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) {
      final c = AppColors.of(ctx);
      return AlertDialog(
        backgroundColor: c.card,
        title: Text('Novo Exercício', style: TextStyle(color: c.textSub)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              buildField('Nome', nomeController, ctx),
              buildField('Grupo Muscular', grupoController, ctx),
              buildField('Séries', seriesController, ctx, isNumber: true),
              buildField(
                'Repetições',
                repeticoesController,
                ctx,
                isNumber: true,
              ),
              buildField('Peso (kg)', pesoController, ctx, isNumber: true),
              buildField('Observação', obsController, ctx),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: c.textHint)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: c.primary),
            onPressed: () async {
              final novo = {
                'grupoId': grupoId,
                'nome': nomeController.text,
                'grupoMuscular': grupoController.text,
                'series': int.tryParse(seriesController.text) ?? 0,
                'repeticoes': int.tryParse(repeticoesController.text) ?? 0,
                'pesoInicial': double.tryParse(pesoController.text) ?? 0.0,
                'observacao': obsController.text,
              };

              try {
                await ExercicioService().criarExercicio(novo);
                Navigator.pop(ctx);
                onAtualizar(); // ✅ força atualização da lista

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exercício criado com sucesso'),
                      backgroundColor: Colors.greenAccent,
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
      );
    },
  );
}

void mostrarEditarExercicio(
  BuildContext context,
  Map<String, dynamic> exercicio,
  VoidCallback onAtualizar,
) {
  final nomeController = TextEditingController(text: exercicio['nome'] ?? '');
  final grupoController = TextEditingController(
    text: exercicio['grupoMuscular'] ?? '',
  );
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
  final String? id = exercicio['id'] ?? exercicio['exercicioId'];
  if (id == null || id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Este exercício não pode ser editado. ID ausente.'),
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (ctx) {
      final c = AppColors.of(ctx);
      return AlertDialog(
        backgroundColor: c.card,
        title: Text('Editar Exercício', style: TextStyle(color: c.textSub)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              buildField('Nome', nomeController, ctx),
              buildField('Grupo Muscular', grupoController, ctx),
              buildField('Séries', seriesController, ctx, isNumber: true),
              buildField(
                'Repetições',
                repeticoesController,
                ctx,
                isNumber: true,
              ),
              buildField('Peso (kg)', pesoController, ctx, isNumber: true),
              buildField('Observação', obsController, ctx),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: c.textHint)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: c.primary),
            onPressed: () async {
              final dadosAtualizados = {
                'id': id,
                'nome': nomeController.text,
                'grupoMuscular': grupoController.text,
                'series': int.tryParse(seriesController.text) ?? 0,
                'repeticoes': int.tryParse(repeticoesController.text) ?? 0,
                'pesoInicial': double.tryParse(pesoController.text) ?? 0.0,
                'observacao': obsController.text,
              };

              try {
                await ExercicioService().editarExercicio(dadosAtualizados);
                Navigator.pop(ctx);
                onAtualizar();
              } catch (e) {
                print('Erro ao editar: $e');
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}
