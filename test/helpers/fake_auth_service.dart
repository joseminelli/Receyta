import 'dart:async';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/auth_service.dart';

/// Conta em memória: nada de rede nem de Google. `nextResult` define o que o
/// próximo `signInWithGoogle` devolve.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? user}) : _user = user;

  AppUser? _user;
  final _controller = StreamController<AppUser?>.broadcast();

  Result<AppUser?>? nextResult;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  @override
  Future<Result<AppUser?>> signInWithGoogle() async {
    signInCalls++;
    final result = nextResult ?? const Ok(null);
    if (result is Ok<AppUser?>) {
      _user = result.value;
      _controller.add(_user);
    }
    return result;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    _controller.add(null);
  }
}
