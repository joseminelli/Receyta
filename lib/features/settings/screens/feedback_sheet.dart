import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/services/app_info.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Folha de feedback: a pessoa escolhe o tipo, escreve o que quiser e envia.
/// Só o texto escrito vai (mais a versão do app) — nada é coletado sozinho.
Future<void> showFeedbackSheet(BuildContext context, {String version = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _FeedbackSheet(version: version),
  );
}

const _categories = ['Sugestão', 'Problema', 'Elogio'];

class _FeedbackSheet extends ConsumerStatefulWidget {
  const _FeedbackSheet({required this.version});

  final String version;

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  final _message = TextEditingController();
  String _category = _categories.first;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool get _canSend => _message.text.trim().isNotEmpty && !_sending;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref.read(feedbackServiceProvider).send(
            message: _message.text,
            category: _category,
            version: widget.version,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enviar feedback', style: context.texts.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Conte o que gostou, o que pode melhorar ou o que deu errado.',
            style: context.texts.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final c in _categories)
                ChoiceChip(
                  label: Text(c),
                  selected: c == _category,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _message,
            minLines: 4,
            maxLines: 8,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Escreva aqui…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: PillButton(
              label: 'Enviar',
              icon: Icons.send_rounded,
              loading: _sending,
              onPressed: _canSend ? _send : null,
            ),
          ),
        ],
      ),
    );
  }
}
