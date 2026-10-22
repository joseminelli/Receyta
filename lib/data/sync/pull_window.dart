import 'package:shared_preferences/shared_preferences.dart';

/// Quanto tempo pode passar sem uma "puxada completa" (ignorando o ponto de
/// leitura). O ponto de leitura só olha pra frente: um item que chegou antes
/// do que ele depende (uma refeição antes da receita, um item antes da lista)
/// é pulado e o ponto passa dele. Reler tudo de vez em quando recupera esses
/// casos — é idempotente, e o que já está igual é pulado sem custo no banco.
const kFullPullEvery = Duration(hours: 12);

/// De onde começar a puxar nesta rodada: [since] nulo = tudo ([full]).
typedef PullWindow = ({DateTime? since, bool full});

/// Decide a janela da puxada: tudo quando não há ponto de leitura, quando
/// [force] (botão "Sincronizar") ou quando já faz [kFullPullEvery] da última
/// puxada completa; senão, só o que mudou desde o ponto (recuando [overlap]).
Future<PullWindow> pullWindow(
  SharedPreferences prefs,
  String cursorKey,
  Duration overlap, {
  bool force = false,
  DateTime Function()? now,
}) async {
  final saved = DateTime.tryParse(prefs.getString(cursorKey) ?? '');
  if (saved == null) return (since: null, full: true);
  final lastFull =
      DateTime.tryParse(prefs.getString(_fullKey(cursorKey)) ?? '');
  final clock = (now ?? DateTime.now)();
  final due = lastFull == null || clock.difference(lastFull) >= kFullPullEvery;
  if (force || due) return (since: null, full: true);
  return (since: saved.subtract(overlap), full: false);
}

/// Marca que uma puxada completa terminou bem.
Future<void> markFullPull(
  SharedPreferences prefs,
  String cursorKey, {
  DateTime Function()? now,
}) =>
    prefs.setString(
      _fullKey(cursorKey),
      (now ?? DateTime.now)().toUtc().toIso8601String(),
    );

String _fullKey(String cursorKey) => '${cursorKey}_full_at';
