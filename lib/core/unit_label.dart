import 'package:receyta/data/database/seed_data.dart';

/// Nome por extenso da unidade (singular/plural conforme a quantidade) —
/// usado no detalhe da receita e na lista de compras. `null` quando o
/// código não bate com nenhuma unidade do seed (não deveria acontecer com
/// dado gravado pelo próprio app, mas não quebra se acontecer).
String? unitLabel(String? unitCode, double quantity) {
  if (unitCode == null) return null;
  for (final u in kSeedUnits) {
    if (u.code == unitCode) return quantity == 1 ? u.displayName : u.plural;
  }
  return null;
}
