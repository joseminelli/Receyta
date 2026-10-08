import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/database/seed_data.dart';
import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Pergunta quanto custa o ingrediente (uma vez só — vale pra toda receita):
/// "R$ [valor] por [quantidade] [unidade]". Serve pra "R$ 6 por kg", "R$ 4,50
/// por 500 g", "R$ 3 por maço", "R$ 1,20 por dente". [suggestedUnit] é a
/// unidade que já vem escolhida quando ainda não há preço (a que a receita
/// usa). Devolve `true` se gravou ou removeu o preço.
Future<bool> showIngredientPriceSheet(
  BuildContext context,
  Ingredient ingredient, {
  String? suggestedUnit,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _PriceSheet(
      ingredient: ingredient,
      suggestedUnit: suggestedUnit,
    ),
  );
  return saved ?? false;
}

/// As unidades do menu: as de peso e volume mais comuns primeiro, depois o
/// resto na ordem do catálogo (dente, maço, lata, pacote...).
final List<SeedUnit> _menuUnits = () {
  const first = ['kg', 'g', 'l', 'ml', 'unidade'];
  final all = kSeedUnits.where((u) => isPriceUnit(u.code)).toList();
  return [
    for (final code in first) all.firstWhere((u) => u.code == code),
    for (final u in all)
      if (!first.contains(u.code)) u,
  ];
}();

class _PriceSheet extends ConsumerStatefulWidget {
  const _PriceSheet({required this.ingredient, this.suggestedUnit});

  final Ingredient ingredient;
  final String? suggestedUnit;

  @override
  ConsumerState<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends ConsumerState<_PriceSheet> {
  late final TextEditingController _value;
  late final TextEditingController _quantity;
  late String _unit;
  String? _error;

  @override
  void initState() {
    super.initState();
    final price = widget.ingredient.price;
    _value =
        TextEditingController(text: price == null ? '' : _plain(price.cents));
    _quantity = TextEditingController(
      text: price == null ? '1' : _quantityText(price.quantity),
    );
    final suggested = widget.suggestedUnit;
    _unit = price?.unitCode ??
        (suggested != null && isPriceUnit(suggested) ? suggested : 'kg');
  }

  @override
  void dispose() {
    _value.dispose();
    _quantity.dispose();
    super.dispose();
  }

  /// "8,50" — sem o "R$", pra editar.
  String _plain(int cents) =>
      formatMoney(cents).replaceFirst('R\$ ', '').replaceAll('.', '');

  Future<void> _save() async {
    final cents = parseMoneyToCents(_value.text);
    if (cents == null) {
      setState(() => _error = 'Digite um valor maior que zero, como 8,50');
      return;
    }
    final quantity = parseQuantity(_quantity.text);
    if (quantity == null) {
      setState(() => _error = 'Digite uma quantidade maior que zero, como 1');
      return;
    }
    final result = await ref.read(ingredientRepositoryProvider).setPrice(
          widget.ingredient.id,
          IngredientPrice(cents, _unit, quantity),
        );
    if (!mounted) return;
    result.when(
      ok: (_) => Navigator.of(context).pop(true),
      err: (f) => setState(() => _error = f.message),
    );
  }

  Future<void> _remove() async {
    await ref
        .read(ingredientRepositoryProvider)
        .setPrice(widget.ingredient.id, null);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final hasPrice = widget.ingredient.price != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheetFrame(
        title: widget.ingredient.displayName,
        subtitle: 'Quanto você paga? Use a embalagem que comprou.',
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _value,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearError(),
                    decoration: const InputDecoration(
                      prefixText: 'R\$ ',
                      hintText: '0,00',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm + 2,
                    AppSpacing.sm,
                    0,
                  ),
                  child: Text('por'),
                ),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _quantity,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _clearError(),
                    onSubmitted: (_) => _save(),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: '1'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _unit,
              isExpanded: true,
              items: [
                for (final u in _menuUnits)
                  DropdownMenuItem(value: u.code, child: Text(u.displayName)),
              ],
              onChanged: (v) => setState(() => _unit = v ?? _unit),
              decoration: const InputDecoration(labelText: 'Unidade'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            PillButton(label: 'Salvar preço', onPressed: _save),
            if (hasPrice) ...[
              const SizedBox(height: AppSpacing.xs),
              PillButton(
                label: 'Remover preço',
                variant: PillButtonVariant.ghost,
                onPressed: _remove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lê "1", "500", "0,5" ou "1.5". `null` se não for maior que zero.
double? parseQuantity(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return (value == null || value <= 0) ? null : value;
}

String _quantityText(double q) {
  final s = q == q.roundToDouble() ? q.toInt().toString() : q.toString();
  return s.replaceAll('.', ',');
}

/// "R$ 6,00/kg", "R$ 4,50/500 g", "R$ 3,00/maço", "R$ 12,00/12 unidades".
String priceTag(IngredientPrice price) {
  final unit = kSeedUnits.firstWhere(
    (u) => u.code == price.unitCode,
    orElse: () => kSeedUnits.first,
  );
  final String per;
  if (price.quantity == 1) {
    per = unit.code == 'unidade' ? 'un' : unit.displayName;
  } else {
    per = '${_quantityText(price.quantity)} ${unit.plural}';
  }
  return '${formatMoney(price.cents)}/$per';
}
