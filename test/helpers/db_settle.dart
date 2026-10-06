import 'package:flutter_test/flutter_test.dart';

/// Deixa terminar as operações de banco que um gesto do teste disparou.
///
/// Por que existe: num `testWidgets` o relógio é falso (`FakeAsync`). Uma
/// transação do Drift precisa de voltas do relógio REAL pra concluir e depois
/// de microtarefas do relógio falso pra continuar. Quem só faz `pump` nunca dá
/// a volta real; quem lê o banco por `runAsync` espera a transação soltar o
/// bloqueio — que depende do relógio falso. Resultado: o teste trava (e,
/// quando uma asserção falha antes, a limpeza também). Alternar as duas coisas
/// resolve.
Future<void> settleDb(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}
