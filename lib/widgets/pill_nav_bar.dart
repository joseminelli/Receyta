import 'package:flutter/material.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Um destino da [PillNavBar]. `color` é a cor da seção (§9.2) — o `motif` fica
/// só de referência pra quem consome via [TileMotif], a navbar em si não
/// desenha o azulejo (ficava grosseiro nesse tamanho).
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
/// uma barra de ponta a ponta. Inativos mostram só o ícone; o ativo ganha a
/// cor da seção e o ícone entra num medalhão, com ícone + label.
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

class _NavSlot extends StatefulWidget {
  const _NavSlot({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavSlot> createState() => _NavSlotState();
}

class _NavSlotState extends State<_NavSlot> with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    if (widget.selected) _pop.value = 1;
  }

  @override
  void didUpdateWidget(covariant _NavSlot old) {
    super.didUpdateWidget(old);
    // Só estoura ao ENTRAR selecionado — sair não anima o ícone, a pílula só
    // encolhe (o `AnimatedContainer` já cuida disso).
    if (widget.selected && !old.selected) {
      _pop.forward(from: 0);
    } else if (!widget.selected) {
      _pop.value = 0;
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = widget.item;
    final selected = widget.selected;
    final onSection =
        item.color.computeLuminance() > 0.5 ? colors.ink : colors.onSaturated;
    final foreground =
        selected ? onSection : colors.onSaturated.withValues(alpha: 0.5);
    // Medalhão atrás do ícone quando ativo — mesmo par "ícone dentro de
    // círculo de tom" do chip do AppSnackBar e dos estados vazios: um tom do
    // próprio `onSection` misturado na cor da seção, sutil o bastante pra não
    // brigar com o ícone por cima.
    final medallion = Color.lerp(item.color, onSection, 0.18)!;
    // Estouro do ícone ao selecionar — mesmo easeOutBack do chip do
    // AppSnackBar e dos pills do menu `+`.
    final iconPop = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _pop, curve: Curves.easeOutBack),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: widget.onTap,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: iconPop,
                child: selected
                    ? Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: medallion,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, size: 17, color: foreground),
                      )
                    : Icon(item.icon, size: 21, color: foreground),
              ),
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
        ),
      ),
    );
  }
}

