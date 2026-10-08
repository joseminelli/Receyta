import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/stretch_indicator.dart';

/// Uma aba: ícone e nome.
class UnderlineTab {
  const UnderlineTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Abas de duas ou mais seções da mesma tela: ícone e nome em cada uma, um fio
/// cinza por baixo e uma barra escura que desliza até a aba escolhida. Parece
/// com abas de verdade — e não se confunde com os seletores em pílula (como o
/// de Semana/Mês), que escolhem um *valor* e não uma *seção*.
class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<UnderlineTab> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final n = tabs.length;
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(height: 2, color: colors.paperSoft),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == selected,
                  child: InkWell(
                    onTap: () => onChanged(i),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.sm + 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tabs[i].icon,
                            size: 20,
                            color:
                                i == selected ? colors.ink : colors.textMuted,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style:
                                  (context.texts.bodyLarge ?? const TextStyle())
                                      .copyWith(
                                color: i == selected
                                    ? colors.ink
                                    : colors.textMuted,
                                fontWeight: i == selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                              child: Text(
                                tabs[i].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned.fill(
          child: StretchIndicator(
            index: selected,
            slotRect: (i, size) {
              const inset = AppSpacing.md;
              final slot = size.width / n;
              return Rect.fromLTWH(
                i * slot + inset,
                size.height - 4,
                slot - inset * 2,
                4,
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.ink,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
