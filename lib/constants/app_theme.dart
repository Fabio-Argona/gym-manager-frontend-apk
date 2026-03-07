// lib/constants/app_theme.dart
//
// Tokens centralizados de cores e ícones.
// Importe este arquivo onde precisar:
//   import 'package:gym_manager/constants/app_theme.dart';

import 'package:flutter/material.dart';

// ─── Cores base ───────────────────────────────────────────────────────────────

/// Fundo principal (mais escuro).
const Color kBg1 = Color(0xFF0D0D1A);

/// Fundo secundário / gradiente.
const Color kBg2 = Color(0xFF1A1040);

/// Terceira parada do gradiente de fundo.
const Color kBg3 = Color(0xFF0E1628);

/// Cor de card padrão.
const Color kCard = Color(0xFF1C1B2E);

/// Cor de card de exercício.
const Color kCardEx = Color(0xFF201F35);

/// Cor primária (roxo).
const Color kPrimary = Color(0xFF7C3AED);

/// Variação escura da cor primária.
const Color kPrimaryDark = Color(0xFF5B21B6);

/// Cor de destaque / accent (ciano).
const Color kAccent = Color(0xFF06B6D4);

/// Cor de sucesso (verde).
const Color kSuccess = Color(0xFF10B981);

/// Cor de aviso (amarelo/âmbar).
const Color kWarning = Color(0xFFF59E0B);

/// Cor de erro (vermelho).
const Color kError = Color(0xFFEF4444);

/// Fundo de campos de input.
const Color kInputBg = Color(0xFF252438);

/// Cor de bordas.
const Color kBorder = Color(0xFF3A3857);

/// Texto de hint / placeholder.
const Color kTextHint = Color(0xFF8884A8);

/// Texto secundário / subtítulo.
const Color kTextSub = Color(0xFFB0ADCC);

// ─── Cores de nível / badge ───────────────────────────────────────────────────

/// Ouro — ≥ 500 dias ativos.
const Color kLevelGold = Color(0xFFFFD700);

/// Diamante (roxo claro) — ≥ 300 dias ativos.
const Color kLevelDiamond = Color(0xFFAB47BC);

/// Ciano — ≥ 200 dias ativos.
const Color kLevelCyan = Color(0xFF26C6DA);

/// Azul — ≥ 150 dias ativos.
const Color kLevelBlue = Color(0xFF42A5F5);

// kSuccess  → ≥ 100 dias
// kWarning  → ≥  60 dias
// kAccent   → ≥  30 dias
// kPrimary  → ≥  10 dias
// kTextHint → iniciante (padrão)

/// Retorna a cor do nível baseada nos dias ativos.
Color corNivel(int diasAtivos, AppColors c) {
  if (diasAtivos >= 500) return kLevelGold;
  if (diasAtivos >= 300) return kLevelDiamond;
  if (diasAtivos >= 200) return kLevelCyan;
  if (diasAtivos >= 150) return kLevelBlue;
  if (diasAtivos >= 100) return c.success;
  if (diasAtivos >= 60) return c.warning;
  if (diasAtivos >= 30) return c.accent;
  if (diasAtivos >= 10) return c.primary;
  return c.textHint;
}

// ─── Cores por grupo muscular ─────────────────────────────────────────────────

/// Cor de fundo sutil do card por grupo muscular.
Color cardColorByMuscleGroup(String? grupo, AppColors c) {
  final isDark = c.bg1.computeLuminance() < 0.5;
  switch (grupo?.toLowerCase()) {
    case 'peito':
      return isDark ? const Color(0xFF231E3A) : const Color(0xFFF0ECFF);
    case 'costas':
      return isDark ? const Color(0xFF1A2035) : const Color(0xFFE8EDFF);
    case 'pernas':
      return isDark ? const Color(0xFF1A2530) : const Color(0xFFE8F5F0);
    case 'ombros':
      return isDark ? const Color(0xFF28202A) : const Color(0xFFFFEEEE);
    case 'bíceps':
      return isDark ? const Color(0xFF281E1A) : const Color(0xFFFFF5EA);
    case 'tríceps':
      return isDark ? const Color(0xFF1A2620) : const Color(0xFFEEF9EE);
    case 'abdômen':
      return isDark ? const Color(0xFF272015) : const Color(0xFFFFF9EA);
    case 'glúteos':
      return isDark ? const Color(0xFF28182A) : const Color(0xFFFFF0FA);
    default:
      return c.cardEx;
  }
}

/// Cor do badge/tag por grupo muscular.
Color tagColorByMuscleGroup(String? grupo, AppColors c) {
  final isDark = c.bg1.computeLuminance() < 0.5;
  if (isDark) {
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
        return c.textHint;
    }
  } else {
    // Modo claro: cores mais escuras e saturadas para garantir contraste
    switch (grupo?.toLowerCase()) {
      case 'peito':
        return const Color(0xFF6B3FD4);
      case 'costas':
        return const Color(0xFF1A6FD4);
      case 'pernas':
        return const Color(0xFF178A5A);
      case 'ombros':
        return const Color(0xFFD43040);
      case 'bíceps':
        return const Color(0xFFB86A00);
      case 'tríceps':
        return const Color(0xFF2A8C2A);
      case 'abdômen':
        return const Color(0xFFB89000);
      case 'glúteos':
        return const Color(0xFFB83090);
      default:
        return c.textHint;
    }
  }
}

// ─── Ícones — Navegação ───────────────────────────────────────────────────────

const IconData kIconBack = Icons.arrow_back_ios_new_rounded;
const IconData kIconBackSimple = Icons.arrow_back;
const IconData kIconMenu = Icons.more_vert;
const IconData kIconClose = Icons.close_rounded;
const IconData kIconArrowUp = Icons.arrow_upward_rounded;
const IconData kIconArrowDown = Icons.arrow_downward_rounded;
const IconData kIconChevronDown = Icons.keyboard_arrow_down_rounded;
const IconData kIconChevronUp = Icons.keyboard_arrow_up_rounded;

// ─── Ícones — Usuário / Perfil ────────────────────────────────────────────────

const IconData kIconPerson = Icons.person_outline_rounded;
const IconData kIconEmail = Icons.alternate_email_rounded;
const IconData kIconEmailOutlined = Icons.email_outlined;
const IconData kIconPhone = Icons.phone_outlined;
const IconData kIconBirthday = Icons.cake_outlined;
const IconData kIconBadge = Icons.badge_outlined;
const IconData kIconGender = Icons.wc_rounded;
const IconData kIconPhoto = Icons.photo_camera_outlined;
const IconData kIconLogout = Icons.logout_rounded;
const IconData kIconSave = Icons.save_rounded;

// ─── Ícones — Autenticação / Segurança ───────────────────────────────────────

const IconData kIconLock = Icons.lock_outline_rounded;
const IconData kIconLockSolid = Icons.lock_rounded;
const IconData kIconLockFill = Icons.lock;
const IconData kIconLockReset = Icons.lock_reset_rounded;
const IconData kIconKey = Icons.vpn_key;
const IconData kIconFingerprint = Icons.fingerprint_rounded;
const IconData kIconVisibility = Icons.visibility_outlined;
const IconData kIconVisibilityOff = Icons.visibility_off_outlined;
const IconData kIconVisibilityRounded = Icons.visibility_rounded;
const IconData kIconVisibilityOffRounded = Icons.visibility_off_rounded;
const IconData kIconVisibilitySolid = Icons.visibility;
const IconData kIconVisibilityOffSolid = Icons.visibility_off;

// ─── Ícones — Fitness / Treino ────────────────────────────────────────────────

const IconData kIconGym = Icons.fitness_center_rounded;
const IconData kIconGymnastics = Icons.sports_gymnastics_rounded;
const IconData kIconTimer = Icons.timer_outlined;
const IconData kIconTime = Icons.access_time_rounded;
const IconData kIconCalendar = Icons.calendar_today_rounded;
const IconData kIconHistory = Icons.history_rounded;
const IconData kIconList = Icons.format_list_numbered_rounded;
const IconData kIconNotes = Icons.notes_rounded;
const IconData kIconRepeat = Icons.repeat_rounded;
const IconData kIconPlay = Icons.play_circle_fill_rounded;
const IconData kIconPlayOutlined = Icons.play_circle_outline_rounded;
const IconData kIconStop = Icons.stop_circle_rounded;
const IconData kIconRefresh = Icons.refresh_rounded;
const IconData kIconAdd = Icons.add_rounded;
const IconData kIconDelete = Icons.delete_outline_rounded;
const IconData kIconBuild = Icons.build_outlined;

// ─── Ícones — Progresso / Métricas ───────────────────────────────────────────

const IconData kIconWeight = Icons.monitor_weight_outlined;
const IconData kIconHeight = Icons.height_rounded;
const IconData kIconWater = Icons.water_drop_outlined;
const IconData kIconMeasure = Icons.straighten_rounded;
const IconData kIconBarChart = Icons.bar_chart_rounded;
const IconData kIconTrendingUp = Icons.trending_up_rounded;
const IconData kIconGoal = Icons.flag_outlined;
const IconData kIconCalculate = Icons.calculate_outlined;
const IconData kIconBody = Icons.accessibility_new_rounded;
const IconData kIconLabel = Icons.label_outline_rounded;

// ─── Ícones — Nível / Conquistas ─────────────────────────────────────────────

const IconData kIconLevelDefault = Icons.eco_rounded;
const IconData kIconLevelBolt = Icons.bolt_rounded;
const IconData kIconLevelFire = Icons.local_fire_department_rounded;
const IconData kIconLevelTrophy = Icons.emoji_events_rounded;
const IconData kIconLevelTrophyOutlined = Icons.emoji_events_outlined;
const IconData kIconLevelStar = Icons.star_rounded;
const IconData kIconLevelStarHalf = Icons.star_half_rounded;
const IconData kIconLevelDiamond = Icons.diamond_rounded;
const IconData kIconLevelCrown = Icons.workspace_premium_rounded;
const IconData kIconLevelMedal = Icons.military_tech_rounded;
const IconData kIconLevelSparkle = Icons.auto_awesome_rounded;

/// Retorna o ícone do nível baseado nos dias ativos.
IconData iconNivel(int diasAtivos) {
  if (diasAtivos >= 500) return kIconLevelSparkle;
  if (diasAtivos >= 300) return kIconLevelCrown;
  if (diasAtivos >= 200) return kIconLevelDiamond;
  if (diasAtivos >= 150) return kIconLevelStar;
  if (diasAtivos >= 100) return kIconLevelTrophy;
  if (diasAtivos >= 60) return kIconLevelFire;
  if (diasAtivos >= 30) return kIconGym;
  if (diasAtivos >= 10) return kIconLevelBolt;
  return kIconLevelDefault;
}

// ─── Ícones — Status / Feedback ──────────────────────────────────────────────

const IconData kIconSuccess = Icons.check_circle_outline_rounded;
const IconData kIconSuccessFill = Icons.check_circle;
const IconData kIconError = Icons.error_outline_rounded;
const IconData kIconWarning = Icons.warning_amber_rounded;
const IconData kIconInfo = Icons.info_outline_rounded;
const IconData kIconOffline = Icons.wifi_off_rounded;

// ─── AppColors — ThemeExtension ──────────────────────────────────────────────

/// Conjunto de cores do app, acessível via [AppColors.of(context)].
/// Registrado como ThemeExtension em ambos os ThemeData (claro e escuro).
class AppColors extends ThemeExtension<AppColors> {
  final Color bg1;
  final Color bg2;
  final Color bg3;
  final Color card;
  final Color cardEx;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color inputBg;
  final Color border;
  final Color textHint;
  final Color textSub;

  const AppColors({
    required this.bg1,
    required this.bg2,
    required this.bg3,
    required this.card,
    required this.cardEx,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.inputBg,
    required this.border,
    required this.textHint,
    required this.textSub,
  });

  /// Paleta escura (padrão).
  static const dark = AppColors(
    bg1: kBg1,
    bg2: kBg2,
    bg3: kBg3,
    card: kCard,
    cardEx: kCardEx,
    primary: kPrimary,
    primaryDark: kPrimaryDark,
    accent: kAccent,
    success: kSuccess,
    warning: kWarning,
    error: kError,
    inputBg: kInputBg,
    border: kBorder,
    textHint: kTextHint,
    textSub: kTextSub,
  );

  /// Paleta clara.
  static const light = AppColors(
    bg1: Color(0xFFF4F2FF),
    bg2: Color(0xFFEDE9FE),
    bg3: Color(0xFFE0D7FF),
    card: Color(0xFFFFFFFF),
    cardEx: Color(0xFFF5F2FF),
    primary: kPrimary,
    primaryDark: kPrimaryDark,
    accent: Color(0xFF0891B2),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    inputBg: Color(0xFFF5F3FF),
    border: Color(0xFFB9A8F5),
    textHint: Color(0xFF4A3A80),
    textSub: Color(0xFF2D1F5E),
  );

  /// Obtém as cores do tema atual via BuildContext.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? bg1,
    Color? bg2,
    Color? bg3,
    Color? card,
    Color? cardEx,
    Color? primary,
    Color? primaryDark,
    Color? accent,
    Color? success,
    Color? warning,
    Color? error,
    Color? inputBg,
    Color? border,
    Color? textHint,
    Color? textSub,
  }) => AppColors(
    bg1: bg1 ?? this.bg1,
    bg2: bg2 ?? this.bg2,
    bg3: bg3 ?? this.bg3,
    card: card ?? this.card,
    cardEx: cardEx ?? this.cardEx,
    primary: primary ?? this.primary,
    primaryDark: primaryDark ?? this.primaryDark,
    accent: accent ?? this.accent,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    inputBg: inputBg ?? this.inputBg,
    border: border ?? this.border,
    textHint: textHint ?? this.textHint,
    textSub: textSub ?? this.textSub,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      bg1: Color.lerp(bg1, other.bg1, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      bg3: Color.lerp(bg3, other.bg3, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardEx: Color.lerp(cardEx, other.cardEx, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      border: Color.lerp(border, other.border, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textSub: Color.lerp(textSub, other.textSub, t)!,
    );
  }
}
