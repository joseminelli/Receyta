import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/step_duration.dart';

List<Duration> _found(String text) =>
    [for (final d in findStepDurations(text)) d.duration];

void main() {
  group('findStepDurations', () {
    test('minutos, por extenso e abreviado', () {
      expect(_found('Cozinhe por 20 minutos.'), [const Duration(minutes: 20)]);
      expect(_found('Asse 45 min em forno médio'), [const Duration(minutes: 45)]);
      expect(_found('Deixe descansar 1 minuto'), [const Duration(minutes: 1)]);
    });

    test('horas, com minutos, "e meia" e a forma colada 1h30', () {
      expect(_found('Leve ao forno por 2 horas'), [const Duration(hours: 2)]);
      expect(_found('Deixe 1 hora e meia na geladeira'),
          [const Duration(hours: 1, minutes: 30)]);
      expect(_found('Cozinhe 1 hora e 15 minutos'),
          [const Duration(hours: 1, minutes: 15)]);
      expect(_found('Asse por 1h30'), [const Duration(hours: 1, minutes: 30)]);
      expect(_found('Descanse 1h'), [const Duration(hours: 1)]);
    });

    test('meia hora e segundos', () {
      expect(_found('Espere meia hora'), [const Duration(minutes: 30)]);
      expect(_found('Doure 30 segundos de cada lado'),
          [const Duration(seconds: 30)]);
    });

    test('faixa ("20 a 25 minutos") usa o menor: o lembrete é pra ir olhar', () {
      expect(_found('Asse de 20 a 25 minutos'), [const Duration(minutes: 20)]);
      expect(_found('Cozinhe 20-25 min'), [const Duration(minutes: 20)]);
    });

    test('mais de um tempo no mesmo passo, na ordem do texto', () {
      expect(
        _found('Frite 3 minutos de cada lado e depois asse 20 minutos'),
        [const Duration(minutes: 3), const Duration(minutes: 20)],
      );
    });

    test('não confunde "1h30" com duas durações nem conta o pedaço duas vezes',
        () {
      expect(findStepDurations('Asse por 1 hora e 30 minutos'), hasLength(1));
      expect(findStepDurations('Asse por 1h30'), hasLength(1));
    });

    test('maiúsculas, acento e vírgula decimal', () {
      expect(_found('COZINHE 10 MINUTOS'), [const Duration(minutes: 10)]);
      expect(_found('Cozinhe 1,5 hora'), [const Duration(minutes: 90)]);
    });

    test('sem tempo, vazio, zero e absurdo não viram timer', () {
      expect(_found('Misture bem os ingredientes'), isEmpty);
      expect(_found(''), isEmpty);
      expect(_found('Espere 0 minutos'), isEmpty);
      expect(_found('Deixe 500 horas'), isEmpty);
      expect(_found('Prato para 4 pessoas, 2 colheres'), isEmpty);
    });

    test('o rótulo mostra o tempo de forma curta', () {
      String label(String t) => findStepDurations(t).single.label;
      expect(label('20 minutos'), '20 min');
      expect(label('1 hora e meia'), '1 h 30 min');
      expect(label('2 horas'), '2 h');
      expect(label('30 segundos'), '30 s');
      expect(label('1h15'), '1 h 15 min');
    });
  });

  group('formatTimer', () {
    test('mm:ss e h:mm:ss', () {
      expect(formatTimer(const Duration(minutes: 5, seconds: 7)), '05:07');
      expect(formatTimer(const Duration(seconds: 59)), '00:59');
      expect(formatTimer(const Duration(hours: 1, minutes: 2, seconds: 3)),
          '1:02:03');
      expect(formatTimer(Duration.zero), '00:00');
    });

    test('negativo vira zero', () {
      expect(formatTimer(const Duration(seconds: -4)), '00:00');
    });
  });
}
