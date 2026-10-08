import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart'
    show ChoicePill;
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Pergunta quanto custa o ingrediente (uma vez só — vale pra toda receita) e
/// em que unidade. Devolve `true` se gravou ou removeu o preço.
Future<bool> showIngredientPriceSheet(
  BuildContext context,
  Ingredient ingredient,
) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _PriceSheet(ingredient: ingredient),
  );
  return saved ?? false;
}

class _PriceSheet extends ConsumerStatefulWidget {
  const _PriceSheet({required this.ingredient});

  final Ingredient ingredient;

  @override
  ConsumerState<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends ConsumerState<_PriceSheet> {
  late final TextEditingController _controller;
  late PriceBasis _basis;
  String? _error;

  @override
  void initState() {
    super.initState();
    final price = widget.ingredient.price;
    _basis = price?.basis ?? PriceBasis.kg;
    _controller = TextEditingController(
      text: price == null ? '' : _plain(price.cents),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// "8,50" — sem o "R$", pra editar.
  String _plain(int cents) =>
      formatMoney(cents).replaceFirst('R\$ ', '').replaceAll('.', '');

  Future<void> _save() async {
    final cents = parseMoneyToCents(_controller.text);
    if (cents == null) {
      setState(() => _error = 'Digite um valor maior que zero, como 8,50');
      return;
    }
    final result = await ref
        .read(ingredientRepositoryProvider)
        .setPrice(widget.ingredient.id, IngredientPrice(cents, _basis));
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

  @override
  Widget build(BuildContext context) {
    final hasPrice = widget.ingredient.price != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheetFrame(
        title: widget.ingredient.displayName,
        subtitle: 'Quanto custa ${_basisPhrase(_basis)}?',
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                hintText: '0,00',
                errorText: _error,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final b in PriceBasis.values)
                  ChoicePill(
                    label: b.label,
                    selected: b == _basis,
                    onTap: () => setState(() => _basis = b),
                  ),
              ],
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

String _basisPhrase(PriceBasis basis) => switch (basis) {
      PriceBasis.kg => '1 kg',
      PriceBasis.liter => '1 litro',
      PriceBasis.unit => '1 unidade',
    };

/// "R$ 6,00/kg", "R$ 5,00/L", "R$ 1,00/un".
String priceTag(IngredientPrice price) {
  final suffix = switch (price.basis) {
    PriceBasis.kg => 'kg',
    PriceBasis.liter => 'L',
    PriceBasis.unit => 'un',
  };
  return '${formatMoney(price.cents)}/$suffix';
}
