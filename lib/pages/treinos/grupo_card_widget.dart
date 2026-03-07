import 'package:flutter/material.dart';
import 'treinos_design_tokens.dart';
import 'treinos_shared_widgets.dart';
import 'exercicio_card_widget.dart';

/// Card de um grupo de treino com seus exercícios.
class GrupoCard extends StatelessWidget {
  final Map<String, dynamic> grupo;
  final bool expandido;
  final Map<String, bool> exerciciosEmExecucao;
  final Map<String, DateTime> ultimaConclusao;
  final Map<String, int> tempoExercicio;
  final Map<String, int> tempoRealPorGrupo;

  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onToggleExpand;
  final VoidCallback onAdicionarExercicio;
  final void Function(Map<String, dynamic> ex) onEditarExercicio;
  final void Function(Map<String, dynamic> ex) onExcluirExercicio;
  final void Function(Map<String, dynamic> ex) onIniciarExercicio;
  final void Function(Map<String, dynamic> ex) onEncerrarExercicio;
  final void Function(int oldIndex, int newIndex) onReordenar;

  const GrupoCard({
    super.key,
    required this.grupo,
    required this.expandido,
    required this.exerciciosEmExecucao,
    required this.ultimaConclusao,
    required this.tempoExercicio,
    required this.tempoRealPorGrupo,
    required this.onEditar,
    required this.onExcluir,
    required this.onToggleExpand,
    required this.onAdicionarExercicio,
    required this.onEditarExercicio,
    required this.onExcluirExercicio,
    required this.onIniciarExercicio,
    required this.onEncerrarExercicio,
    required this.onReordenar,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final grupoId = grupo['id'];
    final exercicios = (grupo['exercicios'] as List)
        .where((ex) => ex['ativo'] == true)
        .cast<Map<String, dynamic>>()
        .toList();
    final count = exercicios.length;
    final tempoLabel = _buildTempoLabel(grupoId, exercicios, count);

    final hoje = DateTime.now();
    final concluidosHoje = exercicios.where((ex) {
      final ultima = ultimaConclusao[ex['id']];
      return ultima != null &&
          ultima.year == hoje.year &&
          ultima.month == hoje.month &&
          ultima.day == hoje.day;
    }).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withValues(alpha: 0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GrupoHeader(
            nome: grupo['nome'] ?? 'Grupo sem nome',
            count: count,
            concluidosHoje: concluidosHoje,
            tempoLabel: tempoLabel,
            expandido: expandido,
            onEditar: onEditar,
            onExcluir: onExcluir,
            onToggleExpand: onToggleExpand,
          ),
          Divider(
            thickness: 0.5,
            height: 1,
            color: c.border.withValues(alpha: 0.5),
          ),
          if (expandido) ...[
            if (exercicios.isEmpty)
              const _EmptyExerciciosHint()
            else
              for (final ex in exercicios)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: _buildExercicioCard(ex, exercicios),
                ),
            _AddExercicioButton(onPressed: onAdicionarExercicio),
          ],
        ],
      ),
    );
  }

  String _buildTempoLabel(
    dynamic grupoId,
    List<Map<String, dynamic>> exercicios,
    int count,
  ) {
    final tempoAcumulado =
        (tempoRealPorGrupo[grupoId] ?? 0) +
        exercicios
            .where((ex) => exerciciosEmExecucao[ex['id']] == true)
            .fold<int>(0, (sum, ex) => sum + (tempoExercicio[ex['id']] ?? 0));
    if (tempoAcumulado > 0) {
      return tempoAcumulado >= 60
          ? '${tempoAcumulado ~/ 60}min ${tempoAcumulado % 60}s'
          : '${tempoAcumulado}s';
    }
    return '~${count * 5} min';
  }

  Widget _buildExercicioCard(
    Map<String, dynamic> ex,
    List<Map<String, dynamic>> exercicios,
  ) {
    final ultima = ultimaConclusao[ex['id']];
    final hoje = DateTime.now();
    final concluidoHoje =
        ultima != null &&
        ultima.year == hoje.year &&
        ultima.month == hoje.month &&
        ultima.day == hoje.day;
    final emExecucao = exerciciosEmExecucao[ex['id']] == true;

    return ExercicioCard(
      exercicio: ex,
      exerciciosDoGrupo: exercicios,
      concluidoHoje: concluidoHoje,
      emExecucao: emExecucao,
      tempoSegundos: tempoExercicio[ex['id']],
      onIniciar: concluidoHoje ? null : () => onIniciarExercicio(ex),
      onEncerrar: emExecucao ? () => onEncerrarExercicio(ex) : null,
      onEditar: () => onEditarExercicio(ex),
      onExcluir: () => onExcluirExercicio(ex),
      onReordenar: onReordenar,
    );
  }
}

// ─── Sub-widgets privados ─────────────────────────────────────────────────────

class _GrupoHeader extends StatelessWidget {
  final String nome;
  final int count;
  final int concluidosHoje;
  final String tempoLabel;
  final bool expandido;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onToggleExpand;

  const _GrupoHeader({
    required this.nome,
    required this.count,
    required this.concluidosHoje,
    required this.tempoLabel,
    required this.expandido,
    required this.onEditar,
    required this.onExcluir,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pct = count > 0 ? concluidosHoje / count : 0.0;
    final completo = count > 0 && concluidosHoje == count;
    final corPct = completo
        ? c.success
        : concluidosHoje > 0
        ? c.accent
        : c.textHint;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: c.textSub,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '$count exerc.',
                      style: TextStyle(color: c.textHint, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time_rounded, size: 13, color: c.accent),
                    const SizedBox(width: 4),
                    Text(
                      tempoLabel,
                      style: TextStyle(color: c.textHint, fontSize: 12),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: corPct.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: corPct.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          completo
                              ? '✓ 100%'
                              : '$concluidosHoje/$count · ${(pct * 100).toInt()}%',
                          style: TextStyle(
                            color: corPct,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (count > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 3,
                      backgroundColor: c.border.withValues(alpha: 0.35),
                      valueColor: AlwaysStoppedAnimation<Color>(corPct),
                    ),
                  ),
                ],
              ],
            ),
          ),
          iconBtn(
            icon: Icons.build_outlined,
            color: c.primary,
            size: 18,
            tooltip: 'Editar',
            onPressed: onEditar,
          ),
          iconBtn(
            icon: Icons.close_rounded,
            color: c.error,
            size: 18,
            tooltip: 'Excluir',
            onPressed: onExcluir,
          ),
          iconBtn(
            icon: expandido
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: c.textHint,
            size: 20,
            tooltip: expandido ? 'Recolher' : 'Expandir',
            onPressed: onToggleExpand,
          ),
        ],
      ),
    );
  }
}

class _EmptyExerciciosHint extends StatelessWidget {
  const _EmptyExerciciosHint();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, color: c.textHint, size: 16),
          SizedBox(width: 8),
          Text(
            'Nenhum exercício neste grupo.',
            style: TextStyle(color: c.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AddExercicioButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddExercicioButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Adicionar Exercício'),
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: c.accent,
            side: BorderSide(color: c.border, width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
