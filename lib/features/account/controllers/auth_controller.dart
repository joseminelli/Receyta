import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  try {
    return SupabaseAuthService(sb.Supabase.instance.client);
  } catch (_) {
    return const UnavailableAuthService();
  }
});

/// Usuário logado (ou `null`). Começa com a sessão já restaurada, sem esperar
/// o primeiro evento do stream.
final authUserProvider = StreamProvider<AppUser?>((ref) async* {
  final service = ref.watch(authServiceProvider);
  yield service.currentUser;
  yield* service.userChanges;
});

/// Estado da ação de entrar/sair (loading enquanto a janela do Google ou a
/// troca de token está em andamento).
class AuthController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// `null` = deu certo ou a pessoa cancelou; senão, a falha pra mostrar.
  Future<Failure?> signIn() async {
    state = const AsyncLoading();
    final result = await ref.read(authServiceProvider).signInWithGoogle();
    state = const AsyncData(null);
    if (result.valueOrNull != null) {
      unawaited(ref.read(recipeImageSyncProvider).syncPending());
    }
    return result.when(ok: (_) => null, err: (f) => f);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await ref.read(authServiceProvider).signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, void>(AuthController.new);
