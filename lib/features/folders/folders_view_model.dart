import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/domain/models/recipe.dart';

/// Pastas de raiz com contagem — a seção "Pastas" da home mostra elas.
final rootFoldersProvider = StreamProvider<List<FolderWithCounts>>(
  (ref) => ref.watch(folderRepositoryProvider).watchChildrenWithCounts(null),
);

/// As 7 pastas de raiz mais recentes (criação ou abertura) — a faixa da
/// home. `rootFoldersProvider` continua servindo a tela "ver todas".
final recentFoldersProvider = StreamProvider<List<FolderWithCounts>>(
  (ref) =>
      ref.watch(folderRepositoryProvider).watchRecentRootWithCounts(limit: 7),
);

/// A pasta em si (nome, pai) — cabeçalho da tela da pasta.
final folderProvider = StreamProvider.family<Folder?, String>(
  (ref, id) => ref.watch(folderRepositoryProvider).watchFolder(id),
);

/// Subpastas de uma pasta, com contagem.
final subfoldersProvider =
    StreamProvider.family<List<FolderWithCounts>, String>(
  (ref, id) => ref.watch(folderRepositoryProvider).watchChildrenWithCounts(id),
);

/// Receitas diretamente dentro de uma pasta.
final folderRecipesProvider = StreamProvider.family<List<Recipe>, String>(
  (ref, id) => ref.watch(recipeRepositoryProvider).watchInFolder(id),
);

/// Toda a árvore de pastas, achatada — alimenta o seletor "Mover para pasta".
final allFoldersProvider = StreamProvider<List<Folder>>(
  (ref) => ref.watch(folderRepositoryProvider).watchAll(),
);
