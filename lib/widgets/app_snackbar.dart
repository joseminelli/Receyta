import 'dart:async';

import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Papel visual do snackbar: define o chip de ícone e o acento da borda —
/// nunca cinza neutro, sempre um bloco de cor da paleta (§9.2).
enum AppSnackBarVariant {
  /// Confirmação — chip `lime`, ícone de check.
  success,

  /// Falha — chip `danger`, ícone de alerta.
  error,
}

/// Snackbar totalmente próprio, inserido direto no `Overlay` da raiz — não
/// depende de `ScaffoldMessenger`/`SnackBar` do Material, então nunca fica
/// escondido atrás de um `Scaffold` sem messenger ou de um tema que engula o
/// widget padrão. Visual em bloco `ink`, chip de ícone circular, borda
/// acentuada e ação em pílula — a mesma linguagem gráfica dos cards e botões
/// do app (§9.8).
abstract class AppSnackBar {
  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarVariant variant = AppSnackBarVariant.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) return;

    _current?.remove();
    _current = null;

    late final OverlayEntry entry;
    void remove() {
      if (identical(_current, entry)) {
        _current = null;
      }
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => _AppSnackBarHost(
        message: message,
        variant: variant,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        onDismissed: remove,
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _AppSnackBarHost extends StatefulWidget {
  const _AppSnackBarHost({
    required this.message,
    required this.variant,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final AppSnackBarVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_AppSnackBarHost> createState() => _AppSnackBarHostState();
}

class _AppSnackBarHostState extends State<_AppSnackBarHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _anim.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    await _anim.reverse();
    widget.onDismissed();
  }

  void _runAction() {
    widget.onAction?.call();
    _dismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Entrada como se brotasse da câmera frontal: um traço fino no centro
    // do topo que se abre pros dois lados (scaleX) enquanto ganha altura
    // (scaleY) — mesmo easeOutBack de estouro dos pills do menu `+`. Saída
    // é só um fade rápido, sem quique, pra não distrair no dismiss.
    final bounce = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    final fade = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );
    // O chip do ícone estoura um pouco depois do cartão (delay via
    // Interval) — o mesmo escalonamento dos pills do menu `+`.
    final iconBounce = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.3, 1, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeIn,
    );
    final scaleX = Tween<double>(begin: 0.1, end: 1);
    final scaleY = Tween<double>(begin: 0.5, end: 1);
    return Positioned(
      left: AppSpacing.screen,
      right: AppSpacing.screen,
      // Abaixo da altura de uma AppBar padrão — limpa tanto a AppBar quanto
      // o botão circular de "voltar" sobre o hero das telas de receita.
      top: MediaQuery.paddingOf(context).top + kToolbarHeight + AppSpacing.xs,
      child: AnimatedBuilder(
        animation: bounce,
        builder: (context, child) => Transform.scale(
          scaleX: scaleX.evaluate(bounce),
          scaleY: scaleY.evaluate(bounce),
          alignment: Alignment.topCenter,
          child: child,
        ),
        child: FadeTransition(
          opacity: fade,
          child: Material(
            type: MaterialType.transparency,
            child: GestureDetector(
              onTap: widget.actionLabel == null ? _dismiss : null,
              onVerticalDragEnd: (_) => _dismiss(),
              child: _AppSnackBarCard(
                message: widget.message,
                variant: widget.variant,
                actionLabel: widget.actionLabel,
                onAction: widget.actionLabel == null ? null : _runAction,
                iconAnim: iconBounce,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppSnackBarCard extends StatelessWidget {
  const _AppSnackBarCard({
    required this.message,
    required this.variant,
    required this.actionLabel,
    required this.onAction,
    required this.iconAnim,
  });

  final String message;
  final AppSnackBarVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Animation<double> iconAnim;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = switch (variant) {
      AppSnackBarVariant.success => colors.lime,
      AppSnackBarVariant.error => colors.danger,
    };
    final icon = switch (variant) {
      AppSnackBarVariant.success => Icons.check_rounded,
      AppSnackBarVariant.error => Icons.priority_high_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: accent, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: iconAnim,
            child: RotationTransition(
              turns: Tween<double>(begin: -0.2, end: 0).animate(iconAnim),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: accent, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: colors.ink),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodyLarge?.copyWith(
                color: colors.paper,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: AppSpacing.sm),
            PillButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: PillButtonVariant.accent,
              dense: true,
            ),
          ],
        ],
      ),
    );
  }
}
