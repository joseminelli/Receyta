/// Retorno de operação que pode falhar de forma esperada (§5). Repositórios
/// devolvem `Result`; ViewModels e o import/export (bloco D) consomem via
/// [Result.when]. Dart puro, sem Flutter.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) {
    final self = this;
    return switch (self) {
      Ok<T>() => ok(self.value),
      Err<T>() => err(self.failure),
    };
  }

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// Causa de uma falha esperada. Sealed para `switch` exaustivo no consumidor.
sealed class Failure {
  const Failure(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType($message)';
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.cause});
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Entrada do usuário rejeitada antes de tocar no repositório (nome vazio, etc).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
