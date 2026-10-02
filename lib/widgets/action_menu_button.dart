import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Uma linha do [ActionMenuButton].
class ActionMenuItem {
  const ActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;
}

/// Botão circular que abre um cartão de ações ancorado nele: o ícone vira "x",
/// o cartão cresce a partir do botão e as linhas entram em sequência. Só
/// aparece uma ação a mais no cabeçalho em vez de vários botões.
class ActionMenuButton extends StatefulWidget {
  const ActionMenuButton({
    super.key,
    required this.items,
    this.tooltip = 'Mais ações',
  });

  final List<ActionMenuItem> items;
  final String tooltip;

  @override
  State<ActionMenuButton> createState() => _ActionMenuButtonState();
}

class _ActionMenuButtonState extends State<ActionMenuButton> {
  bool _open = false;
  bool _pressed = false;

  Future<void> _toggle() async {
    HapticFeedback.selectionClick();
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final anchor = origin & box.size;
    final screen = MediaQuery.sizeOf(context);

    setState(() => _open = true);
    final picked = await showGeneralDialog<ActionMenuItem>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar menu',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, _) => Stack(
        children: [
          CustomSingleChildLayout(
            delegate: _BelowCenteredDelegate(anchor),
            child: _MenuCard(
              items: widget.items,
              animation: animation,
              onPick: (item) => Navigator.of(dialogContext).pop(item),
            ),
          ),
        ],
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            alignment: Alignment(
              (anchor.center.dx / screen.width) * 2 - 1,
              -1,
            ),
            scale: Tween(begin: 0.6, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() => _open = false);
    picked?.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _toggle,
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _open ? colors.lime : colors.ink,
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                _open ? Icons.close : Icons.more_horiz,
                key: ValueKey(_open),
                size: 20,
                color: _open ? colors.ink : colors.onSaturated,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centraliza o cartão sob o botão, sem deixar sair da tela.
class _BelowCenteredDelegate extends SingleChildLayoutDelegate {
  _BelowCenteredDelegate(this.anchor);

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const margin = 12.0;
    final left = (anchor.center.dx - childSize.width / 2)
        .clamp(margin, size.width - childSize.width - margin);
    return Offset(left, anchor.bottom + 8);
  }

  @override
  bool shouldRelayout(_BelowCenteredDelegate old) => old.anchor != anchor;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.items,
    required this.animation,
    required this.onPick,
  });

  final List<ActionMenuItem> items;
  final Animation<double> animation;
  final ValueChanged<ActionMenuItem> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paper,
      elevation: 10,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 230, maxWidth: 290),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, item) in items.indexed)
                  _staggered(
                    i,
                    _MenuRow(item: item, onTap: () => onPick(item)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _staggered(int index, Widget child) {
    final start = (0.25 + index * 0.18).clamp(0.0, 0.8);
    final anim = CurvedAnimation(
      parent: animation,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position:
            Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({required this.item, required this.onTap});

  final ActionMenuItem item;
  final VoidCallback onTap;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = Theme.of(context).textTheme;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: _pressed ? colors.paperSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.item.icon, size: 18, color: colors.lime),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.label,
                        style: texts.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (widget.item.hint != null)
                        Text(
                          widget.item.hint!,
                          style: texts.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
