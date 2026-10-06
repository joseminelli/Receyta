import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/fuzzy_match.dart';

void main() {
  test('idêntico tem similaridade 1', () {
    expect(normalizedSimilarity('tomate', 'tomate'), 1);
  });

  test('palavra idêntica fica acima de 0.85', () {
    expect(
        normalizedSimilarity('cebola', 'cebola'), greaterThanOrEqualTo(0.85));
  });

  test(
      'uma letra de diferença numa palavra curta dá menos de 0.85, mas '
      'isCloseMatch aceita (é a regra de 1 edição)', () {
    expect(normalizedSimilarity('tomate', 'tomat'), lessThan(0.85));
    expect(isCloseMatch('tomate', 'tomat'), isTrue);
  });

  test('palavras bem diferentes ficam abaixo de 0.85', () {
    expect(normalizedSimilarity('tomate', 'batata'), lessThan(0.85));
  });

  test('vazio vs vazio é idêntico', () {
    expect(normalizedSimilarity('', ''), 1);
  });
}
