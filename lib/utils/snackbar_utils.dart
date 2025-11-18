import 'package:flutter/material.dart';

void mostrarSnackBarPadrao(
  BuildContext context,
  String mensagem, {
  bool erro = false,
  Duration duracao = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        mensagem,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      duration: duracao,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 80, // sobe o snackbar pro topo do rodapé
      ),
      backgroundColor: erro ? Colors.red : Colors.green,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
