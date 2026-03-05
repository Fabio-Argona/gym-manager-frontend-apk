import 'package:flutter/material.dart';
import 'treinos_design_tokens.dart';
import 'treinos_shared_widgets.dart';

/// Dialog de confirmação genérico (excluir, encerrar, etc).
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool danger;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? kError : kPrimary;
    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
              style: const TextStyle(color: kTextSub, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextSub,
                      side: const BorderSide(color: kBorder),
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
}

/// Dialog para criar/editar nome de grupo.
class GrupoDialog extends StatelessWidget {
  final String nomeInicial;
  final TextEditingController controller;

  const GrupoDialog({
    super.key,
    required this.nomeInicial,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kBorder, width: 1),
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
                    color: kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: kPrimary,
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
            buildField(
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
                  style: TextButton.styleFrom(foregroundColor: kTextHint),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                primaryButton(
                  label: 'Salvar',
                  onPressed: () => Navigator.pop(context, controller.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog para criar/editar exercício.
class ExercicioFormDialog extends StatefulWidget {
  final String titulo;
  final TextEditingController nomeController;
  final TextEditingController seriesController;
  final TextEditingController repeticoesController;
  final TextEditingController pesoController;
  final TextEditingController obsController;
  final List<String> gruposMusculares;
  final String grupoInicial;
  final bool autofocus;

  const ExercicioFormDialog({
    super.key,
    required this.titulo,
    required this.nomeController,
    required this.seriesController,
    required this.repeticoesController,
    required this.pesoController,
    required this.obsController,
    required this.gruposMusculares,
    required this.grupoInicial,
    this.autofocus = false,
  });

  @override
  State<ExercicioFormDialog> createState() => _ExercicioFormDialogState();
}

class _ExercicioFormDialogState extends State<ExercicioFormDialog> {
  late String _grupoSelecionado;

  @override
  void initState() {
    super.initState();
    _grupoSelecionado = widget.gruposMusculares.contains(widget.grupoInicial)
        ? widget.grupoInicial
        : widget.gruposMusculares.first;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kBorder, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogHeader(titulo: widget.titulo),
            const SizedBox(height: 20),
            buildField(
              controller: widget.nomeController,
              label: 'Nome do exercício',
              icon: Icons.label_outline_rounded,
              autofocus: widget.autofocus,
              capitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            _MuscleGroupDropdown(
              gruposMusculares: widget.gruposMusculares,
              grupoSelecionado: _grupoSelecionado,
              onChanged: (v) {
                if (v != null) setState(() => _grupoSelecionado = v);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: buildField(
                    controller: widget.seriesController,
                    label: 'Séries',
                    icon: Icons.repeat_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: buildField(
                    controller: widget.repeticoesController,
                    label: 'Repetições',
                    icon: Icons.format_list_numbered_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            buildField(
              controller: widget.pesoController,
              label: 'Peso inicial (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            buildField(
              controller: widget.obsController,
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
                  style: TextButton.styleFrom(foregroundColor: kTextHint),
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                primaryButton(
                  label: 'Salvar',
                  onPressed: () => Navigator.pop(context, _grupoSelecionado),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog de registro ao encerrar exercício.
class RegistroExercicioDialog extends StatelessWidget {
  final String nomeExercicio;
  final TextEditingController seriesController;
  final TextEditingController repeticoesController;
  final TextEditingController pesoController;
  final TextEditingController obsController;

  const RegistroExercicioDialog({
    super.key,
    required this.nomeExercicio,
    required this.seriesController,
    required this.repeticoesController,
    required this.pesoController,
    required this.obsController,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kBorder, width: 1),
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
                    color: kAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: kAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nomeExercicio,
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
            buildField(
              controller: seriesController,
              label: 'Séries realizadas',
              icon: Icons.repeat_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildField(
              controller: repeticoesController,
              label: 'Repetições realizadas',
              icon: Icons.format_list_numbered_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildField(
              controller: pesoController,
              label: 'Peso utilizado (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            buildField(
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
                  style: TextButton.styleFrom(foregroundColor: kTextHint),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                primaryButton(
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
}

// ─── helpers privados ─────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final String titulo;
  const _DialogHeader({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.sports_gymnastics_rounded,
            color: kAccent,
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
    );
  }
}

class _MuscleGroupDropdown extends StatelessWidget {
  final List<String> gruposMusculares;
  final String grupoSelecionado;
  final ValueChanged<String?> onChanged;

  const _MuscleGroupDropdown({
    required this.gruposMusculares,
    required this.grupoSelecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: gruposMusculares.contains(grupoSelecionado)
          ? grupoSelecionado
          : gruposMusculares.first,
      dropdownColor: kInputBg,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Grupo muscular',
        labelStyle: const TextStyle(color: kTextHint, fontSize: 14),
        prefixIcon: const Icon(
          Icons.accessibility_new_rounded,
          color: kTextHint,
          size: 20,
        ),
        filled: true,
        fillColor: kInputBg,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.8),
        ),
      ),
      items: gruposMusculares
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(g, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
