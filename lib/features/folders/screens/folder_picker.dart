import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/features/folders/screens/folder_actions.dart';
import 'package:receyta/features/folders/controllers/folders_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Uma escolha do seletor de pasta. `id` nulo = raiz (sem pasta). O `Future`
/// externo é nulo quando o usuário fecha sem escolher.
typedef FolderChoice = ({String? id});

/// Abre o seletor "Mover para pasta": a árvore achatada e indentada por nível,
/// "Raiz" no topo, e um atalho pra criar pasta nova. [excludeSubtreeOf] tira da
/// lista uma pasta e as descendentes dela — usado ao mover a própria pasta.
Future<FolderChoice?> pickFolder(
  BuildContext context,
  WidgetRef ref, {
  String? currentId,
  String? excludeSubtreeOf,
}) {
  return showModalBottomSheet<FolderChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => _FolderPickerSheet(
      currentId: currentId,
      excludeSubtreeOf: excludeSubtreeOf,
    ),
  );
}

class _FolderPickerSheet extends ConsumerWidget {
  const _FolderPickerSheet({this.currentId, this.excludeSubtreeOf});

  final String? currentId;
  final String? excludeSubtreeOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders =
        ref.watch(allFoldersProvider).valueOrNull ?? const <Folder>[];
    final rows = _flatten(folders, excludeSubtreeOf);

    return AppSheetFrame(
      title: 'Mover para',
      subtitle: rows.isEmpty
          ? 'Você ainda não tem pastas. Crie a primeira.'
          : 'Escolha a pasta de destino',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(child: _buildList(context, rows)),
            const SizedBox(height: AppSpacing.sm),
            PillButton(
              label: 'Nova pasta',
              icon: Icons.create_new_folder_outlined,
              variant: PillButtonVariant.secondary,
              onPressed: () => _createFolder(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<_FlatFolder> rows) {
    final colors = context.colors;
    final entries = <Widget>[
      _Row(
        label: 'Raiz',
        hint: 'Sem pasta',
        icon: Icons.home_outlined,
        depth: 0,
        selected: currentId == null,
        onTap: () => Navigator.of(context).pop<FolderChoice>((id: null)),
      ),
      for (final r in rows)
        _Row(
          label: r.folder.name,
          icon: Icons.folder_outlined,
          depth: r.depth,
          selected: currentId == r.folder.id,
          onTap: () =>
              Navigator.of(context).pop<FolderChoice>((id: r.folder.id)),
        ),
    ];
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, thickness: 1.5, color: colors.paperSoft),
      itemBuilder: (_, i) => entries[i],
    );
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final name = await promptFolderName(
      context,
      title: 'Nova pasta',
      action: 'Criar',
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    final result = await ref.read(folderRepositoryProvider).create(name: name);
    if (!context.mounted) return;
    result.when(
      ok: (folder) => Navigator.of(context).pop<FolderChoice>((id: folder.id)),
      err: (_) {},
    );
  }
}

typedef _FlatFolder = ({Folder folder, int depth});

/// Achata a árvore em ordem de leitura (pai antes dos filhos), com a
/// profundidade de cada pasta. Pula a subárvore de [excludeId].
List<_FlatFolder> _flatten(List<Folder> all, String? excludeId) {
  final byParent = <String?, List<Folder>>{};
  for (final f in all) {
    byParent.putIfAbsent(f.parentId, () => []).add(f);
  }
  for (final list in byParent.values) {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  final out = <_FlatFolder>[];
  void walk(String? parentId, int depth) {
    for (final f in byParent[parentId] ?? const <Folder>[]) {
      if (f.id == excludeId) continue;
      out.add((folder: f, depth: depth));
      walk(f.id, depth + 1);
    }
  }

  walk(null, 0);
  return out;
}

/// Uma pasta do seletor: medalhão `ink` com o ícone em `lime` (o mesmo par das
/// outras folhas), recuo e uma seta de subpasta conforme o nível, e um check
/// em quem já é o destino atual.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.icon,
    required this.depth,
    required this.selected,
    required this.onTap,
    this.hint,
  });

  final String label;
  final String? hint;
  final IconData icon;
  final int depth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = selected ? 'Aqui agora' : hint;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: EdgeInsets.only(left: depth * AppSpacing.md),
            child: Row(
              children: [
                if (depth > 0) ...[
                  Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    size: 18,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.ink,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: colors.lime, width: 2)
                        : null,
                  ),
                  child: Icon(icon, size: 21, color: colors.lime),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.display(21),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: context.texts.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, color: colors.ink)
                else
                  Icon(Icons.arrow_forward_rounded, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
