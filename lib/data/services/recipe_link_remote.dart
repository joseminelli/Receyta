import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Os links curtos de receita no servidor (`docs/supabase/recipe-links.sql`).
abstract class RecipeLinkRemote {
  /// Criar link exige conta; ler não.
  bool get canCreate;

  /// Guarda o texto da receita e devolve o token do link.
  Future<String> create(String fragment);

  /// O texto guardado, ou nulo se o token não existe ou já venceu.
  Future<String?> fetch(String token);
}

class SupabaseRecipeLinkRemote implements RecipeLinkRemote {
  SupabaseRecipeLinkRemote(this._client);

  final sb.SupabaseClient _client;

  @override
  bool get canCreate => _client.auth.currentUser != null;

  @override
  Future<String> create(String fragment) async {
    final token = await _client.rpc(
      'create_recipe_link',
      params: {'p_data': fragment},
    );
    return '$token';
  }

  @override
  Future<String?> fetch(String token) async {
    final data = await _client.rpc(
      'get_recipe_link',
      params: {'p_token': token},
    );
    return data is String && data.isNotEmpty ? data : null;
  }
}

/// Usado quando o Supabase não inicializou.
class NoRecipeLinkRemote implements RecipeLinkRemote {
  const NoRecipeLinkRemote();

  @override
  bool get canCreate => false;

  @override
  Future<String> create(String fragment) async =>
      throw StateError('not_authenticated');

  @override
  Future<String?> fetch(String token) async =>
      throw StateError('offline');
}

final recipeLinkRemoteProvider = Provider<RecipeLinkRemote>((ref) {
  try {
    return SupabaseRecipeLinkRemote(sb.Supabase.instance.client);
  } catch (_) {
    return const NoRecipeLinkRemote();
  }
});
