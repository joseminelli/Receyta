import 'dart:io';

import 'package:flutter/foundation.dart';
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
    } on SocketException catch (e) {
      return Err(NetworkFailure('Sem conexão com a internet.', cause: e));
    } on sb.AuthException catch (e) {
      return Err(ProcessingFailure(e.message, cause: e));
    } catch (e) {
      return Err(ProcessingFailure('Não foi possível entrar.', cause: e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (e) {
      debugPrint('signOut(google): $e');
    }
    await _client.auth.signOut();
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
