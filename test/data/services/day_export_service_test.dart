import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/day_export_service.dart';

void main() {
  test('nome do arquivo com a data', () {
    expect(
      DayExportService.fileName(DateTime(2026, 10, 2)),
      'receyta-dia-2026-10-02.png',
    );
    expect(
      DayExportService.fileName(DateTime(2026, 12, 25)),
      'receyta-dia-2026-12-25.png',
    );
  });

  test('legenda que acompanha a imagem', () {
    expect(
      DayExportService.caption(DateTime(2026, 10, 2)),
      'Meu dia no Receyta — 2 de outubro',
    );
  });

  test('dia sem refeições não compartilha nada', () async {
    final result = await DayExportService().shareDay(DateTime(2026, 10, 2), []);

    expect(result, isA<Err<void>>());
  });
}
