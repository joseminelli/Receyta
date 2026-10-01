import 'package:flutter_test/flutter_test.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/models/cooking_timer.dart';
import 'package:receyta/widgets/timer_card_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desenha o card como PNG não vazio', (tester) async {
    final png = await tester.runAsync(
      () => renderTimerCardPng(
        recipeId: 'r1',
        name: 'Pasta de grão de bico (homus) com um nome bem comprido',
        label: 'Passo 2',
      ),
    );

    expect(png, isNotNull);
    expect(png!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(png.length, greaterThan(1000));
  });

  test('o estilo do azulejo sobrevive ao json e ao copyWith', () {
    final timer = CookingTimer(
      id: 1,
      recipeId: 'r1',
      label: 'Passo 1',
      total: const Duration(minutes: 5),
      remaining: const Duration(minutes: 5),
      phase: TimerPhase.paused,
      tileColor: TileColor.values.first,
      tileMotif: TileMotif.values.first,
    );

    final back = CookingTimer.fromJson(timer.toJson())!;
    expect(back.tileColor, TileColor.values.first);
    expect(back.tileMotif, TileMotif.values.first);
    expect(back.copyWith(remaining: Duration.zero).tileMotif,
        TileMotif.values.first);
  });
}
