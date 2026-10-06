import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:receyta/core/result.dart';
import 'package:receyta/core/supabase_config.dart';

/// Quem está logado: só o que a interface precisa mostrar.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;
}

/// Porta de entrada da conta. A interface (e os testes) falam com isto, nunca
/// com o Supabase direto — o login é opcional, o app inteiro funciona sem ele.
abstract class AuthService {
  AppUser? get currentUser;

  /// Emite a cada entrada ou saída (e também quando a sessão é restaurada).
  Stream<AppUser?> get userChanges;

  /// `Ok(null)` = a pessoa fechou a janela do Google, não é erro.
  Future<Result<AppUser?>> signInWithGoogle();

  Future<void> signOut();
}

/// Login nativo do Google trocado por uma sessão do Supabase
/// (`signInWithIdToken`): sem navegador, sem redirecionamento.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client, {GoogleSignIn? google})
      : _google = google ?? GoogleSignIn(serverClientId: kGoogleWebClientId);

  final sb.SupabaseClient _client;
  final GoogleSignIn _google;

  @override
  AppUser? get currentUser => _toUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> get userChanges =>
      _client.auth.onAuthStateChange.map((s) => _toUser(s.session?.user));

  @override
  Future<Result<AppUser?>> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) return const Ok(null);

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        return const Err(
          ProcessingFailure('O Google não devolveu a identificação.'),
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      return Ok(_toUser(response.user));
    } on PlatformException catch (e) {
      // Algumas versões do plugin avisam o cancelamento assim, não com `null`.
      if (e.code == 'sign_in_canceled') return const Ok(null);
      debugPrint('signInWithGoogle: ${e.code} ${e.message}');
      return Err(failureForSignIn(e));
    } catch (e) {
      debugPrint('signInWithGoogle: $e');
      return Err(failureForSignIn(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (e) {
      debugPrint('signOut(google): $e');
    }
    try {
      await _client.auth.signOut();
    } catch (e) {
      // Conta já excluída no servidor (ou sem rede): o token não vale mais, e
      // sair só no aparelho resolve. Nunca deixa a pessoa presa logada.
      debugPrint('signOut(supabase): $e');
      await _client.auth.signOut(scope: sb.SignOutScope.local);
    }
  }

  AppUser? _toUser(sb.User? user) {
    if (user == null) return null;
    final meta = user.userMetadata ?? const <String, dynamic>{};
    return AppUser(
      id: user.id,
      email: user.email,
      name: (meta['full_name'] ?? meta['name']) as String?,
      avatarUrl: (meta['avatar_url'] ?? meta['picture']) as String?,
    );
  }
}

/// A falha de login em português: sem rede, o Google recusando neste aparelho
/// (quase sempre configuração do app) ou outra coisa. O texto cru do Google e
/// do Supabase (em inglês, técnico) fica só em `cause`.
Failure failureForSignIn(Object error) {
  final text = error.toString().toLowerCase();
  final offline = error is SocketException ||
      error is sb.AuthRetryableFetchException ||
      (error is PlatformException && error.code == 'network_error') ||
      text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('network_error') ||
      text.contains('unable to resolve host');
  if (offline) {
    return NetworkFailure(
      'Sem internet. Conecte-se e tente de novo.',
      cause: error,
    );
  }
  if (error is PlatformException) {
    return ProcessingFailure(
      'Não foi possível entrar com o Google neste aparelho. Tente de novo.',
      cause: error,
    );
  }
  return ProcessingFailure('Não foi possível entrar. Tente de novo.',
      cause: error);
}

/// Usado quando o Supabase não inicializou: ninguém logado e entrar falha
/// com mensagem, em vez de derrubar o app.
class UnavailableAuthService implements AuthService {
  const UnavailableAuthService();

  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> get userChanges => const Stream.empty();

  @override
  Future<Result<AppUser?>> signInWithGoogle() async => const Err(
        NetworkFailure('A conta não está disponível agora.'),
      );

  @override
  Future<void> signOut() async {}
}
