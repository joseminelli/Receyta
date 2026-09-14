/// Similaridade de texto pro fuzzy match do C4 (§8.2 passo 3). Levenshtein
/// normalizado: 1 = idêntico, 0 = nada em comum.
library;

int levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List<int>.generate(b.length + 1, (j) => j);
  var current = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = [
        current[j - 1] + 1,
        previous[j] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[b.length];
}

/// "Parecido o bastante" (§8.2 passo 3): bate o limiar normalizado OU é só
/// 1 letra trocada/faltando/sobrando numa palavra que não é curta demais
/// pra arriscar (< 4 letras, tipo "sal"/"sol", fica de fora — aí 1 edição já
/// é a palavra inteira). O normalizado sozinho penaliza demais 1 edição
/// única em palavra curta: "tomate" vs "tomatr" dá 0.83, abaixo de 0.85,
/// mesmo sendo só 1 letra.
bool isCloseMatch(String a, String b, {double threshold = 0.85}) {
  if (normalizedSimilarity(a, b) >= threshold) return true;
  final shorter = a.length < b.length ? a.length : b.length;
  return shorter >= 4 && levenshteinDistance(a, b) <= 1;
}

/// 1 = idêntico, 0 = nada em comum. Compare formas já normalizadas
/// (`normalize()` do C2) — é aí que o C4 se pluga.
double normalizedSimilarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1;
  final maxLen = a.length > b.length ? a.length : b.length;
  if (maxLen == 0) return 1;
  return 1 - (levenshteinDistance(a, b) / maxLen);
}
