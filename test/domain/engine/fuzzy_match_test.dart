import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/fuzzy_match.dart';

void main() {
  test('idêntico tem similaridade 1', () {
    expect(normalizedSimilarity('tomate', 'tomate'), 1);
  });

  test('um erro de digitação fica acima de 0.85', () {
    expect(normalizedSimilarity('tomate', 'tomat'), greaterThanOrEqualTo(0.85));
    expect(
        normalizedSimilarity('cebola', 'cebola'), greaterThanOrEqualTo(0.85));
  });

  test('palavras bem diferentes ficam abaixo de 0.85', () {
    expect(normalizedSimilarity('tomate', 'batata'), lessThan(0.85));
  });

  test('vazio vs vazio é idêntico', () {
    expect(normalizedSimilarity('', ''), 1);
  });
}
