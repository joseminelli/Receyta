import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color ink;
  final Color inkSoft;
  final Color paper;
  final Color paperSoft;
  final Color lime;
  final Color coral;
  final Color coralLight;
  final Color violetDeep;
  final Color violet;
  final Color textMuted;
  final Color textBody;

  /// Erro e ação destrutiva. Vermelho frio, deliberadamente distante do
  /// `coral` laranja — coral é a cor da seção Receitas, não de alerta.
  /// Não consta na §9.2 do plano; adicionado por necessidade real.
  final Color danger;

  /// Texto sobre bloco saturado (`coral`, `violet`): branco puro, sempre.
  final Color onSaturated;

  /// Label secundário sobre `coral`. Versão clara do próprio matiz — cinza
  /// nesse fundo fica sujo (§9.2).
  final Color coralMuted;

  /// Label secundário sobre `violet`. Mesma regra do [coralMuted].
  final Color violetMuted;

  // Pattern colors
  final Color coralPattern;
  final Color violetPattern;
  final Color inkPattern;
  final Color limePattern;

  const AppColors({
    required this.ink,
    required this.inkSoft,
    required this.paper,
    required this.paperSoft,
    required this.lime,
    required this.coral,
    required this.coralLight,
    required this.violetDeep,
    required this.violet,
    required this.textMuted,
    required this.textBody,
    required this.danger,
    required this.onSaturated,
    required this.coralMuted,
    required this.violetMuted,
    required this.coralPattern,
    required this.violetPattern,
    required this.inkPattern,
    required this.limePattern,
  });

  static const AppColors light = AppColors(
    ink: Color(0xFF16150F),
    inkSoft: Color(0xFF2B2A20),
    paper: Color(0xFFF5F2EA),
    paperSoft: Color(0xFFE9E5D8),
    lime: Color(0xFFD6F45A),
    coral: Color(0xFFFF5A38),
    coralLight: Color(0xFFFF7A5E),
    violetDeep: Color(0xFF6558E0),
    violet: Color(0xFF7B6CF6),
    textMuted: Color(0xFF8A8674),
    textBody: Color(0xFF3D3B30),
    danger: Color(0xFFC0203F),
    onSaturated: Color(0xFFFFFFFF),
    coralMuted: Color(0xFFFFB3A4),
    violetMuted: Color(0xFFC2BCFA),
    coralPattern: Color(0xFFFF7A5E),
    violetPattern: Color(0xFF9A8EF9),
    inkPattern: Color(0xFF2B2A20),
    limePattern: Color(0xFFC2E33F),
  );

  static const AppColors dark = AppColors(
    ink: Color(0xFFF5F2EA),
    inkSoft: Color(0xFFE9E5D8),
    paper: Color(0xFF1E1D16),
    paperSoft: Color(0xFF2B2A20),
    lime: Color(0xFFC2E33F),
    coral: Color(0xFFE64820),
    coralLight: Color(0xFFFF6A48),
    violetDeep: Color(0xFF5543C8),
    violet: Color(0xFF6957D8),
    textMuted: Color(0xFF776B5F),
    textBody: Color(0xFFB8B5A8),
    danger: Color(0xFFFF6B85),
    onSaturated: Color(0xFFFFFFFF),
    coralMuted: Color(0xFFFFA38F),
    violetMuted: Color(0xFFB3A8F5),
    coralPattern: Color(0xFFE64820),
    violetPattern: Color(0xFF7966E6),
    inkPattern: Color(0xFF373625),
    limePattern: Color(0xFFADD82E),
  );

  @override
  AppColors copyWith({
    Color? ink,
    Color? inkSoft,
    Color? paper,
    Color? paperSoft,
    Color? lime,
    Color? coral,
    Color? coralLight,
    Color? violetDeep,
    Color? violet,
    Color? textMuted,
    Color? textBody,
    Color? danger,
    Color? onSaturated,
    Color? coralMuted,
    Color? violetMuted,
    Color? coralPattern,
    Color? violetPattern,
    Color? inkPattern,
    Color? limePattern,
  }) {
    return AppColors(
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      paper: paper ?? this.paper,
      paperSoft: paperSoft ?? this.paperSoft,
      lime: lime ?? this.lime,
      coral: coral ?? this.coral,
      coralLight: coralLight ?? this.coralLight,
      violetDeep: violetDeep ?? this.violetDeep,
      violet: violet ?? this.violet,
      textMuted: textMuted ?? this.textMuted,
      textBody: textBody ?? this.textBody,
      danger: danger ?? this.danger,
      onSaturated: onSaturated ?? this.onSaturated,
      coralMuted: coralMuted ?? this.coralMuted,
      violetMuted: violetMuted ?? this.violetMuted,
      coralPattern: coralPattern ?? this.coralPattern,
      violetPattern: violetPattern ?? this.violetPattern,
      inkPattern: inkPattern ?? this.inkPattern,
      limePattern: limePattern ?? this.limePattern,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      paperSoft: Color.lerp(paperSoft, other.paperSoft, t)!,
      lime: Color.lerp(lime, other.lime, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coralLight: Color.lerp(coralLight, other.coralLight, t)!,
      violetDeep: Color.lerp(violetDeep, other.violetDeep, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onSaturated: Color.lerp(onSaturated, other.onSaturated, t)!,
      coralMuted: Color.lerp(coralMuted, other.coralMuted, t)!,
      violetMuted: Color.lerp(violetMuted, other.violetMuted, t)!,
      coralPattern: Color.lerp(coralPattern, other.coralPattern, t)!,
      violetPattern: Color.lerp(violetPattern, other.violetPattern, t)!,
      inkPattern: Color.lerp(inkPattern, other.inkPattern, t)!,
      limePattern: Color.lerp(limePattern, other.limePattern, t)!,
    );
  }
}

class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Margem lateral padrão de tela (§9.8). Também o quanto o sheet de
  /// conteúdo sobe sobre o hero.
  static const double screen = 18;

  /// Área mínima de toque — acessibilidade (RNF-05).
  static const double minTapTarget = 48;
}

class AppRadii {
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 26;
  static const double pill = 99;
}