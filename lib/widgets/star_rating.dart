import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';

/// Cinco estrelas. Com [onChanged] vira seletor (tocar na estrela já marcada
/// limpa); sem ele é só leitura.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 18,
  });

  final int? value;
  final ValueChanged<int?>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = value ?? 0;
    return Semantics(
      label: current == 0 ? 'Sem avaliação' : '$current de 5 estrelas',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            _star(
              i,
              AnimatedScale(
                scale: i == current ? 1.2 : 1,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
                child: Icon(
                  i <= current
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: size,
                  color: i <= current ? colors.onPaper : colors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _star(int i, Widget icon) {
    final onChanged = this.onChanged;
    if (onChanged == null) return icon;
    return InkResponse(
      key: Key('star-$i'),
      radius: size,
      onTap: () => onChanged(i == value ? null : i),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: icon,
      ),
    );
  }
}
