import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Dica única de que as linhas da lista respondem a deslizar. Aparece até o
/// usuário dispensá-la; a escolha fica guardada por [hintId].
class SwipeHint extends StatefulWidget {
  const SwipeHint({super.key, required this.hintId, required this.message});

  final String hintId;
  final String message;

  @override
  State<SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<SwipeHint> {
  bool _visible = false;

  String get _key => 'swipe_hint_seen_${widget.hintId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_key) ?? false;
      if (mounted && !seen) setState(() => _visible = true);
    } catch (_) {}
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !_visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  top: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.paperSoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.swipe, size: 20, color: colors.onPaper),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: context.texts.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _dismiss,
                      icon: const Icon(Icons.close, size: 18),
                      color: colors.textMuted,
                      tooltip: 'Entendi',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
