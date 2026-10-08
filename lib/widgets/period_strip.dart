import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';

/// Um período na faixa: o texto grande ([label]) e um complemento pequeno
/// ([caption]), como "Out" / "2026" ou "12–18" / "out". [id] é estável e dá o
/// `Key` do chip (`period-chip-<id>`).
class PeriodChoice {
  const PeriodChoice({required this.id, required this.label, this.caption});

  final String id;
  final String label;
  final String? caption;
}

/// Navegação por período das telas de custos e de retrospectiva: em cima um
/// seletor deslizante do tipo (Semana | Mês, Mês | Ano) e, embaixo, uma faixa
/// rolável com os períodos como chips — do mais antigo ao atual, que já vem
/// centralizado. Um toque em qualquer chip pula direto pra ele.
class PeriodStrip extends StatefulWidget {
  const PeriodStrip({
    super.key,
    required this.kinds,
    required this.kindIndex,
    required this.onKind,
    required this.choices,
    required this.selected,
    required this.onSelect,
  });

  final List<String> kinds;
  final int kindIndex;
  final ValueChanged<int> onKind;
  final List<PeriodChoice> choices;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  State<PeriodStrip> createState() => _PeriodStripState();
}

class _PeriodStripState extends State<PeriodStrip> {
  static const _chipWidth = 68.0;
  static const _gap = AppSpacing.xs;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centerSelected(animate: false),
    );
  }

  @override
  void didUpdateWidget(covariant PeriodStrip old) {
    super.didUpdateWidget(old);
    final listChanged = old.choices.length != widget.choices.length ||
        old.kindIndex != widget.kindIndex;
    if (listChanged || old.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _centerSelected(animate: !listChanged),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _centerSelected({required bool animate}) {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final target = widget.selected * (_chipWidth + _gap) +
        _chipWidth / 2 -
        position.viewportDimension / 2 +
        AppSpacing.screen;
    final offset = target.clamp(0.0, position.maxScrollExtent);
    if (animate) {
      _controller.animateTo(
        offset,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpTo(offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          child: SlidingSegmented(
            labels: widget.kinds,
            selected: widget.kindIndex,
            onChanged: widget.onKind,
          ),
        ),
        SizedBox(
          height: 64,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            itemCount: widget.choices.length,
            separatorBuilder: (_, __) => const SizedBox(width: _gap),
            itemBuilder: (context, i) => _Chip(
              key: Key('period-chip-${widget.choices[i].id}'),
              choice: widget.choices[i],
              width: _chipWidth,
              selected: i == widget.selected,
              onTap: () => widget.onSelect(i),
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.choice,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final PeriodChoice choice;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final main = selected ? colors.lime : colors.ink;
    final sub = selected ? colors.onSaturated : colors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: '${choice.label} ${choice.caption ?? ''}'.trim(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: selected ? colors.ink : colors.paperSoft,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  choice.label,
                  maxLines: 1,
                  style: AppTextStyles.display(20).copyWith(color: main),
                ),
                if (choice.caption != null)
                  Text(
                    choice.caption!,
                    maxLines: 1,
                    style: context.texts.labelSmall?.copyWith(color: sub),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seletor de tipo com o indicador deslizando entre as opções (o mesmo gesto
/// visual da barra de baixo do app).
class SlidingSegmented extends StatelessWidget {
  const SlidingSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final n = labels.length;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: n == 1
                ? Alignment.center
                : Alignment(-1 + 2 * selected / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.ink,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
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
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      onTap: () => onChanged(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: (context.texts.labelLarge ?? const TextStyle())
                              .copyWith(
                            color: i == selected ? colors.lime : colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          child: Text(labels[i]),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
