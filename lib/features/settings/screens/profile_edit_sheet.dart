import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/tile_appearance.dart';

/// Edita o perfil local: como a pessoa quer ser chamada e a cor do avatar.
Future<void> showProfileEditSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _ProfileEditSheet(),
  );
}

class _ProfileEditSheet extends ConsumerStatefulWidget {
  const _ProfileEditSheet();

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  late final TextEditingController _name;
  late TileColor _color;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _name = TextEditingController(text: settings.nickname);
    _color = settings.profileColor;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Widget _dot(TileColor c) => _ColorDot(
        color: c,
        selected: c == _color,
        onTap: () => setState(() => _color = c),
      );

  Future<void> _save() async {
    await ref
        .read(appSettingsProvider.notifier)
        .setProfile(nickname: _name.text, color: _color);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      child: Padding(
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
            Text('Seu perfil', style: context.texts.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _name,
              maxLength: 24,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Como quer ser chamado?',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Cor do avatar', style: context.texts.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in kBaseTileColors) _dot(c),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Mais cores', style: context.texts.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in kExtraTileColors) _dot(c),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar',
                      style: TextStyle(color: colors.textMuted)),
                ),
                const SizedBox(width: AppSpacing.xs),
                PillButton(label: 'Salvar', onPressed: _save),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final TileColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = resolveTileAppearance(colors, color: color);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Cor ${color.name}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: tile.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.ink : Colors.transparent,
              width: 3,
            ),
          ),
          child:
              selected ? Icon(Icons.check_rounded, color: tile.onColor) : null,
        ),
      ),
    );
  }
}
