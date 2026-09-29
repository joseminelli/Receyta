import 'package:receyta/data/database/seed_data.dart';
import 'package:receyta/domain/engine/text_normalize.dart';

const _fallbackSlug = 'outros';

/// Palavras-chave por corredor (slug de `kSeedCategories`), na ordem em que
/// são testadas — a primeira que casar vence, então o mais específico vem
/// antes ("molho de tomate" cai em massas_molhos antes de "tomate" virar
/// hortifruti).
const _keywords = <(String, List<String>)>[
  (
    'massas_molhos',
    [
      'molho', 'extrato de tomate', 'macarrao', 'espaguete', 'penne',
      'lasanha', 'nhoque', 'talharim', 'massa de pizza',
    ],
  ),
  (
    'enlatados_conservas',
    [
      'milho verde', 'ervilha', 'atum', 'sardinha', 'palmito', 'azeitona',
      'conserva', 'seleta', 'lata',
    ],
  ),
  (
    'frios_laticinios',
    [
      'leite', 'queijo', 'manteiga', 'margarina', 'iogurte', 'requeijao',
      'creme de leite', 'nata', 'ovo', 'presunto', 'mussarela', 'muçarela',
      'parmesao', 'ricota', 'cream cheese', 'mortadela', 'peito de peru',
    ],
  ),
  (
    'acougue',
    [
      'carne', 'frango', 'peito de frango', 'coxa', 'sobrecoxa', 'bacon',
      'linguica', 'costela', 'file', 'patinho', 'acem', 'alcatra',
      'picanha', 'porco', 'lombo', 'salsicha', 'calabresa', 'bife',
    ],
  ),
  ('peixaria', ['peixe', 'camarao', 'salmao', 'tilapia', 'bacalhau', 'lula']),
  ('padaria', ['pao', 'baguete', 'torrada', 'bisnaga']),
  (
    'temperos_condimentos',
    [
      'sal', 'pimenta', 'oregano', 'colorau', 'canela', 'cominho', 'noz moscada',
      'louro', 'curry', 'paprica', 'tempero', 'vinagre', 'shoyu', 'mostarda',
      'ketchup', 'maionese', 'caldo', 'fermento', 'cravo',
    ],
  ),
  (
    'hortifruti',
    [
      'tomate', 'cebola', 'alho', 'batata', 'cenoura', 'abobora', 'abobrinha',
      'pimentao', 'alface', 'rucula', 'couve', 'brocolis', 'espinafre',
      'salsinha', 'cebolinha', 'coentro', 'manjericao', 'hortela', 'limao',
      'laranja', 'banana', 'maca', 'abacate', 'abacaxi', 'morango', 'mandioca',
      'aipim', 'beterraba', 'pepino', 'gengibre', 'milho', 'cogumelo',
      'champignon', 'berinjela', 'chuchu', 'repolho', 'uva', 'mamao',
      'manga', 'melancia', 'coco', 'alho poro', 'salsa', 'fruta', 'verdura',
    ],
  ),
  (
    'matinais_cereais',
    ['aveia', 'granola', 'cereal', 'cafe', 'achocolatado', 'cacau'],
  ),
  (
    'doces_sobremesas',
    [
      'chocolate', 'leite condensado', 'goiabada', 'doce de leite', 'confeito',
      'gelatina', 'granulado', 'sorvete',
    ],
  ),
  ('congelados', ['congelad']),
  ('bebidas', ['suco', 'refrigerante', 'cerveja', 'vinho', 'agua', 'cachaca']),
  (
    'mercearia',
    [
      'farinha', 'acucar', 'arroz', 'feijao', 'oleo', 'azeite', 'amido',
      'maisena', 'polvilho', 'fuba', 'lentilha', 'grao de bico', 'mel',
      'castanha', 'amendoa', 'nozes', 'passas', 'sagu', 'tapioca', 'biscoito',
      'bolacha', 'trigo', 'essencia', 'bicarbonato',
    ],
  ),
  ('higiene_limpeza', ['detergente', 'sabao', 'papel toalha', 'esponja']),
];

/// Corredor do mercado pro nome de um ingrediente — palavra-chave sobre o
/// nome sem acento e em minúsculas. Casa por palavra inteira (ou frase
/// inteira) pra "sal" não pegar "salsinha" nem "salmão". Sem correspondência
/// cai em `outros`.
String categorySlugFor(String ingredientName) {
  final text = ' ${stripAccents(ingredientName.toLowerCase()).trim()} ';
  for (final (slug, words) in _keywords) {
    for (final w in words) {
      final key = stripAccents(w);
      final isStem = key == 'congelad';
      if (isStem ? text.contains(' $key') : text.contains(' $key ')) {
        return slug;
      }
      if (!isStem && _pluralForm(text, key)) return slug;
    }
  }
  return _fallbackSlug;
}

bool _pluralForm(String text, String key) =>
    text.contains(' ${key}s ') || text.contains(' ${key}es ');

/// Ordem do corredor (índice em `kSeedCategories`) — usada pra ordenar as
/// seções da lista na sequência em que se anda pelo mercado.
int categoryOrder(String slug) {
  final i = kSeedCategories.indexWhere((c) => c.slug == slug);
  return i == -1 ? kSeedCategories.length : i;
}

String categoryLabel(String slug) {
  for (final c in kSeedCategories) {
    if (c.slug == slug) return c.name;
  }
  return 'Outros';
}

/// Converte o `categoryId` do catálogo (`cat_<slug>`) de volta pro slug.
String? categorySlugFromId(String? categoryId) {
  if (categoryId == null || !categoryId.startsWith('cat_')) return null;
  final slug = categoryId.substring(4);
  return kSeedCategories.any((c) => c.slug == slug) ? slug : null;
}
