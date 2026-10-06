import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';

/// Cor do perfil que a folha de edição está experimentando, antes de salvar.
/// `null` = sem prévia. Quem edita escreve aqui a cada toque (o perfil por
/// trás muda na hora) e quem abriu a folha zera ao fechar — cancelar, arrastar
/// pra baixo ou salvar, tanto faz.
final profileColorPreviewProvider = StateProvider<TileColor?>((ref) => null);

/// A cor que o perfil mostra: a prévia, se houver, senão a salva.
final effectiveProfileColorProvider = Provider<TileColor>((ref) {
  return ref.watch(profileColorPreviewProvider) ??
      ref.watch(appSettingsProvider.select((s) => s.profileColor));
});
