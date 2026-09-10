import 'package:flutter/material.dart';

/// Número ilustrativo em escala enorme, ancorado num canto e sangrando para
/// fora do bloco (§9.1, §9.8).
///
/// É o recurso que resolve o card de receita sem foto: o excesso vem de dado
/// real ampliado, não de ornamento aplicado.
///
/// Precisa de um [Stack] em volta e de clip no pai — o sangramento depende
/// disso para não vazar sobre os vizinhos:
///
/// ```dart
/// ClipRRect(
///   borderRadius: BorderRadius.circular(AppRadii.md),
///   child: Stack(children: [
///     ColoredBox(...),
///     HeroNumber(value: '25', color: colors.coralLight),
///     // conteúdo por cima
///   ]),
/// )
/// ```
///
/// Sobre um bloco com azulejo, use branco sólido: em tom sobre tom o número
/// desaparece no padrão (§9.4).
class HeroNumber extends StatelessWidget {
  const HeroNumber({
    super.key,
    required this.value,
    required this.color,
    this.corner = Alignment.bottomRight,
    this.size = 96,
    this.bleed,
    this.unit,
  });

  final String value;
  final Color color;

  /// Sufixo pequeno colado no valor ("min"). Deixa claro o que o número mede.
  final String? unit;

  /// Canto de ancoragem. O sangramento segue a direção do canto.
  final Alignment corner;

  /// 86–130 conforme o bloco (§9.3).
  final double size;

  /// Quanto o número ultrapassa a borda. Padrão: 18% do tamanho da fonte.
  final double? bleed;

  @override
  Widget build(BuildContext context) {
    final bleed = this.bleed ?? size * 0.18;

    return Align(
      alignment: corner,
      child: Transform.translate(
        offset: Offset(corner.x * bleed, corner.y * bleed),
        child: MediaQuery.withNoTextScaling(
          // Elemento gráfico, não texto de leitura: em 200% ele estouraria o
          // bloco inteiro (RNF-12). O mesmo dado aparece legível no MetricStat,
          // que acompanha a escala do sistema normalmente.
          child: ExcludeSemantics(
            child: Text.rich(
              TextSpan(
                text: value,
                children: unit == null
                    ? null
                    : [
                        TextSpan(
                          text: unit,
                          style: TextStyle(
                            fontSize: size * 0.22,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
              ),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: size,
                    letterSpacing: size * -0.045,
                    color: color,
                  ),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
      ),
    );
  }
}
