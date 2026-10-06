import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:receyta/core/result.dart';

/// Alguém que faz parte da casa.
@immutable
class SpaceMember {
  const SpaceMember({
    required this.userId,
    required this.displayName,
    required this.isOwner,
  });

  final String userId;
  final String displayName;
  final bool isOwner;
}

/// A casa (espaço compartilhado) e as pessoas dela.
@immutable
class SpaceInfo {
  const SpaceInfo({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
  });

  final String id;
  final String name;
  final String ownerId;
  final List<SpaceMember> members;

  static SpaceInfo? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final owner = json['owner_id'];
    if (id is! String || owner is! String) return null;
    final members = <SpaceMember>[];
    final raw = json['members'];
    if (raw is List) {
      for (final m in raw) {
        if (m is! Map || m['user_id'] is! String) continue;
        members.add(SpaceMember(
          userId: m['user_id'] as String,
          displayName: '${m['display_name'] ?? ''}'.trim(),
          isOwner: m['role'] == 'owner',
        ));
      }
    }
    return SpaceInfo(
      id: id,
      name: '${json['name'] ?? 'Casa'}',
      ownerId: owner,
      members: members,
    );
  }
}

/// Criar casa, convidar, entrar, sair e remover alguém. Cada operação é uma
/// função do servidor (ver `docs/supabase/spaces.sql`): é lá que se garante
/// que só entra quem tem convite válido e só o dono convida e remove.
abstract class SpaceRemote {
  /// `null` = ninguém logado.
  String? get userId;

  /// A casa de quem está logado, ou nulo se não participa de nenhuma.
  Future<SpaceInfo?> mySpace();

  Future<SpaceInfo> createSpace(String displayName);

  /// Código de convite (8 caracteres, uso único, vale 48 horas).
  Future<String> createInvite();

  Future<SpaceInfo> joinSpace(String code, String displayName);

  /// Quem sai é o membro; se for o dono, a casa acaba.
  Future<void> leaveSpace();

  Future<void> removeMember(String userId);

  /// Muda o nome com que a pessoa aparece na casa.
  Future<void> setDisplayName(String name);
}

class SupabaseSpaceRemote implements SpaceRemote {
  SupabaseSpaceRemote(this._client);

  final sb.SupabaseClient _client;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<SpaceInfo?> mySpace() async {
    final data = await _client.rpc('my_space');
    return SpaceInfo.fromJson(data);
  }

  Future<SpaceInfo> _required() async {
    final info = await mySpace();
    if (info == null) throw StateError('space_missing');
    return info;
  }

  @override
  Future<SpaceInfo> createSpace(String displayName) async {
    await _client.rpc('create_space', params: {'p_display_name': displayName});
    return _required();
  }

  @override
  Future<String> createInvite() async {
    final code = await _client.rpc('create_invite');
    return '$code';
  }

  @override
  Future<SpaceInfo> joinSpace(String code, String displayName) async {
    await _client.rpc('join_space', params: {
      'p_code': code,
      'p_display_name': displayName,
    });
    return _required();
  }

  @override
  Future<void> leaveSpace() async {
    await _client.rpc('leave_space');
  }

  @override
  Future<void> removeMember(String userId) async {
    await _client.rpc('remove_member', params: {'p_user': userId});
  }

  @override
  Future<void> setDisplayName(String name) async {
    await _client.rpc('set_display_name', params: {'p_name': name});
  }
}

/// Usado quando o Supabase não inicializou.
class NoSpaceRemote implements SpaceRemote {
  const NoSpaceRemote();

  @override
  String? get userId => null;

  Never _off() => throw StateError('not_authenticated');

  @override
  Future<SpaceInfo?> mySpace() async => null;

  @override
  Future<SpaceInfo> createSpace(String displayName) async => _off();

  @override
  Future<String> createInvite() async => _off();

  @override
  Future<SpaceInfo> joinSpace(String code, String displayName) async => _off();

  @override
  Future<void> leaveSpace() async {}

  @override
  Future<void> removeMember(String userId) async {}

  @override
  Future<void> setDisplayName(String name) async {}
}

final spaceRemoteProvider = Provider<SpaceRemote>((ref) {
  try {
    return SupabaseSpaceRemote(sb.Supabase.instance.client);
  } catch (_) {
    return const NoSpaceRemote();
  }
});

/// Traduz o erro de uma operação da casa numa mensagem pra pessoa.
Failure failureForSpace(Object error) {
  final text = '$error';
  String? pick(Map<String, String> table) {
    for (final e in table.entries) {
      if (text.contains(e.key)) return e.value;
    }
    return null;
  }

  final known = pick({
    'invalid_invite':
        'Esse código não vale mais. Peça um novo para quem te convidou.',
    'already_in_space':
        'Você já faz parte de uma casa. Saia dela antes de entrar em outra.',
    'space_full': 'Essa casa já está cheia (6 pessoas).',
    'not_owner': 'Só quem criou a casa pode fazer isso.',
    'too_many_invites':
        'Há convites demais em aberto. Use um deles ou espere vencer.',
    'cannot_remove_owner': 'O dono não pode ser removido.',
    'not_authenticated': 'Entre na sua conta para usar a casa.',
  });
  if (known != null) return ValidationFailure(known);

  final lower = text.toLowerCase();
  final offline = lower.contains('socketexception') ||
      lower.contains('clientexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('timeout') ||
      lower.contains('network');
  return NetworkFailure(
    offline
        ? 'Sem conexão. Tente de novo quando a internet voltar.'
        : 'Não foi possível falar com o servidor agora. Tente de novo.',
    cause: error,
  );
}
