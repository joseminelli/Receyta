/// Forma canônica de um nome curto em pt-BR: pontas aparadas, espaço
/// interno colapsado, primeira letra de cada palavra em maiúscula. Conectores
/// curtos ficam minúsculos, menos quando abrem o nome ("Bolo de Fubá", "Da
/// Vó"). Usado pra tag (§RF-01.10, via [canonicalTagName]).
const _connectors = {
  'de', 'da', 'do', 'das', 'dos', 'e', 'com', 'sem',
  'a', 'o', 'à', 'ao', 'aos', 'na', 'no', 'para', 'por',
};

String canonicalTitleCase(String raw) {
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

/// Nome histórico deste mesmo transform, mantido pros call sites de tag
/// (§RF-01.10) — é a chave usada para reaproveitar a linha em `tags`.
String canonicalTagName(String raw) => canonicalTitleCase(raw);

/// Corrige nome vindo de fonte "suja" (arquivo `.receyta` mal formatado,
/// OCR, site) que saiu TUDO MAIÚSCULO — aplica [canonicalTitleCase]. Nome
/// que já tem alguma letra minúscula fica intocado: diferente da tag (texto
/// curto, sempre digitado pelo usuário), nome de receita importado pode ter
/// parênteses/sigla no meio ("Cookie (Sem Açúcar)") onde recalcular
/// maiúscula por posição de palavra estragaria o que já tava certo — só
/// vale a pena arriscar quando o texto de origem não distingue caixa
/// nenhuma pra começo de conversa.
String fixShoutyCase(String raw) {
  final isShouting = raw.isNotEmpty &&
      raw == raw.toUpperCase() &&
      raw != raw.toLowerCase();
  return isShouting ? canonicalTitleCase(raw) : raw;
}
