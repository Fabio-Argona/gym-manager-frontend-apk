import 'package:flutter/material.dart';
import 'treinos_design_tokens.dart';
import 'treinos_shared_widgets.dart';

/// Card de um exercício dentro de um grupo de treino.
class ExercicioCard extends StatelessWidget {
  final Map<String, dynamic> exercicio;

  /// Lista de exercícios ativos do grupo (para controle de reordenação).
  final List<Map<String, dynamic>> exerciciosDoGrupo;

  final bool concluidoHoje;
  final bool emExecucao;
  final int? tempoSegundos;

  final VoidCallback? onIniciar;
  final VoidCallback? onEncerrar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final void Function(int oldIndex, int newIndex) onReordenar;

  const ExercicioCard({
    super.key,
    required this.exercicio,
    required this.exerciciosDoGrupo,
    required this.concluidoHoje,
    required this.emExecucao,
    required this.tempoSegundos,
    required this.onIniciar,
    required this.onEncerrar,
    required this.onEditar,
    required this.onExcluir,
    required this.onReordenar,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final grupoMuscular =
        exercicio['grupoMuscular'] ?? exercicio['grupo_muscular'];
    final index = exerciciosDoGrupo.indexOf(exercicio);

    return Stack(
      children: [
        Opacity(
          opacity: concluidoHoje ? 0.45 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: cardColorByMuscleGroup(grupoMuscular, c),
              border: Border.all(
                color: concluidoHoje
                    ? c.success.withValues(alpha: 0.4)
                    : emExecucao
                    ? c.accent.withValues(alpha: 0.4)
                    : c.border.withValues(alpha: 0.6),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopRow(context, index),
                const SizedBox(height: 6),
                _buildBottomRow(context, grupoMuscular),
                if ((exercicio['observacao'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '\u2139\uFE0F ${exercicio['observacao']}',
                    style: TextStyle(color: c.textHint, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (concluidoHoje) _buildConcluidoOverlay(context),
      ],
    );
  }

  Widget _buildTopRow(BuildContext context, int index) {
    final c = AppColors.of(context);
    return Row(
      children: [
        _ReorderButtons(
          index: index,
          total: exerciciosDoGrupo.length,
          onReordenar: onReordenar,
        ),
        Expanded(
          child: Text(
            exercicio['nome'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: emExecucao ? c.accent : c.textSub,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _PlayStopButton(
          concluidoHoje: concluidoHoje,
          emExecucao: emExecucao,
          onIniciar: onIniciar,
          onEncerrar: onEncerrar,
        ),
        _ExercicioMenu(onEditar: onEditar, onExcluir: onExcluir),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context, String? grupoMuscular) {
    final c = AppColors.of(context);
    final tempo = tempoSegundos;
    final tempoLabel = tempo != null
        ? '${(tempo ~/ 60).toString().padLeft(2, '0')}:${(tempo % 60).toString().padLeft(2, '0')}'
        : '00:00';

    return Row(
      children: [
        _InfoBadge(
          label: '${exercicio['series']}x${exercicio['repeticoes']}',
          color: c.accent,
          background: c.primary.withValues(alpha: 0.15),
        ),
        const SizedBox(width: 8),
        Text(
          '${(exercicio['pesoInicial'] ?? 0.0).toStringAsFixed(1)} kg',
          style: TextStyle(color: c.textSub, fontSize: 12),
        ),
        if (grupoMuscular != null) ...[
          const SizedBox(width: 8),
          _MuscleGroupTag(grupo: grupoMuscular),
        ],
        const Spacer(),
        Icon(Icons.timer_outlined, size: 13, color: c.primary),
        const SizedBox(width: 4),
        Text(
          tempoLabel,
          style: TextStyle(
            color: emExecucao ? c.accent : c.textHint,
            fontSize: 12,
            fontWeight: emExecucao ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConcluidoOverlay(BuildContext context) {
    final c = AppColors.of(context);
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.3),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: c.success.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
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
    );
  }
}

// ─── Sub-widgets privados ─────────────────────────────────────────────────────

class _ReorderButtons extends StatelessWidget {
  final int index;
  final int total;
  final void Function(int oldIndex, int newIndex) onReordenar;

  const _ReorderButtons({
    required this.index,
    required this.total,
    required this.onReordenar,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 22,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 18,
              color: index > 0 ? c.textHint : c.textHint.withValues(alpha: 0.2),
            ),
            onPressed: index > 0 ? () => onReordenar(index, index - 1) : null,
          ),
        ),
        SizedBox(
          width: 28,
          height: 22,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: index < total - 1
                  ? c.textHint
                  : c.textHint.withValues(alpha: 0.2),
            ),
            onPressed: index < total - 1
                ? () => onReordenar(index, index + 1)
                : null,
          ),
        ),
      ],
    );
  }
}

class _PlayStopButton extends StatelessWidget {
  final bool concluidoHoje;
  final bool emExecucao;
  final VoidCallback? onIniciar;
  final VoidCallback? onEncerrar;

  const _PlayStopButton({
    required this.concluidoHoje,
    required this.emExecucao,
    required this.onIniciar,
    required this.onEncerrar,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (emExecucao) {
      return iconBtn(
        icon: Icons.stop_circle_rounded,
        color: c.error,
        size: 20,
        tooltip: 'Encerrar',
        onPressed: onEncerrar,
      );
    }
    if (concluidoHoje) {
      return Tooltip(
        message: 'Concluído hoje',
        child: iconBtn(
          icon: Icons.play_circle_outline_rounded,
          color: c.textHint,
          size: 20,
          onPressed: null,
        ),
      );
    }
    return iconBtn(
      icon: Icons.play_circle_fill_rounded,
      color: c.accent,
      size: 20,
      tooltip: 'Iniciar',
      onPressed: onIniciar,
    );
  }
}

class _ExercicioMenu extends StatelessWidget {
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _ExercicioMenu({required this.onEditar, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: c.textHint, size: 20),
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border.withValues(alpha: 0.7)),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'editar',
          child: Row(
            children: [
              Icon(Icons.build_outlined, color: c.primary, size: 18),
              SizedBox(width: 10),
              Text('Editar', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'excluir',
          child: Row(
            children: [
              Icon(Icons.close_rounded, color: c.error, size: 18),
              SizedBox(width: 10),
              Text('Excluir', style: TextStyle(color: c.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'editar') onEditar();
        if (value == 'excluir') onExcluir();
      },
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _InfoBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MuscleGroupTag extends StatelessWidget {
  final String grupo;

  const _MuscleGroupTag({required this.grupo});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cor = tagColorByMuscleGroup(grupo, c);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cor.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        grupo,
        style: TextStyle(
          color: cor.withValues(alpha: 0.65),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
