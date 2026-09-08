import 'package:flutter/material.dart';

/// Papéis tipográficos do Receyta (§9.3 do plano).
///
/// Duas famílias, papéis rígidos: Bricolage Grotesque 800 para display,
/// sans do sistema (400/500) para interface — nunca acima de 500.
///
/// Nenhum estilo carrega cor: a cor vem do contexto de uso, porque as regras
/// de pareamento da §9.2 dependem do fundo (lime sobre ink, nunca sobre paper).
abstract class AppTextStyles {
  static const String displayFamily = 'Bricolage';

  /// Tracking negativo agressivo é assinatura da linguagem — sem ele o layout
  /// perde a personalidade inteira (§9.3). Em `em`, multiplicado pelo tamanho.
  static const double _displayTracking = -0.045;
  static const double _displayHeight = 0.92;

  /// O arquivo é uma variable font; o peso 800 vem do eixo `wght`.
  /// `fontWeight` sozinho não move o eixo de forma confiável.
  static const List<FontVariation> _weight800 = [FontVariation('wght', 800)];

  /// Display em Bricolage 800 num tamanho arbitrário.
  ///
  /// Use direto para os números ilustrativos, que variam de 86 a 130 conforme
  /// o bloco. Os papéis fixos abaixo são atalhos para os tamanhos da escala.
  static TextStyle display(double size) => TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        fontVariations: _weight800,
        letterSpacing: size * _displayTracking,
        height: _displayHeight,
      );

  /// Número ilustrativo que sangra na borda do bloco (86–130).
  static TextStyle get displayXl => display(96);

  /// Título de tela (44–52).
  static TextStyle get displayL => display(48);

  /// Nome de receita.
  static TextStyle get displayM => display(25);

  /// Título de seção (22–24).
  static TextStyle get displayS => display(22);

  /// Quantidade de ingrediente e métricas (17–28).
  static TextStyle get metric => display(20);

  /// Corpo de texto.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Label secundário e metadados (11–12).
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Label caps: 10px, tracking 0.16em. O texto precisa vir em maiúsculas —
  /// não há `textTransform` no Flutter.
  static const TextStyle labelCaps = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 10 * 0.16,
  );
}
