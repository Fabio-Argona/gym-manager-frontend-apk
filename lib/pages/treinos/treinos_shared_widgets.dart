import 'package:flutter/material.dart';
import 'treinos_design_tokens.dart';

/// Botão de ícone compacto com tooltip opcional.
Widget iconBtn({
  required IconData icon,
  required Color color,
  VoidCallback? onPressed,
  String? tooltip,
  double size = 26,
}) {
  final btn = SizedBox(
    width: size + 4,
    height: size + 4,
    child: IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 16,
    ),
  );
  return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
}

/// Botão primário com gradiente.
Widget primaryButton(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
}) {
  final c = AppColors.of(context);
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [c.primary, c.primaryDark]),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: c.primary.withValues(alpha: 0.35),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

/// Campo de texto padronizado.
Widget buildField(
  BuildContext context, {
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType? keyboardType,
  int maxLines = 1,
  bool autofocus = false,
  TextCapitalization capitalization = TextCapitalization.none,
}) {
  final c = AppColors.of(context);
  return TextField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: keyboardType,
    maxLines: maxLines,
    textCapitalization: capitalization,
    style: TextStyle(color: c.textSub, fontSize: 15),
    cursorColor: c.primary,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.textHint, fontSize: 14),
      prefixIcon: Icon(icon, color: c.textHint, size: 20),
      filled: true,
      fillColor: c.inputBg,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.primary, width: 1.8),
      ),
    ),
  );
}

/// Exibe um snackbar padronizado.
void showCustomSnackBar(
  BuildContext context,
  String mensagem, {
  Color? backgroundColor,
  bool success = false,
  bool warning = false,
}) {
  final c = AppColors.of(context);
  final isSuccess =
      success ||
      (backgroundColor == Colors.greenAccent ||
          backgroundColor == Colors.green);
  final isWarning = warning;
  final color = isSuccess ? c.success : (isWarning ? c.warning : c.error);
  final icon = isSuccess
      ? Icons.check_circle_outline_rounded
      : (isWarning ? Icons.warning_amber_rounded : Icons.error_outline_rounded);

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
