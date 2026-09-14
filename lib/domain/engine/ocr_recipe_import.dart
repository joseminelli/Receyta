/// Divide o texto reconhecido numa foto de receita (C8, RF-06.10) em
/// nome/ingredientes/passos. Dart puro — sem Flutter, sem o plugin de OCR
/// em si (quem roda o reconhecimento é a camada de dados). Diferente do
/// JSON-LD do C7, aqui não tem marcação nenhuma — é heurística por palavra-
/// chave de seção ("Ingredientes", "Modo de preparo"...) sobre as linhas que
/// o OCR devolveu, na ordem em que apareceram na foto.
library;

import 'recipe_import.dart';

final _ingredientsHeading = RegExp(
  r'^ingredientes?$',
  caseSensitive: false,
);

final _stepsHeading = RegExp(
  r'^(modo de preparo|modo de fazer|preparo|instru(ç|c)(õ|o)es|como fazer|'
  r'm(é|e)todo|instructions|directions)$',
  caseSensitive: false,
);

/// Widget de "sugestões"/anúncio que sites de receita costumam pôr logo
/// depois da lista de ingredientes ("Faltou algo? Tenta essas", receitas
/// relacionadas, banner de propaganda). Não é passo nenhum — é onde a
/// lista de ingredientes para, mesmo sem achar "Modo de preparo" depois
/// (comum em print de tela que corta antes de chegar lá).
final _sectionStopMarker = RegExp(
  r'^(falt(ou|a) algo\??( tenta essas)?|tenta essas|'
  r'voc[eê] tamb[eé]m pode gostar|receitas relacionadas|mais receitas|'
  r'publicidade|an[uú]ncio|globoplay|assista( agora)?)$',
  caseSensitive: false,
);

final _numberedStepPrefix = RegExp(
  r'^(?:\d+\s*[.\)]|passo\s*\d+\s*[:.]?|step\s*\d+\s*[:.]?)\s*',
  caseSensitive: false,
);

/// Marcador de lista que o OCR costuma inserir no começo de cada linha
/// ("• 2 ovos", "- 1/2 xícara de leite"). Só remove no início da linha —
/// a barra da fração ("1/4") nunca é tocada.
final _leadingBullet = RegExp(r'^[•●○◦▪‣∙·*\-–—»>]+\s*');

/// "Bolo de nozes — Foto: Receitas" — legenda de foto de site, comum vir
/// grudada no nome de verdade. Tira só o pedaço da legenda.
final _photoCaptionSuffix = RegExp(r'\s*[—–-]\s*foto:.*$', caseSensitive: false);

String _cleanLine(String line) {
  var l = line.trim().replaceFirst(_leadingBullet, '').trim();
  l = l.replaceFirst(_photoCaptionSuffix, '').trim();
  return l;
}

/// Botão/rótulo de interface que aparece inteiro de rede social (print de
/// vídeo do TikTok/Instagram, não da receita em si).
final _socialUiButton = RegExp(
  r'^(seguir|seguindo|curtir|curtido|denunciar|compartilhar|comentar|'
  r'coment[aá]rios?|enviar|salvar|traduzir|ver tradu[cç][aã]o|ver mais|'
  r'toque para (pausar|reproduzir)|adicionar coment[aá]rio)$',
  caseSensitive: false,
);

/// "@fulano123" ou "#receitafacil" — nunca é ingrediente/passo.
final _handleOrHashtag = RegExp(r'^[@#]\S+$');

/// "1,2 mil curtidas", "340 comentários", "89k visualizações".
final _socialCount = RegExp(
  r'^\d[\d.,]*\s*(mil|mi|k)?\s*'
  r'(curtidas?|coment[aá]rios?|compartilhamentos?|visualiza[cç][oõ]es|'
  r'seguidores)$',
  caseSensitive: false,
);

/// Relógio da barra de status ("22:11", às vezes com um glyph de ícone
/// vizinho mal lido grudado, tipo "22:11 O").
final _clockLike = RegExp(r'^\d{1,2}:\d{2}(\s+\S{1,3})?$');

/// Bateria/sinal da barra de status ("59%", "I 59%").
final _batteryLike = RegExp(r'^\S{0,3}\s*\d{1,3}\s*%$');

/// "Você" sozinho na linha — é como o Instagram identifica o autor quando o
/// post é seu, aparece no lugar do nome de usuário. Nunca é nome de receita.
final _selfProfileName = RegExp(r'^voc[eê]$', caseSensitive: false);

/// "há 3 d", "há 2 horas" — quando o post foi publicado, não a receita.
final _relativeTime = RegExp(
  r'^h[áa]\s+\d+\s*'
  r'(s|seg(undos?)?|min(utos?)?|h|horas?|d|dias?|sem(anas?)?|'
  r'm[êe]s(es)?|anos?)$',
  caseSensitive: false,
);

/// Placeholder do campo de comentário ("Responder a você", "Responder").
final _replyPlaceholder = RegExp(r'^responder( a .+)?$', caseSensitive: false);

/// "Curtido por fulano e outras 859.063 pessoas" — pode vir quebrado em
/// duas linhas, com "pessoas" sozinho continuando.
final _likedBySentence = RegExp(r'^curtido por .+$', caseSensitive: false);
final _peopleContinuation = RegExp(r'^pessoas$', caseSensitive: false);

/// Contador de curtida/comentário/compartilhamento só com o número, sem
/// palavra nenhuma do lado (fica ao lado do ícone no Instagram/TikTok:
/// "859 mil", "3.854", "6.940"). Mais arriscado que [_socialCount] (que
/// exige a palavra), por isso só entra como número + opcional
/// "mil"/"mi"/"k" — nada mais na linha.
final _bareInteractionCount = RegExp(
  r'^\d[\d.,]*\s*(mil|mi|k)?$',
  caseSensitive: false,
);

/// Nome de usuário sem @ (o Instagram mostra só o texto no cabeçalho do
/// post) — um token só, sem espaço, com underscore ("mais_receitas_").
/// Ingrediente/passo real não tem esse formato.
final _usernameLikeToken = RegExp(r'^\S*_\S*$');

/// Ícone isolado que o OCR leu como um caractere solto sozinho na linha.
final _strayGlyph = RegExp(r'^[+*#~•●]$');

/// "•" no meio da linha (não só no começo, esse já é tirado por
/// [_leadingBullet]) é quase sempre separador de UI — local + categoria
/// ("Neighbours • Home"), tag + tag. Ingrediente/passo de verdade não usa
/// esse caractere pra separar palavra.
final _midLineBulletSeparator = RegExp(r'\S\s*[•●]\s*\S');

/// Barra de abas do site grudada numa linha só ("Resumo Ingredientes Modo
/// de preparo Comentários") — tem palavra de seção, mas não É uma seção;
/// pra contar como aba teria que ter pelo menos duas dessas palavras juntas
/// (uma só, sozinha na linha, já é pega por [_ingredientsHeading]/
/// [_stepsHeading] normalmente).
final _navTabWords = [
  RegExp(r'\bresumo\b', caseSensitive: false),
  RegExp(r'\bingredientes?\b', caseSensitive: false),
  RegExp(r'\bmodo de preparo\b', caseSensitive: false),
  RegExp(r'\bcoment[aá]rios?\b', caseSensitive: false),
];

bool _looksLikeNavTabBar(String line) {
  var hits = 0;
  for (final w in _navTabWords) {
    if (w.hasMatch(line)) hits++;
    if (hits >= 2) return true;
  }
  return false;
}

bool _isChromeNoise(String line) =>
    _socialUiButton.hasMatch(line) ||
    _handleOrHashtag.hasMatch(line) ||
    _socialCount.hasMatch(line) ||
    _clockLike.hasMatch(line) ||
    _batteryLike.hasMatch(line) ||
    _looksLikeNavTabBar(line) ||
    _selfProfileName.hasMatch(line) ||
    _relativeTime.hasMatch(line) ||
    _replyPlaceholder.hasMatch(line) ||
    _likedBySentence.hasMatch(line) ||
    _peopleContinuation.hasMatch(line) ||
    _bareInteractionCount.hasMatch(line) ||
    _usernameLikeToken.hasMatch(line) ||
    _strayGlyph.hasMatch(line) ||
    _midLineBulletSeparator.hasMatch(line);

/// Recebe as linhas de texto reconhecidas (em ordem de leitura) e monta um
/// rascunho pro formulário — sempre revisado pelo usuário antes de salvar,
/// nunca cria a receita sozinha. Sem nenhum texto reconhecível, devolve
/// `null`. Descarta de cara ruído de interface — barra de status do
/// celular, abas do site, botão/contador de rede social (print de vídeo do
/// TikTok/Instagram: "Seguir", curtidas, @usuário...).
ImportedRecipe? parseOcrLines(List<String> rawLines) {
  final lines = [
    for (final l in rawLines) _cleanLine(l),
  ].where((l) => l.isNotEmpty && !_isChromeNoise(l)).toList();
  if (lines.isEmpty) return null;

  final ingredientsAt = lines.indexWhere(_ingredientsHeading.hasMatch);
  final stepsAt = lines.indexWhere(_stepsHeading.hasMatch);
  final stopAt = lines.indexWhere(
    _sectionStopMarker.hasMatch,
    ingredientsAt == -1 ? 0 : ingredientsAt + 1,
  );

  if (ingredientsAt == -1 && stepsAt == -1) {
    // Sem nenhum marcador de seção — melhor esforço: 1ª linha é o nome, o
    // resto vira ingredientes (o usuário reorganiza na revisão), parando
    // num widget de sugestão/anúncio se achar um.
    final cut = stopAt == -1 ? lines.length : stopAt;
    return ImportedRecipe(
      name: lines.first,
      ingredientLines: lines.sublist(1, cut < 1 ? 1 : cut),
    );
  }

  final titleEnd = [
    if (ingredientsAt != -1) ingredientsAt,
    if (stepsAt != -1) stepsAt,
  ].reduce((a, b) => a < b ? a : b);
  final titleLines = lines.sublist(0, titleEnd);
  final name = titleLines.isEmpty ? 'Receita importada' : titleLines.first;
  final about = titleLines.length > 1 ? titleLines.skip(1).join(' ') : null;

  final ingredientsEnd = [
    if (stepsAt > ingredientsAt) stepsAt,
    if (stopAt != -1 && stopAt > ingredientsAt) stopAt,
    lines.length,
  ].reduce((a, b) => a < b ? a : b);

  final ingredientLines = ingredientsAt == -1
      ? const <String>[]
      : lines.sublist(ingredientsAt + 1, ingredientsEnd);

  final stepLines = stepsAt == -1
      ? const <String>[]
      : _splitSteps(lines.sublist(stepsAt + 1));

  return ImportedRecipe(
    name: name,
    about: about,
    ingredientLines: ingredientLines,
    stepLines: stepLines,
  );
}

/// Junta linhas quebradas do mesmo passo quando dá pra achar numeração
/// ("1.", "Passo 2"); sem numeração nenhuma, cada linha vira um passo —
/// melhor esforço, o usuário ajusta na revisão.
List<String> _splitSteps(List<String> lines) {
  final hasNumbering = lines.any((l) => _numberedStepPrefix.hasMatch(l));
  if (!hasNumbering) return lines;

  final out = <String>[];
  for (final line in lines) {
    if (_numberedStepPrefix.hasMatch(line)) {
      out.add(line.replaceFirst(_numberedStepPrefix, '').trim());
    } else if (out.isNotEmpty) {
      out[out.length - 1] = '${out.last} $line'.trim();
    } else {
      out.add(line);
    }
  }
  return out;
}
