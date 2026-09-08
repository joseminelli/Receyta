import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

/// Um destino da [PillNavBar].
class PillNavItem {
  const PillNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barra de navegação flutuante em pílula `ink`, item ativo em `lime` (§9.8).
///
/// Inativos mostram só o ícone; o ativo abre para ícone + label. É a forma de
/// dizer onde você está sem gastar altura, e o movimento de abrir dá o feedback
/// da troca sem precisar de animação de tela.
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
      child: Material(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavSlot(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onSelected(i),
                ),
            ],
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
    final foreground = selected ? colors.ink : colors.paperSoft;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: AppSpacing.minTapTarget,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? AppSpacing.md : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.lime : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 20, color: foreground),
              // AnimatedSize evita o salto de largura quando o label entra.
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
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
