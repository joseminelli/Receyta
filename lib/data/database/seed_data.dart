/// Dados de seed do schema v1 (§6 "Seed inicial").
///
/// Dart puro — sem `package:drift`. [AppDatabase] transforma estas listas em
/// linhas no `onCreate` (e revalida com `insertOrIgnore`, então é idempotente).
///
/// Nenhum ingrediente é semeado (§6). Só unidades, categorias de corredor e o
/// vocabulário do normalizador.
library;

/// Uma unidade de medida pt-BR. `code` é o slug estável usado como `id`.
class SeedUnit {
  const SeedUnit(
    this.code,
    this.displayName,
    this.plural,
    this.kind, {
    this.baseUnitCode,
    this.factorToBase,
  });

  final String code;
  final String displayName;
  final String plural;

  /// `mass` | `volume` | `count` | `subjective`.
  final String kind;

  /// `code` da unidade-base da família, ou `null` para as próprias bases.
  final String? baseUnitCode;
  final double? factorToBase;
}

/// Kinds válidos de [SeedUnit.kind] — espelhado nos testes.
const kUnitKinds = {'mass', 'volume', 'count', 'subjective'};

/// ~32 unidades. As bases (`g`, `ml`) têm `baseUnitCode`/`factorToBase` nulos;
/// as derivadas convertem para elas. `count` e `subjective` não convertem.
const List<SeedUnit> kSeedUnits = [
  // Massa — base: g
  SeedUnit('g', 'g', 'g', 'mass'),
  SeedUnit('kg', 'kg', 'kg', 'mass', baseUnitCode: 'g', factorToBase: 1000),
  SeedUnit('mg', 'mg', 'mg', 'mass', baseUnitCode: 'g', factorToBase: 0.001),

  // Volume — base: ml
  SeedUnit('ml', 'ml', 'ml', 'volume'),
  SeedUnit('l', 'l', 'l', 'volume', baseUnitCode: 'ml', factorToBase: 1000),
  SeedUnit('xicara', 'xícara', 'xícaras', 'volume',
      baseUnitCode: 'ml', factorToBase: 240),
  SeedUnit('colher_sopa', 'colher de sopa', 'colheres de sopa', 'volume',
      baseUnitCode: 'ml', factorToBase: 15),
  SeedUnit('colher_cha', 'colher de chá', 'colheres de chá', 'volume',
      baseUnitCode: 'ml', factorToBase: 5),
  SeedUnit('colher_cafe', 'colher de café', 'colheres de café', 'volume',
      baseUnitCode: 'ml', factorToBase: 2),
  SeedUnit('copo', 'copo', 'copos', 'volume',
      baseUnitCode: 'ml', factorToBase: 200),

  // Contagem — sem conversão
  SeedUnit('unidade', 'unidade', 'unidades', 'count'),
  SeedUnit('dente', 'dente', 'dentes', 'count'),
  SeedUnit('fatia', 'fatia', 'fatias', 'count'),
  SeedUnit('ramo', 'ramo', 'ramos', 'count'),
  SeedUnit('maco', 'maço', 'maços', 'count'),
  SeedUnit('lata', 'lata', 'latas', 'count'),
  SeedUnit('pacote', 'pacote', 'pacotes', 'count'),
  SeedUnit('caixa', 'caixa', 'caixas', 'count'),
  SeedUnit('vidro', 'vidro', 'vidros', 'count'),
  SeedUnit('pote', 'pote', 'potes', 'count'),
  SeedUnit('folha', 'folha', 'folhas', 'count'),
  SeedUnit('talo', 'talo', 'talos', 'count'),
  SeedUnit('cabeca', 'cabeça', 'cabeças', 'count'),
  SeedUnit('gota', 'gota', 'gotas', 'count'),
  SeedUnit('rodela', 'rodela', 'rodelas', 'count'),
  SeedUnit('posta', 'posta', 'postas', 'count'),
  SeedUnit('file', 'filé', 'filés', 'count'),
  SeedUnit('espiga', 'espiga', 'espigas', 'count'),

  // Subjetivas — sem quantidade real
  SeedUnit('a_gosto', 'a gosto', 'a gosto', 'subjective'),
  SeedUnit('quanto_baste', 'quanto baste', 'quanto baste', 'subjective'),
  SeedUnit('pitada', 'pitada', 'pitadas', 'subjective'),
  SeedUnit('punhado', 'punhado', 'punhados', 'subjective'),
];

/// Uma categoria de corredor. `slug` é o sufixo do `id` (`cat_<slug>`).
class SeedCategory {
  const SeedCategory(this.slug, this.name);
  final String slug;
  final String name;
}

/// Corredores na ordem de percurso do mercado (§RF-05.7). A posição na lista
/// vira o `sort_order`.
const List<SeedCategory> kSeedCategories = [
  SeedCategory('hortifruti', 'Hortifrúti'),
  SeedCategory('acougue', 'Açougue'),
  SeedCategory('peixaria', 'Peixaria'),
  SeedCategory('frios_laticinios', 'Frios e laticínios'),
  SeedCategory('padaria', 'Padaria'),
  SeedCategory('mercearia', 'Mercearia'),
  SeedCategory('massas_molhos', 'Massas e molhos'),
  SeedCategory('enlatados_conservas', 'Enlatados e conservas'),
  SeedCategory('temperos_condimentos', 'Temperos e condimentos'),
  SeedCategory('matinais_cereais', 'Matinais e cereais'),
  SeedCategory('congelados', 'Congelados'),
  SeedCategory('bebidas', 'Bebidas'),
  SeedCategory('doces_sobremesas', 'Doces e sobremesas'),
  SeedCategory('higiene_limpeza', 'Higiene e limpeza'),
  SeedCategory('outros', 'Outros'),
];

/// Um termo do normalizador (§8.2).
class SeedNormalizerTerm {
  const SeedNormalizerTerm(this.term, this.kind);
  final String term;

  /// `stopword` | `qualifier`.
  final String kind;
}

/// Kinds válidos de [SeedNormalizerTerm.kind] — espelhado nos testes.
const kNormalizerKinds = {'stopword', 'qualifier'};

/// Conectivos e ruído estrutural: somem do nome canônico (§8.2).
const List<String> _stopwords = [
  'de', 'da', 'do', 'das', 'dos',
  'e', 'com', 'sem', 'para', 'por',
  'em', 'no', 'na', 'nos', 'nas',
  'ao', 'aos', 'à', 'às',
  'um', 'uma', 'uns', 'umas',
  'tipo', 'cerca', 'aproximadamente', 'bem', 'ou', 'mais', 'nível',
];

/// Estado/preparo: vira o campo `qualifier` de `recipe_ingredients` e sai do
/// nome. Precisa das formas flexionadas — o normalizador remove antes de
/// singularizar (§8.2).
const List<String> _qualifiers = [
  'picado', 'picada', 'picados', 'picadas', 'picadinho', 'picadinha',
  'ralado', 'ralada', 'ralados', 'raladas',
  'fatiado', 'fatiada', 'fatiados', 'fatiadas',
  'moído', 'moída', 'moídos', 'moídas',
  'amassado', 'amassada',
  'cozido', 'cozida', 'cozidos', 'cozidas',
  'cru', 'crua', 'crus', 'cruas',
  'fresco', 'fresca', 'frescos', 'frescas',
  'seco', 'seca', 'secos', 'secas',
  'grande', 'grandes',
  'médio', 'média', 'médios', 'médias',
  'pequeno', 'pequena', 'pequenos', 'pequenas',
  'grosso', 'grossa', 'grossos', 'grossas',
  'fino', 'fina', 'finos', 'finas',
  'maduro', 'madura', 'maduros', 'maduras',
  'quente', 'quentes',
  'frio', 'fria', 'frios', 'frias',
  'peneirado', 'peneirada',
  'derretido', 'derretida',
  'batido', 'batida',
  'escorrido', 'escorrida',
  'drenado', 'drenada',
  'temperado', 'temperada',
  'opcional', 'opcionais',
  'a gosto',
  'sem pele', 'sem osso',
  'em cubos', 'em cubinhos', 'em rodelas', 'em tiras', 'em pedaços', 'em fatias',
];

/// Vocabulário completo do normalizador, semeado na v1.
/// (`final`, não `const`: literais const não aceitam elementos `for`.)
final List<SeedNormalizerTerm> kSeedNormalizerTerms = [
  for (final t in _stopwords) SeedNormalizerTerm(t, 'stopword'),
  for (final t in _qualifiers) SeedNormalizerTerm(t, 'qualifier'),
];
