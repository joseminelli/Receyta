import 'package:flutter/material.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/smart_collections.dart';

/// Ícone e cor de cada coleção inteligente — a parte visual que o motor
/// (Dart puro) não conhece.
extension SmartCollectionStyle on SmartCollection {
  IconData get icon => switch (this) {
        SmartCollection.quick => Icons.bolt_rounded,
        SmartCollection.neverCooked => Icons.restaurant_menu_rounded,
        SmartCollection.mostCooked => Icons.repeat_rounded,
        SmartCollection.forgotten => Icons.hourglass_empty_rounded,
        SmartCollection.favorites => Icons.favorite_rounded,
      };

  TileColor get color => switch (this) {
        SmartCollection.quick => TileColor.lime,
        SmartCollection.neverCooked => TileColor.violet,
        SmartCollection.mostCooked => TileColor.coral,
        SmartCollection.forgotten => TileColor.mar,
        SmartCollection.favorites => TileColor.framboesa,
      };
}
