import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/sync_status_text.dart';

void main() {
  final now = DateTime.utc(2026, 3, 10, 12);

  String ago(Duration d) => formatSyncAgo(now.subtract(d), now);

  test('menos de um minuto', () {
    expect(ago(Duration.zero), 'agora há pouco');
    expect(ago(const Duration(seconds: 59)), 'agora há pouco');
  });

  test('minutos', () {
    expect(ago(const Duration(minutes: 1)), 'há 1 min');
    expect(ago(const Duration(minutes: 59)), 'há 59 min');
  });

  test('horas', () {
    expect(ago(const Duration(minutes: 60)), 'há 1 h');
    expect(ago(const Duration(hours: 23, minutes: 59)), 'há 23 h');
  });

  test('ontem e dias', () {
    expect(ago(const Duration(hours: 24)), 'ontem');
    expect(ago(const Duration(hours: 47)), 'ontem');
    expect(ago(const Duration(days: 2)), 'há 2 dias');
    expect(ago(const Duration(days: 6)), 'há 6 dias');
  });

  test('uma semana ou mais vira a data', () {
    final text = ago(const Duration(days: 9));

    expect(text, startsWith('em '));
    expect(text, matches(RegExp(r'^em \d{2}/\d{2}/\d{4}$')));
  });

  test('relógio que voltou (hora no futuro) não quebra', () {
    expect(formatSyncAgo(now.add(const Duration(minutes: 5)), now),
        'agora há pouco');
  });
}
