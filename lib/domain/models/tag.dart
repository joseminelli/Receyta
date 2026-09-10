import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';

/// Um rótulo livre da receita (§RF-01.10). O usuário digita no formulário; o
/// mesmo `name` (normalizado em minúsculas) reaproveita a linha existente.
@freezed
class Tag with _$Tag {
  const factory Tag({
    required String id,
    required String name,
  }) = _Tag;
}
