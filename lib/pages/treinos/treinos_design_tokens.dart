import 'package:flutter/material.dart';
export '../../constants/app_theme.dart';

/// Retorna o dia da semana em português.
String getDiaSemana(DateTime data) {
  const diasSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  return diasSemana[data.weekday - 1];
}
