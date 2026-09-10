import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/features/folders/folder_actions.dart';
import 'package:receyta/features/folders/folders_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

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
    final colors = context.colors;
    final folders = ref.watch(allFoldersProvider).valueOrNull ?? const <Folder>[];
    final rows = _flatten(folders, excludeSubtreeOf);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                AppSpacing.sm,
              ),
              child: Text('Mover para', style: context.texts.displaySmall),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _Row(
                    label: 'Raiz',
                    icon: Icons.home_outlined,
                    depth: 0,
                    selected: currentId == null,
                    onTap: () =>
                        Navigator.of(context).pop<FolderChoice>((id: null)),
                  ),
                  for (final r in rows)
                    _Row(
                      label: r.folder.name,
                      icon: Icons.folder_outlined,
                      depth: r.depth,
                      selected: currentId == r.folder.id,
                      onTap: () => Navigator.of(context)
                          .pop<FolderChoice>((id: r.folder.id)),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.paperSoft),
            ListTile(
              leading: Icon(Icons.add, color: colors.violet),
              title: Text(
                'Nova pasta',
                style: context.texts.bodyLarge?.copyWith(color: colors.violet),
              ),
              onTap: () async {
                final name = await promptFolderName(
                  context,
                  title: 'Nova pasta',
                  action: 'Criar',
                );
                if (name == null || name.isEmpty) return;
                final result =
                    await ref.read(folderRepositoryProvider).create(name: name);
                result.when(
                  ok: (folder) => Navigator.of(context)
                      .pop<FolderChoice>((id: folder.id)),
                  err: (_) {},
                );
              },
            ),
          ],
        ),
      ),
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

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.icon,
    required this.depth,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int depth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.only(
        left: AppSpacing.screen + depth * AppSpacing.lg,
        right: AppSpacing.screen,
      ),
      leading: Icon(icon, color: selected ? colors.violet : colors.textMuted),
      title: Text(
        label,
        style: context.texts.bodyLarge?.copyWith(
          color: selected ? colors.violet : colors.textBody,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: selected ? Icon(Icons.check, color: colors.violet) : null,
      onTap: onTap,
    );
  }
}
