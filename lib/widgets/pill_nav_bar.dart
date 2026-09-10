import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Um destino da [PillNavBar]. `color` e `motif` são da seção (§9.2/§9.4): a
/// pílula ativa vira uma lasca de azulejo — a cor da seção com o módulo dela
/// desenhado tom sobre tom no canto. É o que dá identidade à navegação.
class PillNavItem {
  const PillNavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.motif,
  });

  final IconData icon;
  final String label;
  final Color color;
  final TileMotif motif;
}

/// Ilha de navegação flutuante em pílula `ink` (§9.8) — compacta, centrada, não
/// uma barra de ponta a ponta. Inativos mostram só o ícone; o ativo abre numa
/// lasca de azulejo da seção, com ícone + label.
class PillNavBar extends StatelessWidget {
  const PillNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<PillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: colors.ink,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs / 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs / 2),
                  _NavSlot(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onSection =
        item.color.computeLuminance() > 0.5 ? colors.ink : colors.onSaturated;
    final foreground =
        selected ? onSection : colors.onSaturated.withValues(alpha: 0.5);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: AppSpacing.minTapTarget,
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? AppSpacing.md : AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: selected ? item.color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (selected)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MotifAccent(
                      motif: item.motif,
                      color: Color.lerp(item.color, colors.onSaturated, 0.16)!,
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 21, color: foreground),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.xs),
                            child: Text(
                              item.label,
                              style: context.texts.labelLarge
                                  ?.copyWith(color: foreground),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um único módulo do azulejo (§9.4) desenhado grande no canto da pílula ativa,
/// tom sobre tom. Não é o padrão repetido (que nunca entra na navegação) — é
/// uma lasca, do jeito que os números ilustrativos sangram na borda.
class _MotifAccent extends CustomPainter {
  _MotifAccent({required this.motif, required this.color});

  final TileMotif motif;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..isAntiAlias = true;
    final h = size.height;

    switch (motif) {
      case TileMotif.arco:
        final r = h * 1.5;
        canvas.drawPath(
          Path()
            ..moveTo(-h * 0.15, -h * 0.15)
            ..lineTo(r, -h * 0.15)
            ..arcToPoint(Offset(-h * 0.15, r),
                radius: Radius.circular(r), clockwise: false)
            ..close(),
          p,
        );
      case TileMotif.meiaLua:
        canvas.drawCircle(Offset(-h * 0.1, h / 2), h * 0.85, p);
      case TileMotif.ponto:
        canvas.drawCircle(Offset(h * 0.15, h * 0.3), h * 0.34, p);
        canvas.drawCircle(Offset(size.width - h * 0.1, h * 0.8), h * 0.34, p);
      case TileMotif.diagonal:
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(h * 1.4, 0)
            ..lineTo(0, h * 1.4)
            ..close(),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(_MotifAccent old) =>
      old.motif != motif || old.color != color;
}
