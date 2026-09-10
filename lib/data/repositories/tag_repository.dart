import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/database/daos/tag_dao.dart';
import 'package:receyta/domain/models/tag.dart';

/// Leitura do catálogo de tags (§RF-01.10). A escrita mora na
/// [RecipeRepository], junto do resto do agregado receita.
class TagRepository {
  TagRepository(this._dao);

  final TagDao _dao;

  /// Todas as tags — o autocomplete do formulário sugere a partir daqui.
  Stream<List<Tag>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toDomain).toList());

  /// Só as tags que estão em alguma receita ativa — é o que o filtro da home
  /// oferece.
  Stream<List<Tag>> watchInUse() =>
      _dao.watchInUse().map((rows) => rows.map(_toDomain).toList());

  Tag _toDomain(TagRow r) => Tag(id: r.id, name: r.name);
}

final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => TagRepository(ref.watch(databaseProvider).tagDao),
);
