/// Divide o texto reconhecido numa foto de receita (C8, RF-06.10) em
/// nome/ingredientes/passos. Dart puro — sem Flutter, sem o plugin de OCR
/// em si (quem roda o reconhecimento é a camada de dados). Diferente do
/// JSON-LD do C7, aqui não tem marcação nenhuma — é heurística por palavra-
/// chave de seção ("Ingredientes", "Modo de preparo"...) sobre as linhas que
/// o OCR devolveu, na ordem em que apareceram na foto.
library;

import 'package:receyta/core/tag_name.dart';

import 'ingredient_parser.dart';
import 'recipe_import.dart';

/// Aceita dois-pontos no fim ("Ingredientes:") — quase toda receita de
/// verdade escreve o cabeçalho assim; exigir a linha inteira sem pontuação
/// nenhuma fazia o cabeçalho passar batido e tudo (inclusive o preparo)
/// cair no fallback de "não achei seção nenhuma". Também aceita texto colado
/// depois dos dois-pontos ("Modo de preparo: no vídeo") — o grupo nomeado
/// `rest` guarda esse texto pra virar conteúdo da seção em vez de vazar pra
/// seção errada (sem os dois-pontos não aceita colado, só o cabeçalho
/// sozinho — senão qualquer frase começando com "ingredientes" viraria
/// cabeçalho).
final _ingredientsHeading = RegExp(
  r'^ingredientes?(\s*:\s*(?<rest>\S.*)|\s*:?)$',
  caseSensitive: false,
);

final _stepsHeading = RegExp(
  r'^(modo de preparo|modo de fazer|preparo|instru(ç|c)(õ|o)es|como fazer|'
  r'm(é|e)todo|instructions|directions)(\s*:\s*(?<rest>\S.*)|\s*:?)$',
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

/// Ícone (compartilhar/link) que sobra colado no fim de um título de card
/// ("Cookie Saudável de Maçã e Aveia (Sem Açúcar) •"). Só no fim da linha —
/// bullet no meio já é tratado como ruído por [_midLineBulletSeparator].
final _trailingIconGlyph = RegExp(r'\s*[•●○◦]\s*$');

String _cleanLine(String line) {
  var l = line.trim().replaceFirst(_leadingBullet, '').trim();
  l = l.replaceFirst(_photoCaptionSuffix, '').trim();
  l = l.replaceFirst(_trailingIconGlyph, '').trim();
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

/// Mesma barra de abas de [_looksLikeNavTabBar], mas pro caso do OCR ler
/// cada aba como uma linha separada (comum quando são botões espacialmente
/// afastados na tela) — aí nenhuma linha sozinha tem duas palavras de aba
/// juntas. "Ingredientes" ou "Comentários" sozinhos na linha só contam como
/// ruído quando vêm GRUDADOS a outra aba (2+ seguidas); um "Ingredientes"
/// isolado, longe de qualquer outra aba, é o cabeçalho de verdade.
final _soloNavTabWord = RegExp(
  r'^(resumo|ingredientes?|modo de preparo|coment[aá]\w*)$',
  caseSensitive: false,
);

List<String> _dropNavTabRuns(List<String> lines) {
  final drop = List<bool>.filled(lines.length, false);
  var i = 0;
  while (i < lines.length) {
    if (!_soloNavTabWord.hasMatch(lines[i])) {
      i++;
      continue;
    }
    var j = i + 1;
    while (j < lines.length && _soloNavTabWord.hasMatch(lines[j])) {
      j++;
    }
    if (j - i >= 2) {
      for (var k = i; k < j; k++) {
        drop[k] = true;
      }
    }
    i = j;
  }
  return [
    for (var k = 0; k < lines.length; k++)
      if (!drop[k]) lines[k],
  ];
}

/// Barra de abas de busca do Google ("Modo IA", "Tudo", "Shopping",
/// "Vídeos curtos"...) — aparece em print de tela de resultado de busca,
/// não é conteúdo da receita.
final _searchTabBar = RegExp(
  r'^(modo ia|tudo(\s+shopp\w*)?|imagens|v[ií]deos(\s+curtos)?|'
  r'not[ií]cias|shopping|maps)$',
  caseSensitive: false,
);

/// Selo "Visão geral criada por IA" do Google (AI Overview) — não é texto
/// da receita, é rótulo da interface de busca.
final _aiOverviewBadge = RegExp(
  r'^vis[ãa]o geral criada por ia$',
  caseSensitive: false,
);

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
    _midLineBulletSeparator.hasMatch(line) ||
    _searchTabBar.hasMatch(line) ||
    _aiOverviewBadge.hasMatch(line);

/// Entre as linhas antes da 1ª seção reconhecida, o nome de verdade
/// normalmente é a primeira linha (ex.: "Torta de limão" / "Rende 8
/// porções", onde a 2ª linha é só um detalhe extra). Mas em print de
/// "Visão geral" de IA (Google) tem frase de verdade (o resumo gerado)
/// ANTES do título real, com o título sanduichado entre esse resumo e a
/// descrição do card. Só desvia do padrão "1ª linha é o nome" quando dá
/// pra ver frase de verdade ali perto (alguma linha termina em ponto) —
/// aí procura, de trás pra frente, a última linha que não é fim de frase
/// mas vem logo antes de uma que é.
bool _looksLikeSentenceEnd(String l) => l.endsWith('.');

int _titleLineIndex(List<String> titleLines) {
  final hasProse = titleLines.any(_looksLikeSentenceEnd);
  if (hasProse) {
    for (var i = titleLines.length - 2; i >= 0; i--) {
      if (!_looksLikeSentenceEnd(titleLines[i]) &&
          _looksLikeSentenceEnd(titleLines[i + 1])) {
        return i;
      }
    }
  }
  return 0;
}

/// Recebe as linhas de texto reconhecidas (em ordem de leitura) e monta um
/// rascunho pro formulário — sempre revisado pelo usuário antes de salvar,
/// nunca cria a receita sozinha. Sem nenhum texto reconhecível, devolve
/// `null`. Descarta de cara ruído de interface — barra de status do
/// celular, abas do site, botão/contador de rede social (print de vídeo do
/// TikTok/Instagram: "Seguir", curtidas, @usuário...).
ImportedRecipe? parseOcrLines(List<String> rawLines) {
  var lines = [
    for (final l in rawLines) _cleanLine(l),
  ].where((l) => l.isNotEmpty && !_isChromeNoise(l)).toList();
  lines = _dropNavTabRuns(lines);
  if (lines.isEmpty) return null;

  final ingredientsAt = lines.indexWhere(_ingredientsHeading.hasMatch);
  final stepsAt = lines.indexWhere(_stepsHeading.hasMatch);
  final stopAt = lines.indexWhere(
    _sectionStopMarker.hasMatch,
    ingredientsAt == -1 ? 0 : ingredientsAt + 1,
  );
  // Texto colado depois do heading ("Modo de preparo: no vídeo") vira 1º
  // conteúdo da seção em vez de vazar pra fora dela — ver [_stepsHeading].
  final stepsRest = stepsAt == -1
      ? null
      : _stepsHeading.firstMatch(lines[stepsAt])?.namedGroup('rest');

  if (ingredientsAt == -1 && stepsAt == -1) {
    // Sem nenhum marcador de seção — 1ª linha é o nome; dali em diante,
    // enquanto a linha tiver cara de ingrediente (e não de instrução de
    // preparo), continua na lista de ingredientes — daí pra frente já é
    // preparo. Também para num widget de sugestão/anúncio se achar um.
    final cut = stopAt == -1 ? lines.length : stopAt;
    final body = lines.sublist(1, cut < 1 ? 1 : cut);
    final ingredientsEnd = _ingredientRunEnd(body, 0, body.length);
    return ImportedRecipe(
      name: fixShoutyCase(lines.first),
      ingredientLines:
          body.sublist(0, ingredientsEnd).map(fixOcrDigitLetterConfusion).toList(),
      stepLines: _splitSteps(body.sublist(ingredientsEnd))
          .map(fixOcrDigitLetterConfusion)
          .toList(),
    );
  }

  final titleEnd = [
    if (ingredientsAt != -1) ingredientsAt,
    if (stepsAt != -1) stepsAt,
  ].reduce((a, b) => a < b ? a : b);
  final titleLines = lines.sublist(0, titleEnd);

  var name = 'Receita importada';
  String? about;
  var ingredientLinesFromTitleBlock = const <String>[];
  if (titleLines.isNotEmpty) {
    final titleIdx = _titleLineIndex(titleLines);
    name = titleLines[titleIdx];
    final beforeName = titleLines.take(titleIdx).toList();
    final afterName = titleLines.skip(titleIdx + 1).toList();

    if (ingredientsAt == -1) {
      // Achou heading de preparo mas não de "Ingredientes:" — a lista está
      // misturada no bloco do título, sem rótulo na frente (comum em
      // caderno/livro de receita). Mesma heurística de formato usada acima.
      final run = _ingredientRunEnd(afterName, 0, afterName.length);
      ingredientLinesFromTitleBlock = afterName.sublist(0, run);
      final aboutLines = [...beforeName, ...afterName.sublist(run)];
      about = aboutLines.isEmpty ? null : aboutLines.join(' ');
    } else {
      final aboutLines = [...beforeName, ...afterName];
      about = aboutLines.isEmpty ? null : aboutLines.join(' ');
    }
  }

  final List<String> ingredientLines;
  if (ingredientsAt == -1) {
    ingredientLines = ingredientLinesFromTitleBlock;
  } else {
    final ingredientsEnd = [
      if (stepsAt > ingredientsAt) stepsAt,
      if (stopAt != -1 && stopAt > ingredientsAt) stopAt,
      lines.length,
    ].reduce((a, b) => a < b ? a : b);
    final ingredientsRest =
        _ingredientsHeading.firstMatch(lines[ingredientsAt])?.namedGroup(
      'rest',
    );
    final rawIngredientLines = [
      if (ingredientsRest != null) ingredientsRest,
      ...lines.sublist(ingredientsAt + 1, ingredientsEnd),
    ];

    // "Ingredientes" é a 1ª linha (sem nome nenhum antes) e a última linha
    // da lista não tem cara de ingrediente: em alguns prints (recorte de
    // post, texto estilizado) o nome da receita vem DEPOIS da lista.
    if (titleLines.isEmpty &&
        rawIngredientLines.isNotEmpty &&
        !_hasQuantityOrUnit(rawIngredientLines.last)) {
      name = rawIngredientLines.removeLast();
    }
    ingredientLines = rawIngredientLines;
  }

  final stepLines = stepsAt == -1
      ? const <String>[]
      : _splitSteps([
          if (stepsRest != null) stepsRest,
          ...lines.sublist(stepsAt + 1),
        ]);

  return ImportedRecipe(
    name: fixShoutyCase(name),
    about: about,
    ingredientLines: ingredientLines.map(fixOcrDigitLetterConfusion).toList(),
    stepLines: stepLines.map(fixOcrDigitLetterConfusion).toList(),
  );
}

/// Marca início de receita em livro/caderno numerado ("1) Toast", "10) Pão
/// sem queijo") — é assim que uma foto acaba trazendo mais de uma receita
/// (a página inteira do livro numa foto só). Aceita "I)"/"l)" além de "1)" —
/// em fonte sem serifa o "1" fica idêntico ao "I" maiúsculo, e é comum o OCR
/// ler o "1)" do primeiro título como letra (a lista de ingredientes logo
/// abaixo, cheia de "1 colher de sopa...", vira a mesma pista: se o OCR leu
/// "I colher" ali, leu "I)" aqui do mesmo jeito). Só conta como separador
/// quando aparece 2+ vezes na mesma foto; uma vez só é o número da receita
/// atual, não um separador (uma foto raramente tem só um fiapo de outra).
final _multiRecipeMarker = RegExp(r'^(?:\d+|[Il])\)\s+\S');
final _multiRecipeMarkerPrefix = RegExp(r'^(?:\d+|[Il])\)\s+');

/// Mesma extração de [parseOcrLines], mas primeiro checa se a foto trouxe
/// mais de uma receita (livro/caderno numerado) e, se trouxe, roda a
/// extração em cada trecho separado — em vez de misturar tudo numa receita
/// só. Sem marcador repetido, devolve a mesma receita única de
/// [parseOcrLines] (ou lista vazia se não achar texto nenhum).
List<ImportedRecipe> parseOcrLinesMulti(List<String> rawLines) {
  final lines = _dropNavTabRuns([
    for (final l in rawLines) _cleanLine(l),
  ].where((l) => l.isNotEmpty && !_isChromeNoise(l)).toList());

  final markerAt = [
    for (var i = 0; i < lines.length; i++)
      if (_multiRecipeMarker.hasMatch(lines[i])) i,
  ];

  if (markerAt.length < 2) {
    final single = parseOcrLines(rawLines);
    return single == null ? const [] : [single];
  }

  final out = <ImportedRecipe>[];
  for (var i = 0; i < markerAt.length; i++) {
    final end = i + 1 < markerAt.length ? markerAt[i + 1] : lines.length;
    final recipe = parseOcrLines(lines.sublist(markerAt[i], end));
    if (recipe == null) continue;
    out.add(
      ImportedRecipe(
        name: recipe.name.replaceFirst(_multiRecipeMarkerPrefix, ''),
        about: recipe.about,
        ingredientLines: recipe.ingredientLines,
        stepLines: recipe.stepLines,
      ),
    );
  }
  return out;
}

/// Verbo/frase que só aparece no início de instrução de preparo — nunca em
/// linha de ingrediente. Usado pra achar onde a lista de ingrediente acaba
/// quando a receita não tem heading nenhum separando ingrediente de preparo
/// (comum em caderno/livro de receita: a lista vem direto embaixo do nome).
final _prepInstructionStart = RegExp(
  r'^(descasque|corte|cozinhe|amasse|misture|coloque|adicione|asse|assar|'
  r'leve|despeje|acrescente|bata|unte|molde|pr[ée]-?aque[çc]a|deixe|'
  r'tempere|sirva|retire|junte|esprema|pique|rale|prepare|esquente|'
  r'aque[çc]a|ferva|doure|frite|reserve|escorra|forre|disponha|espalhe|'
  r'polvilhe|cubra|transfira|no liquidificador|no processador|'
  r'em uma tigela|numa tigela|em uma panela|numa panela)\b',
  caseSensitive: false,
);

/// Linha de ingrediente raramente passa de 8~10 palavras e quase nunca
/// termina em ponto final — frase de preparo de verdade, sim.
bool _looksLikePrepProse(String line) {
  if (_prepInstructionStart.hasMatch(line)) return true;
  if (_numberedStepPrefix.hasMatch(line)) return true;
  if (!line.endsWith('.')) return false;
  return line.trim().split(RegExp(r'\s+')).length >= 6;
}

/// Acha, a partir de `start`, até onde vai o trecho contínuo de linha com
/// cara de preparo — pra separar ingrediente (sem heading) do que vem
/// embaixo sem virar tudo "sobre" ou tudo "ingrediente".
int _ingredientRunEnd(List<String> lines, int start, int end) {
  var i = start;
  while (i < end && !_looksLikePrepProse(lines[i])) {
    i++;
  }
  return i;
}

/// Quantidade/medida no começo ou no meio da linha — número, fração unicode
/// ("½", "¼"...) ou palavra de unidade comum (xícara, colher, dente...).
/// Diferente de [_looksLikePrepProse] (que acha onde o preparo COMEÇA), esse
/// aqui confirma se uma linha específica TEM cara de ingrediente — usado só
/// pra decidir se a última linha antes do fim é ingrediente de verdade ou o
/// nome da receita, que em alguns prints vem depois da lista, não antes.
final _quantityOrUnit = RegExp(
  r'^(\d+([.,/]\d+)?|[½¼¾⅓⅔])|\b(x[ií]caras?|colh(eres?|\.)?|dentes?|'
  r'pitadas?|gramas?|fatias?|unidades?|latas?|copos?|pun(h|g)ado|'
  r'a\s+(gosto|vontade)|[ãa]\s+vontade)\b',
  caseSensitive: false,
);

bool _hasQuantityOrUnit(String line) =>
    _quantityOrUnit.hasMatch(line) ||
    RegExp(r'^(sal|opcional)\b', caseSensitive: false).hasMatch(line);

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
