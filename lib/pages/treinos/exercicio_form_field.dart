import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

Widget buildField(
  String label,
  TextEditingController controller,
  BuildContext context, {
  bool isNumber = false,
}) {
  final c = AppColors.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: c.textSub),
      cursorColor: c.primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: c.textHint),
        floatingLabelStyle: TextStyle(color: c.textSub),
        filled: true,
        fillColor: c.inputBg,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
      ),
    ),
  );
}
