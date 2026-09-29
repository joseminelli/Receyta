import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_list.freezed.dart';

/// Uma lista de compras (§RF-05). `status` é texto livre por enquanto —
/// só `'active'` existe hoje; arquivar/múltiplas listas simultâneas
/// (RF-05.9, Could) decide o resto do vocabulário quando chegar lá.
@freezed
class ShoppingList with _$ShoppingList {
  const factory ShoppingList({
    required String id,
    required String name,
    @Default('active') String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ShoppingList;
}
