import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/domain/engine/cook_log_format.dart';
import 'package:receyta/features/mascot/widgets/animated_mascot.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/star_rating.dart';

/// "Como ficou?": estrelas, atalhos de frase e uma nota pra um registro que
/// acabou de nascer. O cloche aparece acima da folha. Fechar sem salvar deixa
/// o registro como está.
Future<void> showCookFeedbackSheet(
  BuildContext context,
  String logId, {
  String? recipeName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _FeedbackSheet(logId: logId, recipeName: recipeName),
  );
}

class _FeedbackSheet extends ConsumerStatefulWidget {
  const _FeedbackSheet({required this.logId, this.recipeName});

  final String logId;
  final String? recipeName;

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet>
    with WidgetsBindingObserver {
  final _note = TextEditingController();
  final _sheetKey = GlobalKey();
  Animation<double>? _routeAnimation;
  OverlayEntry? _mascot;
  final _ratingListenable = ValueNotifier<int?>(null);
  int? _rating;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final animation = ModalRoute.of(context)?.animation;
      if (!mounted || animation == null) return;
      _routeAnimation = animation..addStatusListener(_onRouteStatus);
      _onRouteStatus(animation.status);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _removeMascot();
    _note.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _mascot?.markNeedsBuild());
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _insertMascot();
    } else {
      _removeMascot();
    }
  }

  double? _sheetTop() {
    final box = _sheetKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    return box.localToGlobal(Offset.zero).dy;
  }

  void _insertMascot() {
    if (_mascot != null) return;
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _mascot = OverlayEntry(
      builder: (_) {
        final top = _sheetTop();
        if (top == null) return const SizedBox.shrink();
        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: top,
          child: IgnorePointer(child: _AskingCloche(rating: _ratingListenable)),
        );
      },
    );
    overlay.insert(_mascot!);
  }

  void _removeMascot() {
    _mascot?.remove();
    _mascot = null;
  }

  void _setRating(int? value) {
    HapticFeedback.selectionClick();
    _ratingListenable.value = value;
    setState(() => _rating = value);
  }

  void _togglePhrase(String phrase) {
    HapticFeedback.selectionClick();
    final text = toggleNotePhrase(_note.text, phrase);
    setState(() {
      _note.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref.read(cookLogRepositoryProvider).setFeedback(
          widget.logId,
          rating: _rating,
          note: _note.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) => Navigator.of(context).pop(),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canSave = _rating != null || _note.text.trim().isNotEmpty;
    final name = widget.recipeName?.trim() ?? '';
    return Padding(
      key: _sheetKey,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (name.isNotEmpty)
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.texts.labelSmall
                      ?.copyWith(color: colors.textMuted, letterSpacing: 1.2),
                ),
              Text(
                'Como ficou?',
                textAlign: TextAlign.center,
                style: AppTextStyles.display(40),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: StarRating(
                  value: _rating,
                  size: 46,
                  onChanged: _setRating,
                ),
              ),
              SizedBox(
                height: 36,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _rating == null
                          ? 'Toque numa estrela'
                          : ratingVerdict(_rating),
                      key: ValueKey(_rating),
                      style: _rating == null
                          ? context.texts.bodyMedium
                              ?.copyWith(color: colors.textMuted)
                          : AppTextStyles.display(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final phrase in kQuickFeedbackPhrases)
                    ChoicePill(
                      label: phrase,
                      selected: noteHasPhrase(_note.text, phrase),
                      onTap: () => _togglePhrase(phrase),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Ou escreva do seu jeito…',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Pular',
                      variant: PillButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    flex: 2,
                    child: PillButton(
                      label: 'Salvar',
                      icon: Icons.check_rounded,
                      loading: _saving,
                      onPressed: (_saving || !canSave) ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Como o cloche se sente com as estrelas: pensativo sem nota, triste nas
/// baixas, simpático no meio, animado nas altas e festejando na máxima.
MascotMood _moodFor(int? stars) => switch (stars) {
      null => MascotMood.thinking,
      1 || 2 => MascotMood.sad,
      3 => MascotMood.idle,
      4 => MascotMood.presenting,
      _ => MascotMood.celebrating,
    };

/// O cloche pensativo em pé na quina da folha, com um balão perguntando. O
/// corpo desce uns pixels sobre a folha pra parecer apoiado nela.
class _AskingCloche extends StatelessWidget {
  const _AskingCloche({required this.rating});

  final ValueListenable<int?> rating;

  static const _standOnSheet = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.7 + 0.3 * v,
          alignment: Alignment.bottomLeft,
          child: child,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.screen),
          child: Transform.translate(
            offset: const Offset(0, _standOnSheet),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ValueListenableBuilder<int?>(
                  valueListenable: rating,
                  builder: (_, stars, __) => AnimatedMascot(
                    kind: MascotKind.cloche,
                    width: 104,
                    mood: _moodFor(stars),
                    tappable: false,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: _standOnSheet + AppSpacing.xl,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -5,
                        bottom: 14,
                        child: Transform.rotate(
                          angle: 0.785398,
                          child: Container(
                            width: 12,
                            height: 12,
                            color: colors.paper,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: colors.paper,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: ValueListenableBuilder<int?>(
                          valueListenable: rating,
                          builder: (_, stars, __) => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, anim) => ScaleTransition(
                              scale: anim,
                              alignment: Alignment.bottomLeft,
                              child:
                                  FadeTransition(opacity: anim, child: child),
                            ),
                            child: Text(
                              clocheReply(stars),
                              key: ValueKey(stars),
                              style: AppTextStyles.display(22)
                                  .copyWith(color: colors.onPaper),
                            ),
                          ),
                        ),
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
