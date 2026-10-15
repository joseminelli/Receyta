import 'dart:async';

import 'package:receyta/data/services/volume_keys.dart';

/// Botões de volume de mentira: o teste aperta com [press] e confere se a
/// captura foi ligada ao abrir a tela e desligada ao sair.
class FakeVolumeKeys implements VolumeKeys {
  final _controller = StreamController<VolumeKey>.broadcast();
  final enabledCalls = <bool>[];

  bool get enabled => enabledCalls.isNotEmpty && enabledCalls.last;

  @override
  Stream<VolumeKey> get events => _controller.stream;

  @override
  Future<void> setEnabled(bool on) async => enabledCalls.add(on);

  void press(VolumeKey key) => _controller.add(key);
}
