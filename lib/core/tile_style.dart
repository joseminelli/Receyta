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

/// As quatro cores de bloco da §9.2. Emparelham com um [TileMotif] por padrão
/// (coral/arco, violet/meiaLua, ink/diagonal, lime/ponto), mas o usuário pode
/// combinar como quiser.
enum TileColor { coral, violet, ink, lime }

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
