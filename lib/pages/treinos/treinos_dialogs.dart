import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'treinos_design_tokens.dart';
import 'treinos_shared_widgets.dart';

/// Dialog de confirmação para iniciar um treino.
class IniciarTreinoDialog extends StatelessWidget {
  final String grupoNome;

  const IniciarTreinoDialog({super.key, required this.grupoNome});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                color: c.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Iniciar Treino',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textSub,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deseja iniciar o treino de',
              style: TextStyle(color: c.textHint, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                grupoNome,
                style: TextStyle(
                  color: c.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSub,
                      side: BorderSide(color: c.border),
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
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Iniciar'),
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
    final c = AppColors.of(context);
    final color = danger ? c.error : c.primary;
    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border, width: 1),
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
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textSub,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: c.textSub, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSub,
                      side: BorderSide(color: c.border),
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
                      textStyle: TextStyle(fontWeight: FontWeight.w600),
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
    final c = AppColors.of(context);
    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border, width: 1),
      ),
      child: SingleChildScrollView(
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
                      color: c.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: c.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    nomeInicial.isEmpty ? 'Criar Grupo' : 'Editar Grupo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.textSub,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              buildField(
                context,
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
                    style: TextButton.styleFrom(foregroundColor: c.textHint),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  primaryButton(
                    context,
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
    final c = AppColors.of(context);
    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border, width: 1),
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
              context,
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
                    context,
                    controller: widget.seriesController,
                    label: 'Séries',
                    icon: Icons.repeat_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: buildField(
                    context,
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
              context,
              controller: widget.pesoController,
              label: 'Peso inicial (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            buildField(
              context,
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
                  style: TextButton.styleFrom(foregroundColor: c.textHint),
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                primaryButton(
                  context,
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
    final c = AppColors.of(context);
    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.border, width: 1),
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
                    color: c.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.timer_outlined, color: c.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nomeExercicio,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.textSub,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            buildField(
              context,
              controller: seriesController,
              label: 'Séries realizadas',
              icon: Icons.repeat_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildField(
              context,
              controller: repeticoesController,
              label: 'Repetições realizadas',
              icon: Icons.format_list_numbered_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildField(
              context,
              controller: pesoController,
              label: 'Peso utilizado (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            buildField(
              context,
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
                  style: TextButton.styleFrom(foregroundColor: c.textHint),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                primaryButton(
                  context,
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
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.sports_gymnastics_rounded,
            color: c.accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: c.textSub,
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
    final c = AppColors.of(context);
    return DropdownButtonFormField<String>(
      initialValue: gruposMusculares.contains(grupoSelecionado)
          ? grupoSelecionado
          : gruposMusculares.first,
      dropdownColor: c.inputBg,
      style: TextStyle(color: c.textSub, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Grupo muscular',
        labelStyle: TextStyle(color: c.textHint, fontSize: 14),
        prefixIcon: Icon(
          Icons.accessibility_new_rounded,
          color: c.textHint,
          size: 20,
        ),
        filled: true,
        fillColor: c.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 1.8),
        ),
      ),
      items: gruposMusculares
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(g, style: TextStyle(color: c.textSub)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Celebração Treino Concluído ────────────────────────────────────────────────

Future<void> showTreinoConcluidoOverlay(
  BuildContext context,
  String grupoNome,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (ctx, a1, a2, child) =>
        FadeTransition(opacity: a1, child: child),
    pageBuilder: (ctx, _, __) => _TreinoConcluidoOverlay(grupoNome: grupoNome),
  );
}

class _Particle {
  final double startX, startY, vx, vy;
  final Color color;
  final double size, rotation, rotationSpeed;
  final bool isCircle;

  _Particle(math.Random rng)
    : startX = rng.nextDouble(),
      startY = rng.nextDouble() * 0.6,
      vx = (rng.nextDouble() - 0.5) * 0.5,
      vy = rng.nextDouble() * 0.7 + 0.3,
      color = const [
        Color(0xFF7C3AED),
        Color(0xFF06B6D4),
        Color(0xFF10B981),
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
        Color(0xFFEC4899),
        Color(0xFF3B82F6),
        Color(0xFFFFD700),
      ][rng.nextInt(8)],
      size = rng.nextDouble() * 6 + 3,
      rotation = rng.nextDouble() * math.pi * 2,
      rotationSpeed = (rng.nextDouble() - 0.5) * math.pi * 5,
      isCircle = rng.nextBool();
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  const _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = progress < 0.65
          ? 1.0
          : ((1.0 - progress) / 0.35).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      final x = p.startX * size.width + p.vx * progress * size.width;
      final y = (p.startY - 0.15) * size.height + p.vy * progress * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * p.rotationSpeed);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _TreinoConcluidoOverlay extends StatefulWidget {
  final String grupoNome;
  const _TreinoConcluidoOverlay({required this.grupoNome});

  @override
  State<_TreinoConcluidoOverlay> createState() =>
      _TreinoConcluidoOverlayState();
}

class _TreinoConcluidoOverlayState extends State<_TreinoConcluidoOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
    ]).animate(_ctrl);

    final rng = math.Random();
    _particles = List.generate(70, (_) => _Particle(rng));

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2900), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        final fade = _ctrl.value < 0.15
            ? (_ctrl.value / 0.15).clamp(0.0, 1.0)
            : _ctrl.value > 0.8
            ? ((1.0 - _ctrl.value) / 0.2).clamp(0.0, 1.0)
            : 1.0;
        return Opacity(
          opacity: fade,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Confetti
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _ctrl.value,
                      particles: _particles,
                    ),
                  ),
                ),
                // Card central
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 44),
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: c.success.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.success.withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                c.success,
                                c.success.withValues(alpha: 0.75),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: c.success.withValues(alpha: 0.45),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Treino Concluído! 💪',
                          style: TextStyle(
                            color: c.textSub,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: c.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: c.success.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            widget.grupoNome,
                            style: TextStyle(
                              color: c.success,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Todos os exercícios realizados!',
                          style: TextStyle(color: c.textHint, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
