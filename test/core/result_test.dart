import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';

void main() {
  test('when despacha o ramo certo', () {
    const Result<int> ok = Ok(7);
    const Result<int> err = Err(NotFoundFailure('sumiu'));

    expect(ok.when(ok: (v) => 'v=$v', err: (f) => 'e'), 'v=7');
    expect(err.when(ok: (v) => 'v', err: (f) => f.message), 'sumiu');
  });

  test('valueOrNull e isOk', () {
    expect(const Ok<String>('x').valueOrNull, 'x');
    expect(const Err<String>(DatabaseFailure('boom')).valueOrNull, isNull);
    expect(const Ok<int>(1).isOk, isTrue);
    expect(const Err<int>(NotFoundFailure('n')).isOk, isFalse);
  });

  test('ValidationFailure é uma Failure com mensagem', () {
    const Result<int> r = Err(ValidationFailure('nome vazio'));
    expect(r.when(ok: (_) => 'ok', err: (f) => f.message), 'nome vazio');
    expect((r as Err<int>).failure, isA<ValidationFailure>());
  });

  test('Failure carrega a causa', () {
    final f = DatabaseFailure('falhou', cause: StateError('raiz'));
    expect(f.message, 'falhou');
    expect(f.cause, isA<StateError>());
  });
}
