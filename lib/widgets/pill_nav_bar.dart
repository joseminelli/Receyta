import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
/// cor da seção e o ícone entra num medalhão, com ícone + label. A seleção em
/// si é uma pílula única que desliza do retângulo do item antigo pro do item
/// novo (em vez de sumir num e aparecer no outro): cada `_NavSlot` assenta no
/// tamanho final na hora (sem animação própria de largura) pra dar dois
/// pontos fixos — origem e destino — que o indicador interpola com
/// `Rect.lerp`. Se o próprio item também animasse a largura, o alvo ficaria
/// se mexendo durante o desliza e as duas animações brigariam.
///
/// Além do toque, dá pra **arrastar o dedo pela barra**: a aba é a da zona onde
/// o dedo está (a largura da barra dividida em partes iguais, uma por aba) e
/// soltar deixa na última escolhida. Zonas iguais, e não os retângulos reais,
/// de propósito: a aba ativa é mais larga que as outras e muda de lugar a cada
/// troca, o que faria a seleção tremer na divisa entre duas abas. Cada troca
/// dá um toque de vibração leve.
class PillNavBar extends StatefulWidget {
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
  State<PillNavBar> createState() => _PillNavBarState();
}

class _PillNavBarState extends State<PillNavBar>
    with SingleTickerProviderStateMixin {
  final _stackKey = GlobalKey();
  late List<GlobalKey> _slotKeys;
  late final AnimationController _slide;
  Rect? _previousRect;
  Rect? _targetRect;
  Rect? _indicatorRect;

  @override
  void initState() {
    super.initState();
    _slotKeys = List.generate(widget.items.length, (_) => GlobalKey());
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(_onSlideTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _snapToCurrent());
  }

  @override
  void didUpdateWidget(covariant PillNavBar old) {
    super.didUpdateWidget(old);
    if (widget.items.length != _slotKeys.length) {
      _slotKeys = List.generate(widget.items.length, (_) => GlobalKey());
      WidgetsBinding.instance.addPostFrameCallback((_) => _snapToCurrent());
    } else if (widget.currentIndex != old.currentIndex) {
      // O `_NavSlot` já assentou no tamanho final neste mesmo frame (sem
      // animação própria) — espera só o layout aplicar antes de medir o
      // destino, senão pega o retângulo antigo.
      _previousRect = _indicatorRect;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final r = _rectFor(widget.currentIndex);
        if (r == null) return;
        _targetRect = r;
        _previousRect ??= r;
        _slide.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  /// Aba da zona onde o dedo está; seleciona e vibra só se for outra.
  void _scrubTo(Offset globalPosition) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.width <= 0) return;
    final dx = box.globalToLocal(globalPosition).dx;
    final count = widget.items.length;
    final index = (dx / box.size.width * count).floor().clamp(0, count - 1);
    if (index == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.onSelected(index);
  }

  Rect? _rectFor(int index) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final slotBox =
        _slotKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || slotBox == null || !slotBox.attached) return null;
    final topLeft = slotBox.localToGlobal(Offset.zero, ancestor: stackBox);
    return topLeft & slotBox.size;
  }

  void _snapToCurrent() {
    final r = _rectFor(widget.currentIndex);
    if (r != null) {
      setState(() {
        _indicatorRect = r;
        _previousRect = r;
        _targetRect = r;
      });
    }
  }

  void _onSlideTick() {
    final from = _previousRect;
    final to = _targetRect;
    if (from == null || to == null) return;
    final t = Curves.easeOutCubic.transform(_slide.value);
    setState(() => _indicatorRect = Rect.lerp(from, to, t));
  }

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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _scrubTo(d.globalPosition),
            onHorizontalDragUpdate: (d) => _scrubTo(d.globalPosition),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs / 2),
              child: Stack(
                key: _stackKey,
                alignment: Alignment.centerLeft,
                children: [
                  if (_indicatorRect != null)
                    Positioned(
                      left: _indicatorRect!.left,
                      top: _indicatorRect!.top,
                      width: _indicatorRect!.width,
                      height: _indicatorRect!.height,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.items[widget.currentIndex].color,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < widget.items.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xs / 2),
                        _NavSlot(
                          key: _slotKeys[i],
                          item: widget.items[i],
                          selected: i == widget.currentIndex,
                          onTap: () => widget.onSelected(i),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatefulWidget {
  const _NavSlot({
    super.key,
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

class _NavSlotState extends State<_NavSlot>
    with SingleTickerProviderStateMixin {
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
        child: Container(
          // Sem animação de tamanho própria: assenta no formato final na
          // hora, pra dar ao `_PillNavBarState` um retângulo fixo de destino.
          // Quem desliza é só o indicador (cor), atrás disto.
          height: AppSpacing.minTapTarget,
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? AppSpacing.md : AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
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
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: FadeTransition(
                    // Some/aparece junto do estouro do ícone — o layout já
                    // está no tamanho final, só o texto ganha opacidade.
                    opacity: _pop,
                    child: Text(
                      item.label,
                      style:
                          context.texts.labelLarge?.copyWith(color: foreground),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
