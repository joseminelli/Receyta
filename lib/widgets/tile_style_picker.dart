import 'package:flutter/material.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Escolhe a cor e a textura do azulejo (§9.4) de uma receita ou pasta. Cada
/// eixo tem um "Auto" (nulo) além das quatro opções. Mostra o resultado numa
/// faixa de preview em cima.
class TileStylePicker extends StatelessWidget {
  const TileStylePicker({
    super.key,
    required this.color,
    required this.motif,
    required this.onChanged,
    this.fallbackColor = TileColor.coral,
    this.seedId,
  });

  final TileColor? color;
  final TileMotif? motif;
  final void Function(TileColor? color, TileMotif? motif) onChanged;

  /// Cor usada quando [color] é nulo e não há [seedId] — combina com o contexto
  /// (pastas caem em violet).
  final TileColor fallbackColor;

  /// Id da receita, pra prévia do "Auto" bater com o card real.
  final String? seedId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolved = resolveTileAppearance(
      colors,
      color: color,
      motif: motif,
      seedId: seedId,
      fallbackColor: fallbackColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: SizedBox(
            height: 64,
            width: double.infinity,
            child: TilePattern(
              motif: resolved.motif,
              background: resolved.background,
              patternColor: resolved.patternColor,
              patternColorAlt: resolved.patternColorAlt,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Caption('Cor'),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _Swatch(
              selected: color == null,
              onTap: () => onChanged(null, motif),
              child: const _Auto(),
            ),
            for (final c in TileColor.values)
              _Swatch(
                selected: color == c,
                onTap: () => onChanged(c, motif),
                child: ColoredBox(
                  color: resolveTileAppearance(colors, color: c).background,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _Caption('Textura'),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _Swatch(
              selected: motif == null,
              onTap: () => onChanged(color, null),
              child: const _Auto(),
            ),
            for (final m in TileMotif.values)
              _Swatch(
                selected: motif == m,
                onTap: () => onChanged(color, m),
                child: TilePattern(
                  motif: m,
                  background: resolved.background,
                  patternColor: resolved.patternColor,
                  patternColorAlt: resolved.patternColorAlt,
                  tile: 32,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Abre o menu de aparência (§9.4) — igual em espírito ao sheet do ⋯. Aplica
/// cada toque na hora via [onChanged], com prévia ao vivo.
Future<void> showAppearanceSheet(
  BuildContext context, {
  required String title,
  required TileColor? color,
  required TileMotif? motif,
  required TileColor fallbackColor,
  String? seedId,
  required void Function(TileColor? color, TileMotif? motif) onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _AppearanceSheet(
      title: title,
      color: color,
      motif: motif,
      fallbackColor: fallbackColor,
      seedId: seedId,
      onChanged: onChanged,
    ),
  );
}

class _AppearanceSheet extends StatefulWidget {
  const _AppearanceSheet({
    required this.title,
    required this.color,
    required this.motif,
    required this.fallbackColor,
    required this.seedId,
    required this.onChanged,
  });

  final String title;
  final TileColor? color;
  final TileMotif? motif;
  final TileColor fallbackColor;
  final String? seedId;
  final void Function(TileColor? color, TileMotif? motif) onChanged;

  @override
  State<_AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends State<_AppearanceSheet> {
  late TileColor? _color = widget.color;
  late TileMotif? _motif = widget.motif;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: context.texts.displaySmall),
            const SizedBox(height: AppSpacing.md),
            TileStylePicker(
              color: _color,
              motif: _motif,
              seedId: widget.seedId,
              fallbackColor: widget.fallbackColor,
              onChanged: (c, m) {
                setState(() {
                  _color = c;
                  _motif = m;
                });
                widget.onChanged(c, m);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.texts.labelSmall,
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.ink : colors.paperSoft,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: child,
        ),
      ),
    );
  }
}

class _Auto extends StatelessWidget {
  const _Auto();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.paperSoft,
      child: Icon(Icons.auto_awesome, size: 16, color: colors.textMuted),
    );
  }
}
