import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seleção múltipla da home: nulo = fora do modo; um conjunto (talvez vazio)
/// = no modo, com essas receitas marcadas.
class RecipeSelectionNotifier extends Notifier<Set<String>?> {
  @override
  Set<String>? build() => null;

  void start() => state = <String>{};

  void toggle(String id) {
    final current = state;
    if (current == null) return;
    final next = {...current};
    if (!next.remove(id)) next.add(id);
    state = next;
  }

  void selectAll(Iterable<String> ids) {
    if (state == null) return;
    state = {...ids};
  }

  void clear() => state = null;
}

final recipeSelectionProvider =
    NotifierProvider<RecipeSelectionNotifier, Set<String>?>(
  RecipeSelectionNotifier.new,
);
