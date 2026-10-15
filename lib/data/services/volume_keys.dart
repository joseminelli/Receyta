import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VolumeKey { up, down }

/// Os botões de volume do aparelho como controle: enquanto ligado, o Android
/// entrega o aperto aqui e não mexe no volume. Só existe no Android; nas
/// outras plataformas e nos testes nunca emite nada.
abstract class VolumeKeys {
  Stream<VolumeKey> get events;

  /// Liga ou desliga a captura dos botões. Desligue sempre ao sair da tela
  /// que usa, senão o volume do aparelho fica travado.
  Future<void> setEnabled(bool on);
}

class PlatformVolumeKeys implements VolumeKeys {
  PlatformVolumeKeys() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'key') return;
      switch (call.arguments) {
        case 'up':
          _controller.add(VolumeKey.up);
        case 'down':
          _controller.add(VolumeKey.down);
      }
    });
  }

  static const _channel = MethodChannel('receyta/volume_keys');
  final _controller = StreamController<VolumeKey>.broadcast();

  @override
  Stream<VolumeKey> get events => _controller.stream;

  @override
  Future<void> setEnabled(bool on) async {
    try {
      await _channel.invokeMethod<void>('setEnabled', on);
    } catch (_) {}
  }
}

final volumeKeysProvider = Provider<VolumeKeys>((ref) => PlatformVolumeKeys());
