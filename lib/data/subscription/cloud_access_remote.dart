import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// De onde vem o acesso à parte online.
enum AccessSource {
  none,

  /// Assinatura da própria pessoa na Google Play.
  own,

  /// Liberação manual (amigos, testers).
  grant,

  /// Casa cujo dono tem acesso.
  house,
}

/// Se a pessoa pode usar a parte online (sync, casa, fotos na nuvem) e até
/// quando. O servidor é quem decide; o app só mostra e pausa o que não vale.
@immutable
class CloudAccess {
  const CloudAccess({
    required this.active,
    this.source = AccessSource.none,
    this.until,
  });

  static const none = CloudAccess(active: false);

  final bool active;
  final AccessSource source;

  /// Fim do período pago ou liberado. Nulo com [active] = sem prazo.
  final DateTime? until;

  /// Vale agora? Cobre o caso de o prazo passar com o app aberto ou de o
  /// aparelho estar sem internet para perguntar de novo.
  bool isActiveAt(DateTime now) {
    if (!active) return false;
    final end = until;
    return end == null || end.isAfter(now);
  }

  static CloudAccess fromJson(Object? json) {
    if (json is! Map) return none;
    final source = switch (json['source']) {
      'own' => AccessSource.own,
      'grant' => AccessSource.grant,
      'house' => AccessSource.house,
      _ => AccessSource.none,
    };
    return CloudAccess(
      active: json['active'] == true,
      source: source,
      until: DateTime.tryParse('${json['until'] ?? ''}')?.toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'active': active,
        'source': source.name,
        'until': until?.toIso8601String(),
      };
}

/// O que o app precisa do servidor sobre o acesso. Injetável pra o teste não
/// usar rede.
abstract class CloudAccessRemote {
  Future<CloudAccess> fetch();

  /// Pede ao servidor que confira a assinatura direto na loja (função
  /// `sync-subscription`) em vez de esperar o aviso do RevenueCat.
  Future<void> syncSubscription();
}

class SupabaseCloudAccessRemote implements CloudAccessRemote {
  SupabaseCloudAccessRemote(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<CloudAccess> fetch() async =>
      CloudAccess.fromJson(await _client.rpc('my_access'));

  @override
  Future<void> syncSubscription() async {
    await _client.functions.invoke('sync-subscription');
  }
}

class NoCloudAccessRemote implements CloudAccessRemote {
  const NoCloudAccessRemote();

  @override
  Future<CloudAccess> fetch() async => CloudAccess.none;

  @override
  Future<void> syncSubscription() async {}
}

final cloudAccessRemoteProvider = Provider<CloudAccessRemote>((ref) {
  try {
    return SupabaseCloudAccessRemote(sb.Supabase.instance.client);
  } catch (_) {
    return const NoCloudAccessRemote();
  }
});
