import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/database/seed_data.dart';
import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/domain/engine/text_normalize.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/features/recipes/screens/cost_notes.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart'
    show ChoicePill;
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
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

/// Nome por extenso com a abreviação entre parênteses, como aparece na lista
/// de unidades. As sem abreviação ("dente", "xícara") só ganham a inicial
/// maiúscula.
const _unitLabels = {
  'kg': 'Quilograma (kg)',
  'g': 'Gramas (g)',
  'mg': 'Miligrama (mg)',
  'l': 'Litro (L)',
  'ml': 'Mililitro (ml)',
  'unidade': 'Unidade (un)',
};

String priceUnitLabel(String code) {
  final fixed = _unitLabels[code];
  if (fixed != null) return fixed;
  final unit = kSeedUnits.firstWhere(
    (u) => u.code == code,
    orElse: () => kSeedUnits.first,
  );
  final name = unit.displayName;
  return name[0].toUpperCase() + name.substring(1);
}

/// As unidades do seletor, em três grupos. Dentro de cada um, as mais comuns
/// primeiro.
final List<({String title, List<SeedUnit> units})> _unitGroups = () {
  List<SeedUnit> of(String kind, List<String> first) {
    final all =
        kSeedUnits.where((u) => u.kind == kind && isPriceUnit(u.code)).toList();
    return [
      for (final code in first) all.firstWhere((u) => u.code == code),
      for (final u in all)
        if (!first.contains(u.code)) u,
    ];
  }

  return [
    (title: 'Peso', units: of('mass', ['kg', 'g'])),
    (title: 'Volume', units: of('volume', ['l', 'ml'])),
    (title: 'Contagem', units: of('count', ['unidade'])),
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

  Future<void> _pickUnit() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _UnitPicker(selected: _unit),
    );
    if (picked != null && mounted) setState(() => _unit = picked);
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
            _UnitField(
              unitCode: _unit,
              onTap: _pickUnit,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            const PriceLocalNote(),
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

/// O campo "Unidade": parece um campo de texto, mostra o nome por extenso da
/// unidade escolhida e abre o seletor.
class _UnitField extends StatelessWidget {
  const _UnitField({required this.unitCode, required this.onTap});

  final String unitCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Unidade: ${priceUnitLabel(unitCode)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Unidade',
            suffixIcon: Icon(Icons.expand_more_rounded),
          ),
          child: Text(
            priceUnitLabel(unitCode),
            style: context.texts.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Folha de escolha da unidade: botão de voltar, busca, filtro por tipo
/// (Peso, Volume, Contagem) e a lista em grupos bem marcados. A atual vem
/// destacada em escuro. Tocar numa unidade escolhe e fecha; "Voltar" fecha sem
/// mudar nada.
class _UnitPicker extends StatefulWidget {
  const _UnitPicker({required this.selected});

  final String selected;

  @override
  State<_UnitPicker> createState() => _UnitPickerState();
}

class _UnitPickerState extends State<_UnitPicker> {
  final _search = TextEditingController();
  String _query = '';
  String? _kind;

  static const _kinds = [
    (kind: 'mass', title: 'Peso', icon: Icons.scale_outlined),
    (kind: 'volume', title: 'Volume', icon: Icons.water_drop_outlined),
    (kind: 'count', title: 'Contagem', icon: Icons.numbers_rounded),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(SeedUnit unit) {
    final q = stripAccents(_query.trim().toLowerCase());
    if (q.isEmpty) return true;
    final label = stripAccents(priceUnitLabel(unit.code).toLowerCase());
    return label.contains(q) || unit.code.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final height = MediaQuery.sizeOf(context).height;

    final groups = <Widget>[];
    for (var i = 0; i < _unitGroups.length; i++) {
      final meta = _kinds[i];
      if (_kind != null && _kind != meta.kind) continue;
      final units = _unitGroups[i].units.where(_matches).toList();
      if (units.isEmpty) continue;
      groups.add(_GroupHeader(title: meta.title, icon: meta.icon));
      groups.add(
        Container(
          decoration: BoxDecoration(
            color: colors.paperSoft,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var j = 0; j < units.length; j++) ...[
                if (j > 0) Divider(height: 1, color: colors.paper),
                _UnitRow(
                  label: priceUnitLabel(units[j].code),
                  selected: units[j].code == widget.selected,
                  onTap: () => Navigator.of(context).pop(units[j].code),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheetFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Voltar',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Unidade',
                    style: AppTextStyles.display(30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar unidade',
                prefixIcon: Icon(Icons.search, color: colors.textMuted),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoicePill(
                    label: 'Todas',
                    selected: _kind == null,
                    onTap: () => setState(() => _kind = null),
                  ),
                  for (final k in _kinds) ...[
                    const SizedBox(width: AppSpacing.xs),
                    ChoicePill(
                      label: k.title,
                      selected: _kind == k.kind,
                      onTap: () => setState(() => _kind = k.kind),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: height * 0.5,
              child: groups.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma unidade encontrada',
                        style: context.texts.bodyMedium
                            ?.copyWith(color: colors.textMuted),
                      ),
                    )
                  : ListView(children: groups),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faixa de título de um grupo: ícone numa bolinha escura, nome em caixa alta
/// e um fio — deixa claro onde um grupo acaba e outro começa.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration:
                BoxDecoration(color: colors.ink, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: colors.lime),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title.toUpperCase(),
            style: context.texts.labelMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Divider(height: 1, color: colors.textMuted)),
        ],
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.ink : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: context.texts.bodyLarge?.copyWith(
                      color: selected ? colors.onSaturated : colors.ink,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected) Icon(Icons.check_rounded, color: colors.lime),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
