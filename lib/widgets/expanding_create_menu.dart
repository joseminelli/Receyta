import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Uma opção do [ExpandingCreateMenu].
class CreateMenuAction {
  const CreateMenuAction({
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
}

/// Botão `+` que abre um leque de opções saindo dele mesmo (§9 — flat, pílula).
/// Fecha ao escolher, ao tocar fora ou ao apertar de novo. As pílulas vão pra
/// baixo do botão, num overlay, então não empurram nem são cortadas pelo header.
/// Um degradê radial parte do botão pra dar ênfase às opções; pílulas herdam
/// a cor do próprio botão, sem sombra animada (mais leve pra animar junto).
class ExpandingCreateMenu extends StatefulWidget {
  const ExpandingCreateMenu({
    super.key,
    required this.actions,
    required this.buttonColor,
    required this.iconColor,
    this.icon = Icons.add,
    this.tooltip = 'Criar',
  });

  final List<CreateMenuAction> actions;
  final Color buttonColor;
  final Color iconColor;

  /// Ícone do botão fechado — vira [Icons.close] enquanto o leque está aberto.
  final IconData icon;
  final String tooltip;

  @override
  State<ExpandingCreateMenu> createState() => _ExpandingCreateMenuState();
}

class _ExpandingCreateMenuState extends State<ExpandingCreateMenu>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  final _buttonKey = GlobalKey();
  late final AnimationController _anim;

  /// Centro do botão em coordenadas de tela — o degradê radial parte daqui.
  Offset? _center;

  bool get _open => _portal.isShowing;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      _center = (box != null && box.hasSize)
          ? box.localToGlobal(box.size.center(Offset.zero))
          : null;
      _portal.show();
      _anim.forward();
      setState(() {});
    }
  }

  Future<void> _close() async {
    await _anim.reverse();
    if (mounted) {
      _portal.hide();
      setState(() {});
    }
  }

  void _run(CreateMenuAction action) {
    _close();
    action.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => _Overlay(
        link: _link,
        anim: _anim,
        actions: widget.actions,
        origin: _center,
        pillColor: widget.buttonColor,
        onBarrierTap: _close,
        onPick: _run,
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: Tooltip(
          message: widget.tooltip,
          child: Material(
            key: _buttonKey,
            color: widget.buttonColor,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _toggle,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    _open ? Icons.close : widget.icon,
                    key: ValueKey(_open),
                    size: 22,
                    color: widget.iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.link,
    required this.anim,
    required this.actions,
    required this.origin,
    required this.pillColor,
    required this.onBarrierTap,
    required this.onPick,
  });

  final LayerLink link;
  final Animation<double> anim;
  final List<CreateMenuAction> actions;
  final Offset? origin;
  final Color pillColor;
  final VoidCallback onBarrierTap;
  final ValueChanged<CreateMenuAction> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
    final size = MediaQuery.sizeOf(context);
    final o = origin ?? size.topRight(Offset.zero);
    final center = Alignment(
      (o.dx / size.width) * 2 - 1,
      (o.dy / size.height) * 2 - 1,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBarrierTap,
            child: FadeTransition(
              opacity: curved,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: center,
                    radius: 1.4,
                    colors: [
                      pillColor.withValues(alpha: 0.28),
                      colors.ink.withValues(alpha: 0.24),
                      colors.ink.withValues(alpha: 0.58),
                    ],
                    stops: const [0.0, 0.28, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, AppSpacing.sm),
          child: Align(
            alignment: Alignment.topRight,
            child: FadeTransition(
              opacity: curved,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.xs),
                      child: _Pill(
                        action: actions[i],
                        color: pillColor,
                        anim: anim,
                        delay: (i / actions.length) * 0.4,
                        onTap: () => onPick(actions[i]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.action,
    required this.color,
    required this.anim,
    required this.delay,
    required this.onTap,
  });

  final CreateMenuAction action;
  final Color color;
  final Animation<double> anim;
  final double delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onColor =
        color.computeLuminance() > 0.5 ? colors.ink : colors.onSaturated;
    // Janela de tempo própria por pílula, não até o fim (1) — senão a última
    // pílula do leque mal tem tempo de animar e "trava" no lugar. `anim` aqui
    // é o `AnimationController` cru (0→1 linear); aplicar o `Interval` sobre
    // uma curva já suavizada distorcia esse intervalo.
    final slide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: anim,
        curve: Interval(
          delay,
          (delay + 0.6).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return SlideTransition(
      position: slide,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action.icon, size: 18, color: onColor),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  action.label,
                  style: context.texts.labelLarge?.copyWith(
                    color: onColor,
                    fontWeight: FontWeight.w600,
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
