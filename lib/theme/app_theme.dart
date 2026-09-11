import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';

/// Estilo da barra de status do sistema (hora, bateria). Blocos escuros no topo
/// (header da home/busca, hero de receita, modo cozinha) pedem ícones claros;
/// telas de fundo `paper` usam os escuros — o default do tema claro.
abstract class SystemBars {
  static const onDark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static const onLight = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );
}

/// `ThemeData` montado inteiramente a partir dos tokens (§9.9 do plano).
///
/// Nenhuma cor ou `TextStyle` literal deve existir fora de `lib/theme/` —
/// telas consomem via `context.colors` e `Theme.of(context).textTheme`.
abstract class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  /// Modo escuro é decisão pendente no plano (§9.2) — a paleta não inverte
  /// trivialmente e a tela de Compras já nasce escura. Isto é um rascunho.
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.paper,
      extensions: [colors],
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.coral,
        brightness: brightness,
      ).copyWith(
        primary: colors.coral,
        secondary: colors.violet,
        surface: colors.paper,
        error: colors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.paper,
        foregroundColor: colors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.displayS.copyWith(color: colors.ink),
      ),
      inputDecorationTheme: _inputTheme(colors),
      textTheme: _textTheme(colors),
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }

  /// Mesma transição em toda plataforma (não a zoom do Android nem o slide
  /// lateral do iOS) — fade + leve subida, o mesmo par curva/deslocamento da
  /// folha de conteúdo subindo sobre o hero (§9.8), só que na página inteira.
  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _AppPageTransitionsBuilder(),
      TargetPlatform.iOS: _AppPageTransitionsBuilder(),
      TargetPlatform.macOS: _AppPageTransitionsBuilder(),
      TargetPlatform.linux: _AppPageTransitionsBuilder(),
      TargetPlatform.windows: _AppPageTransitionsBuilder(),
    },
  );

  /// Campos chapados sobre `paperSoft`, sem borda em repouso (§9.1). O foco
  /// ganha um anel `ink` fino — indicação de foco é acessibilidade (RNF-05),
  /// não ornamento.
  static InputDecorationTheme _inputTheme(AppColors colors) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: width == 0
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: colors.paperSoft,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      hintStyle: AppTextStyles.body.copyWith(color: colors.textMuted),
      border: border(colors.ink, 0),
      enabledBorder: border(colors.ink, 0),
      focusedBorder: border(colors.ink, 1.5),
      errorBorder: border(colors.danger, 1.5),
      focusedErrorBorder: border(colors.danger, 1.5),
    );
  }

  static TextTheme _textTheme(AppColors colors) {
    final ink = colors.ink;
    final body = colors.textBody;
    final muted = colors.textMuted;

    return TextTheme(
      // Display — Bricolage 800. Ver escala na §9.3.
      displayLarge: AppTextStyles.displayL.copyWith(color: ink),
      displayMedium: AppTextStyles.displayM.copyWith(color: ink),
      displaySmall: AppTextStyles.displayS.copyWith(color: ink),
      titleLarge: AppTextStyles.displayS.copyWith(color: ink),
      titleMedium: AppTextStyles.metric.copyWith(color: ink),

      // Interface — sans do sistema, nunca acima de 500.
      bodyLarge: AppTextStyles.body.copyWith(color: body),
      bodyMedium: AppTextStyles.body.copyWith(color: body),
      labelLarge: AppTextStyles.label.copyWith(color: body),
      labelMedium: AppTextStyles.label.copyWith(color: muted),
      labelSmall: AppTextStyles.labelCaps.copyWith(color: muted),
    );
  }
}

extension ThemeContextExtension on BuildContext {
  /// Acesso tipado aos tokens de cor: `context.colors.lime`.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// Atalho para a escala tipográfica já colorida pelo tema.
  TextTheme get texts => Theme.of(this).textTheme;
}

/// Só um fade — de propósito o efeito mais barato de compor que existe.
/// Chegamos a testar fade + deslocamento + escala na página de baixo, mas
/// compor duas telas cheias ao mesmo tempo derrubava quadro e lia como bug,
/// não como transição.
class _AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
      child: child,
    );
  }
}
