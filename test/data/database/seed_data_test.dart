import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/seed_data.dart';

/// Validações puras das listas de seed — não abrem banco.
void main() {
  test('códigos de unidade são únicos e não vazios', () {
    final codes = kSeedUnits.map((u) => u.code).toList();
    expect(codes.toSet().length, codes.length);
    expect(codes.every((c) => c.trim().isNotEmpty), isTrue);
  });

  test('kind de toda unidade é válido', () {
    for (final u in kSeedUnits) {
      expect(kUnitKinds, contains(u.kind), reason: u.code);
    }
  });

  test('unidade com base tem fator, e sem base não tem', () {
    for (final u in kSeedUnits) {
      expect(
        u.baseUnitCode == null,
        u.factorToBase == null,
        reason: '${u.code}: base e fator devem aparecer juntos',
      );
    }
  });

  test('base de conversão aponta para um code existente', () {
    final codes = kSeedUnits.map((u) => u.code).toSet();
    for (final u in kSeedUnits) {
      if (u.baseUnitCode != null) {
        expect(codes, contains(u.baseUnitCode), reason: u.code);
      }
    }
  });

  test('slugs de categoria são únicos e não vazios', () {
    final slugs = kSeedCategories.map((c) => c.slug).toList();
    expect(slugs.toSet().length, slugs.length);
    expect(slugs.every((s) => s.trim().isNotEmpty), isTrue);
    expect(kSeedCategories.every((c) => c.name.trim().isNotEmpty), isTrue);
  });

  test('termos do normalizador: únicos, não vazios, kind válido', () {
    final terms = kSeedNormalizerTerms.map((t) => t.term).toList();
    expect(terms.toSet().length, terms.length, reason: 'termo duplicado');
    for (final t in kSeedNormalizerTerms) {
      expect(t.term.trim(), isNotEmpty);
      expect(kNormalizerKinds, contains(t.kind));
    }
  });

  test('cobre o mínimo do §6: ~30 unidades, stopwords e qualificadores', () {
    expect(kSeedUnits.length, greaterThanOrEqualTo(30));
    expect(
      kSeedNormalizerTerms.where((t) => t.kind == 'stopword'),
      isNotEmpty,
    );
    expect(
      kSeedNormalizerTerms.where((t) => t.kind == 'qualifier'),
      isNotEmpty,
    );
  });
}
