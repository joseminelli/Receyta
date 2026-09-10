/// Forma canônica do nome de uma tag (§RF-01.10): pontas aparadas, espaço
/// interno colapsado, primeira letra de cada palavra em maiúscula. Conectores
/// curtos em pt-BR ficam minúsculos, menos quando abrem o nome ("Bolo de
/// Fubá", "Da Vó"). É a chave usada para reaproveitar a linha em `tags`.
const _connectors = {
  'de', 'da', 'do', 'das', 'dos', 'e', 'com', 'sem',
  'a', 'o', 'à', 'ao', 'aos', 'na', 'no', 'para', 'por',
};

String canonicalTagName(String raw) {
  final words = raw.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
  return [
    for (var i = 0; i < words.length; i++)
      if (words[i].isEmpty)
        words[i]
      else if (i > 0 && _connectors.contains(words[i].toLowerCase()))
        words[i].toLowerCase()
      else
        words[i][0].toUpperCase() + words[i].substring(1).toLowerCase(),
  ].join(' ');
}
