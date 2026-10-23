import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  /// Bloco escuro (cabeçalho, Compras, modo cozinha, barra de navegação). É
  /// superfície, não cor de texto: continua escuro no tema escuro (§9.2). Quem
  /// escreve texto, ícone ou traço sobre o `paper` usa [onPaper].
  final Color ink;

  /// Superfície elevada sobre [ink] (chips, campos).
  final Color inkSoft;
  final Color paper;
  final Color paperSoft;

  /// Texto, ícone e traço sobre `paper`/`paperSoft`. No tema claro é o próprio
  /// `ink`; no escuro vira creme.
  final Color onPaper;

  /// Texto e ícone sobre bloco [ink] ou sobre `lime`/`coral` quando o claro
  /// usa `paper` nesse papel. No tema claro é o próprio `paper`.
  final Color onInk;
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

  /// Segundo tom do módulo `diagonal` sobre `ink` — os triângulos precisam de
  /// dois tons (§9.4). Os outros módulos usam só [inkPattern].
  final Color inkPatternAlt;
  final Color limePattern;

  const AppColors({
    required this.ink,
    required this.inkSoft,
    required this.paper,
    required this.paperSoft,
    required this.onPaper,
    required this.onInk,
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
    required this.inkPatternAlt,
    required this.limePattern,
  });

  static const AppColors light = AppColors(
    ink: Color(0xFF16150F),
    inkSoft: Color(0xFF2B2A20),
    paper: Color(0xFFF5F2EA),
    paperSoft: Color(0xFFE9E5D8),
    onPaper: Color(0xFF16150F),
    onInk: Color(0xFFF5F2EA),
    lime: Color(0xFFD6F45A),
    coral: Color(0xFFFF5A38),
    coralLight: Color(0xFFFF7A5E),
    violetDeep: Color(0xFF6558E0),
    violet: Color(0xFF7B6CF6),
    textMuted: Color(0xFF686555),
    textBody: Color(0xFF3D3B30),
    danger: Color(0xFFC0203F),
    onSaturated: Color(0xFFFFFFFF),
    coralMuted: Color(0xFFFFB3A4),
    violetMuted: Color(0xFFC2BCFA),
    coralPattern: Color(0xFFFF7A5E),
    violetPattern: Color(0xFF9A8EF9),
    inkPattern: Color(0xFF2B2A20),
    inkPatternAlt: Color(0xFF37362A),
    limePattern: Color(0xFFC2E33F),
  );

  /// Variante de alto contraste (RF-08.3): papel branco, texto quase preto e
  /// acentos mais fundos. Todo par texto/fundo usado no app passa de 4,5:1
  /// (AA) — `high_contrast_test.dart` confere.
  static const AppColors highContrast = AppColors(
    ink: Color(0xFF000000),
    inkSoft: Color(0xFF1A1A14),
    paper: Color(0xFFFFFFFF),
    paperSoft: Color(0xFFEDEAE0),
    onPaper: Color(0xFF000000),
    onInk: Color(0xFFFFFFFF),
    lime: Color(0xFFD6F45A),
    coral: Color(0xFFB82E0E),
    coralLight: Color(0xFFD9411F),
    violetDeep: Color(0xFF3A2DA0),
    violet: Color(0xFF4B3CC4),
    textMuted: Color(0xFF4A473B),
    textBody: Color(0xFF1F1E16),
    danger: Color(0xFF9E0F2E),
    onSaturated: Color(0xFFFFFFFF),
    coralMuted: Color(0xFFFFE3DC),
    violetMuted: Color(0xFFE2DFFD),
    coralPattern: Color(0xFFC93C1B),
    violetPattern: Color(0xFF5A4BD2),
    inkPattern: Color(0xFF1A1A14),
    inkPatternAlt: Color(0xFF24241B),
    limePattern: Color(0xFFC2E33F),
  );

  /// Modo escuro (§9.2): `ink` não inverte, a paleta já é escura. O `paper`
  /// escurece para `#1E1D16` e as cores saturadas perdem ~15% de saturação
  /// (e um pouco de luz, pra o branco sobre elas seguir legível). Blocos `ink`
  /// ficam mais fundos que a página; o texto sobre o papel passa a creme.
  static const AppColors dark = AppColors(
    ink: Color(0xFF0B0B07),
    inkSoft: Color(0xFF26251B),
    paper: Color(0xFF1E1D16),
    paperSoft: Color(0xFF2B2A20),
    onPaper: Color(0xFFF5F2EA),
    onInk: Color(0xFFF5F2EA),
    lime: Color(0xFFCDEB52),
    coral: Color(0xFFEC4B2B),
    coralLight: Color(0xFFF57A5E),
    violetDeep: Color(0xFF4838C0),
    violet: Color(0xFF5544E4),
    textMuted: Color(0xFF9A9684),
    textBody: Color(0xFFCFCCBF),
    danger: Color(0xFFE94F6E),
    onSaturated: Color(0xFFFFFFFF),
    coralMuted: Color(0xFFF5A798),
    violetMuted: Color(0xFFB8B1F2),
    coralPattern: Color(0xFFF2674B),
    violetPattern: Color(0xFF6E5CEC),
    inkPattern: Color(0xFF1C1B14),
    inkPatternAlt: Color(0xFF25241B),
    limePattern: Color(0xFFB9D646),
  );

  @override
  AppColors copyWith({
    Color? ink,
    Color? inkSoft,
    Color? paper,
    Color? paperSoft,
    Color? onPaper,
    Color? onInk,
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
    Color? inkPatternAlt,
    Color? limePattern,
  }) {
    return AppColors(
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      paper: paper ?? this.paper,
      paperSoft: paperSoft ?? this.paperSoft,
      onPaper: onPaper ?? this.onPaper,
      onInk: onInk ?? this.onInk,
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
      inkPatternAlt: inkPatternAlt ?? this.inkPatternAlt,
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
      onPaper: Color.lerp(onPaper, other.onPaper, t)!,
      onInk: Color.lerp(onInk, other.onInk, t)!,
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
      inkPatternAlt: Color.lerp(inkPatternAlt, other.inkPatternAlt, t)!,
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

extension AppColorsContrast on AppColors {
  /// Vermelho de perigo para texto e ícone sobre blocos escuros (`ink`,
  /// `inkSoft`): `danger` sozinho não chega a 3:1 ali no tema claro.
  Color get dangerOnDark => const Color(0xFFFF7088);
}
