import 'package:flutter/material.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const Color kBg1 = Color(0xFF0D0D1A);
const Color kBg2 = Color(0xFF1A1040);
const Color kCard = Color(0xFF1C1B2E);
const Color kCardEx = Color(0xFF201F35);
const Color kPrimary = Color(0xFF7C3AED);
const Color kPrimaryDark = Color(0xFF5B21B6);
const Color kAccent = Color(0xFF06B6D4);
const Color kSuccess = Color(0xFF10B981);
const Color kWarning = Color(0xFFF59E0B);
const Color kError = Color(0xFFEF4444);
const Color kInputBg = Color(0xFF252438);
const Color kBorder = Color(0xFF3A3857);
const Color kTextHint = Color(0xFF8884A8);
const Color kTextSub = Color(0xFFB0ADCC);

/// Cor de fundo sutil do card por grupo muscular.
Color cardColorByMuscleGroup(String? grupo) {
  switch (grupo?.toLowerCase()) {
    case 'peito':
      return const Color(0xFF231E3A);
    case 'costas':
      return const Color(0xFF1A2035);
    case 'pernas':
      return const Color(0xFF1A2530);
    case 'ombros':
      return const Color(0xFF28202A);
    case 'bíceps':
      return const Color(0xFF281E1A);
    case 'tríceps':
      return const Color(0xFF1A2620);
    case 'abdômen':
      return const Color(0xFF272015);
    case 'glúteos':
      return const Color(0xFF28182A);
    default:
      return kCardEx;
  }
}

/// Cor do badge/tag por grupo muscular.
Color tagColorByMuscleGroup(String? grupo) {
  switch (grupo?.toLowerCase()) {
    case 'peito':
      return const Color(0xFFA07AFF);
    case 'costas':
      return const Color(0xFF7AABFF);
    case 'pernas':
      return const Color(0xFF7ADFB8);
    case 'ombros':
      return const Color(0xFFFF9EA0);
    case 'bíceps':
      return const Color(0xFFFFCA7A);
    case 'tríceps':
      return const Color(0xFF90EE90);
    case 'abdômen':
      return const Color(0xFFFFE57A);
    case 'glúteos':
      return const Color(0xFFFF9BE0);
    default:
      return kTextHint;
  }
}

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
