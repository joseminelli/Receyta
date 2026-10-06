/// Cor e módulo do azulejo (§9.4) — o que o usuário personaliza numa receita ou
/// pasta. Puro Dart: o domínio guarda estes enums, a camada de UI resolve pra
/// cores concretas (`resolveTileAppearance`).
library;

/// Os quatro módulos do azulejo modernista (§9.4). A referência é Athos Bulcão:
/// geometria pura, sem floral e sem moldura. Re-exportado por
/// `widgets/tile_pattern.dart` — o código de UI pode importar de lá.
enum TileMotif {
  /// Quarto de círculo.
  arco,

  /// Meias-luas alternadas.
  meiaLua,

  /// Triângulos em dois tons.
  diagonal,

  /// Círculos em grade deslocada.
  ponto,
}

/// As cores de bloco. As quatro primeiras são as da §9.2 (a identidade do app)
/// e emparelham com um [TileMotif] por padrão (coral/arco, violet/meiaLua,
/// ink/diagonal, lime/ponto); as outras seis são **opcionais**, só pra
/// personalizar — nunca são escolhidas sozinhas. O usuário combina como
/// quiser. Guardadas pelo `.name`: não renomear nem reordenar os valores.
enum TileColor {
  coral,
  violet,
  ink,
  lime,
  mar,
  framboesa,
  mostarda,
  cobalto,
  floresta,
  terra,
}

/// As quatro cores do app (§9.2).
const kBaseTileColors = [
  TileColor.coral,
  TileColor.violet,
  TileColor.ink,
  TileColor.lime,
];

/// As cores opcionais, na ordem em que aparecem nos seletores.
const kExtraTileColors = [
  TileColor.mar,
  TileColor.framboesa,
  TileColor.mostarda,
  TileColor.cobalto,
  TileColor.floresta,
  TileColor.terra,
];

extension TileColorInfo on TileColor {
  bool get isExtra => kExtraTileColors.contains(this);

  /// Nome pra leitor de tela e legenda.
  String get label => switch (this) {
        TileColor.coral => 'Coral',
        TileColor.violet => 'Violeta',
        TileColor.ink => 'Preto',
        TileColor.lime => 'Lima',
        TileColor.mar => 'Mar',
        TileColor.framboesa => 'Framboesa',
        TileColor.mostarda => 'Mostarda',
        TileColor.cobalto => 'Cobalto',
        TileColor.floresta => 'Floresta',
        TileColor.terra => 'Terra',
      };
}

/// Parse tolerante — string do banco (`.name`) de volta pro enum, nulo se vazio
/// ou desconhecido (linha antiga, valor removido).
TileColor? tileColorFromName(String? name) {
  for (final c in TileColor.values) {
    if (c.name == name) return c;
  }
  return null;
}

TileMotif? tileMotifFromName(String? name) {
  for (final m in TileMotif.values) {
    if (m.name == name) return m;
  }
  return null;
}
