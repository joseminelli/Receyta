/// Normalizador de nome de ingrediente (§8.2). Dart puro. Produz a chave de
/// identidade (`normalized_key`) usada pelo `getOrCreate`: minúsculas, sem
/// acento, sem pontuação, sem stopword/qualificador, no singular.
library;

import '../../data/database/seed_data.dart';
import 'text_normalize.dart';

String _singularize(String word) {
  if (word.length <= 3) return word;
  if (word.endsWith('oes')) return '${word.substring(0, word.length - 3)}ao';
  if (word.endsWith('aes')) return '${word.substring(0, word.length - 3)}ao';
  if (word.endsWith('ais')) return '${word.substring(0, word.length - 3)}al';
  if (word.endsWith('eis')) return '${word.substring(0, word.length - 3)}el';
  if (word.endsWith('ois')) return '${word.substring(0, word.length - 3)}ol';
  if (word.length > 3 && word.endsWith('ns')) {
    return '${word.substring(0, word.length - 2)}m';
  }
  if (word.length > 4 &&
      (word.endsWith('res') || word.endsWith('ses') || word.endsWith('zes'))) {
    return word.substring(0, word.length - 2);
  }
  if (word.endsWith('s') && !word.endsWith('ss')) {
    return word.substring(0, word.length - 1);
  }
  return word;
}

String normalize(String input) {
  final cleaned = stripAccents(input.toLowerCase())
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  final rawTokens =
      cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  final singleTerms = <String>{};
  final multiTerms = <String>{};
  for (final t in kSeedNormalizerTerms) {
    final term = stripAccents(t.term.toLowerCase());
    if (term.contains(' ')) {
      multiTerms.add(term);
    } else {
      singleTerms.add(term);
    }
  }

  final kept = <String>[];
  var i = 0;
  while (i < rawTokens.length) {
    if (i + 1 < rawTokens.length) {
      final bigram = '${rawTokens[i]} ${rawTokens[i + 1]}';
      if (multiTerms.contains(bigram)) {
        i += 2;
        continue;
      }
    }
    if (!singleTerms.contains(rawTokens[i])) {
      kept.add(_singularize(rawTokens[i]));
    }
    i++;
  }
  return kept.join(' ').trim();
}
