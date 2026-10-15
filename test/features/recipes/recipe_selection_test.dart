import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/features/recipes/controllers/recipe_selection.dart';

void main() {
  late ProviderContainer container;
  RecipeSelectionNotifier notifier() =>
      container.read(recipeSelectionProvider.notifier);
  Set<String>? state() => container.read(recipeSelectionProvider);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('começa fora do modo e toggle não faz nada fora dele', () {
    expect(state(), isNull);
    notifier().toggle('a');
    expect(state(), isNull);
  });

  test('start entra no modo vazio; toggle marca e desmarca', () {
    notifier().start();
    expect(state(), isEmpty);

    notifier().toggle('a');
    notifier().toggle('b');
    expect(state(), {'a', 'b'});

    notifier().toggle('a');
    expect(state(), {'b'});
  });

  test('selectAll troca a seleção sem sair do modo; clear sai', () {
    notifier().start();
    notifier().toggle('a');
    notifier().selectAll(const {});
    expect(state(), isEmpty);

    notifier().clear();
    expect(state(), isNull);
  });
}
