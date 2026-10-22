import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Papel do toast: define acento da borda e ícone do chip. `loading` não some
/// sozinho — espera virar outro tipo via [AppToastHandle].
enum AppToastKind { success, error, info, loading }

class _ToastData {
  const _ToastData({
    required this.id,
    required this.kind,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final int id;
  final AppToastKind kind;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  bool get hasBody => description != null;

  bool get hasAction => actionLabel != null;
}

/// Alça de um toast em andamento. Serve pra transformar o loading em
/// sucesso/erro sem abrir outro toast — o cartão faz o morph no lugar.
class AppToastHandle {
  const AppToastHandle._(this._id);

  final int _id;

  void success(String title, {String? description}) =>
      AppToast._morph(_id, AppToastKind.success, title, description);

  void error(String title, {String? description}) =>
      AppToast._morph(_id, AppToastKind.error, title, description);

  void info(String title, {String? description}) =>
      AppToast._morph(_id, AppToastKind.info, title, description);

  /// Troca o título do loading em andamento (ex.: "Importando 3 de 12").
  void progress(String title) =>
      AppToast._morph(_id, AppToastKind.loading, title, null);

  void dismiss() => AppToast.dismiss(_id);
}

/// Toast/loader em pílula que se expande em cartão (inspirado no Sileo).
/// Um único `OverlayEntry` na raiz; chamadas seguidas trocam o conteúdo no
/// lugar em vez de empilhar.
abstract class AppToast {
  static final _state = ValueNotifier<_ToastData?>(null);
  static OverlayEntry? _entry;
  static Timer? _timer;
  static int _seq = 0;

  static AppToastHandle show(
    BuildContext context, {
    required String title,
    String? description,
    AppToastKind kind = AppToastKind.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final id = ++_seq;
    if (!_ensureEntry(context)) return AppToastHandle._(id);
    _publish(
      _ToastData(
        id: id,
        kind: kind,
        title: title,
        description: description,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
      duration,
    );
    return AppToastHandle._(id);
  }

  static AppToastHandle loading(BuildContext context, String title) =>
      show(context, title: title, kind: AppToastKind.loading);

  static Future<T> promise<T>(
    BuildContext context,
    Future<T> future, {
    required String loading,
    required String Function(T value) success,
    required String Function(Object error) error,
  }) async {
    final handle = AppToast.loading(context, loading);
    try {
      final value = await future;
      handle.success(success(value));
      return value;
    } catch (e) {
      handle.error(error(e));
      rethrow;
    }
  }

  /// Fecha o toast atual; com [id], só se ainda for aquele.
  static void dismiss([int? id]) {
    if (id != null && id != _state.value?.id) return;
    _timer?.cancel();
    _state.value = null;
  }

  static void _morph(
    int id,
    AppToastKind kind,
    String title,
    String? description,
  ) {
    if (_state.value?.id != id) return;
    _publish(
      _ToastData(id: id, kind: kind, title: title, description: description),
      const Duration(seconds: 4),
    );
  }

  static void _publish(_ToastData data, Duration duration) {
    _timer?.cancel();
    _state.value = data;
    if (data.kind == AppToastKind.loading) return;
    _timer = Timer(duration, () => dismiss(data.id));
  }

  static bool _ensureEntry(BuildContext context) {
    if (_entry != null) return true;
    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) return false;
    _entry = OverlayEntry(
      builder: (_) => _ToastHost(
        state: _state,
        onGone: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );
    overlay.insert(_entry!);
    return true;
  }
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({required this.state, required this.onGone});

  final ValueNotifier<_ToastData?> state;
  final VoidCallback onGone;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _bounce = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0, 0.55, curve: Curves.easeOut),
    reverseCurve: Curves.easeIn,
  );
  late final Animation<double> _iconBounce = CurvedAnimation(
    parent: _anim,
    curve: const Interval(0.3, 1, curve: Curves.easeOutBack),
    reverseCurve: Curves.easeIn,
  );
  static final _scaleX = Tween<double>(begin: 0.1, end: 1);
  static final _scaleY = Tween<double>(begin: 0.5, end: 1);

  _ToastData? _last;

  @override
  void initState() {
    super.initState();
    _last = widget.state.value;
    widget.state.addListener(_sync);
    _anim.forward();
  }

  Future<void> _sync() async {
    final data = widget.state.value;
    if (data != null) {
      setState(() => _last = data);
      _anim.forward();
      return;
    }
    await _anim.reverse();
    if (mounted && widget.state.value == null) widget.onGone();
  }

  @override
  void dispose() {
    widget.state.removeListener(_sync);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _last;
    if (data == null) return const SizedBox.shrink();
    return Positioned(
      left: AppSpacing.screen,
      right: AppSpacing.screen,
      top: MediaQuery.paddingOf(context).top + kToolbarHeight + AppSpacing.xs,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: _bounce,
          builder: (context, child) => Transform.scale(
            scaleX: _scaleX.evaluate(_bounce),
            scaleY: _scaleY.evaluate(_bounce),
            alignment: Alignment.topCenter,
            child: child,
          ),
          child: FadeTransition(
            opacity: _fade,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  onTap: data.kind == AppToastKind.loading || data.hasAction
                      ? null
                      : AppToast.dismiss,
                  onVerticalDragEnd: (_) {
                    if (data.kind != AppToastKind.loading) AppToast.dismiss();
                  },
                  child: _ToastCard(data: data, iconAnim: _iconBounce),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão líquido: a pílula do título e o bloco de descrição/ação são duas
/// formas `ink` separadas por uma fresta; um blur + corte de alpha (o filtro
/// "gooey") funde as duas num blob só, com o pescoço côncavo se formando e
/// desfazendo conforme o corpo cresce com mola. O conteúdo fica numa camada
/// idêntica por cima, sem filtro.
class _ToastCard extends StatefulWidget {
  const _ToastCard({required this.data, required this.iconAnim});

  final _ToastData data;
  final Animation<double> iconAnim;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> {
  static const double _pillRadius = 20;
  static const double _gap = 6;

  static final ImageFilter _goo = ImageFilter.compose(
    outer: const ColorFilter.matrix(<double>[
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0, //
      0, 0, 1, 0, 0, //
      0, 0, 0, 18, -7, //
    ]),
    inner: ImageFilter.blur(
      sigmaX: 5,
      sigmaY: 5,
      tileMode: TileMode.decal,
    ),
  );

  Timer? _openTimer;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _scheduleOpen();
  }

  @override
  void didUpdateWidget(_ToastCard old) {
    super.didUpdateWidget(old);
    final a = old.data;
    final b = widget.data;
    if (a.id != b.id || a.kind != b.kind || a.title != b.title) {
      _openTimer?.cancel();
      _open = false;
      _scheduleOpen();
    }
  }

  void _scheduleOpen() {
    if (!widget.data.hasBody) return;
    _openTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => _open = true);
    });
  }

  @override
  void dispose() {
    _openTimer?.cancel();
    super.dispose();
  }

  Color _chipColor(AppColors colors) => switch (widget.data.kind) {
        AppToastKind.success => colors.lime,
        AppToastKind.error => colors.danger,
        AppToastKind.info => colors.violet,
        AppToastKind.loading => colors.inkSoft,
      };

  Color _onChip(AppColors colors) => switch (widget.data.kind) {
        AppToastKind.success => colors.ink,
        AppToastKind.error || AppToastKind.info => colors.onSaturated,
        AppToastKind.loading => colors.onInk,
      };

  Color _titleColor(AppColors colors) => switch (widget.data.kind) {
        AppToastKind.success => colors.lime,
        AppToastKind.error => colors.danger,
        AppToastKind.info => colors.violetMuted,
        AppToastKind.loading => colors.onInk.withValues(alpha: 0.6),
      };

  Widget _chip(AppColors colors) {
    final kind = widget.data.kind;
    final onChip = _onChip(colors);
    final icon = switch (kind) {
      AppToastKind.success => Icons.check_rounded,
      AppToastKind.error => Icons.priority_high_rounded,
      AppToastKind.info => Icons.info_outline_rounded,
      AppToastKind.loading => Icons.hourglass_empty_rounded,
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
      child: Container(
        key: ValueKey(kind),
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _chipColor(colors),
          shape: BoxShape.circle,
        ),
        child: kind == AppToastKind.loading
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: onChip,
                ),
              )
            : Icon(icon, size: 16, color: onChip),
      ),
    );
  }

  Widget _title(AppColors colors) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      child: Text(
        widget.data.title,
        key: ValueKey(widget.data.title),
        maxLines: widget.data.hasAction ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.bodyMedium?.copyWith(
          color: _titleColor(colors),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _action() {
    final data = widget.data;
    return _ToastAction(
      label: data.actionLabel!,
      onPressed: () {
        data.onAction?.call();
        AppToast.dismiss(data.id);
      },
    );
  }

  Widget _header(AppColors colors, {required bool ghost}) {
    final data = widget.data;
    final inlineAction = data.hasAction && !data.hasBody;
    return Container(
      padding: EdgeInsets.fromLTRB(6, 6, inlineAction ? 6 : 16, 6),
      decoration: BoxDecoration(
        color: ghost ? colors.ink : null,
        borderRadius: BorderRadius.circular(_pillRadius),
      ),
      child: Opacity(
        opacity: ghost ? 0 : 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(scale: widget.iconAnim, child: _chip(colors)),
            const SizedBox(width: AppSpacing.xs),
            Flexible(child: _title(colors)),
            if (inlineAction) ...[
              const SizedBox(width: AppSpacing.sm),
              _action(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(AppColors colors, double t, {required bool ghost}) {
    final data = widget.data;
    final content = Row(
      children: [
        Expanded(
          child: Text(
            data.description!,
            style: context.texts.bodyMedium?.copyWith(
              color: colors.onInk.withValues(alpha: 0.72),
            ),
          ),
        ),
        if (data.hasAction) ...[
          const SizedBox(width: AppSpacing.sm),
          _action(),
        ],
      ],
    );
    final reveal = const Interval(0.45, 1).transform(t);
    return Container(
      margin: const EdgeInsets.only(top: _gap),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ghost ? colors.ink : null,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Opacity(opacity: ghost ? 0 : reveal, child: content),
    );
  }

  Widget _layout(AppColors colors, double t, {required bool ghost}) {
    final spring = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: _header(colors, ghost: ghost),
        ),
        if (t > 0)
          Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            child: Transform(
              alignment: Alignment.topCenter,
              transform:
                  Matrix4.diagonal3Values(0.45 + 0.55 * spring, spring, 1),
              child: _body(colors, t, ghost: ghost),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _open ? 1 : 0),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => Stack(
        children: [
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: _goo,
              child: _layout(colors, t, ghost: true),
            ),
          ),
          _layout(colors, t, ghost: false),
        ],
      ),
    );
  }
}

/// Ação discreta do toast: texto `lime` sobre `inkSoft`, baixa e alinhada à
/// direita — lê como complemento da mensagem, não como botão a ser clicado.
class _ToastAction extends StatelessWidget {
  const _ToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.inkSoft,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Text(
            label,
            style: context.texts.labelMedium?.copyWith(
              color: colors.lime,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
