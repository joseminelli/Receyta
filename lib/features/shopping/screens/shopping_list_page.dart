import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/widgets/money_text.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/domain/engine/shopping_text.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/domain/models/shopping_list_item.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/recipes/controllers/cost_view_model.dart';
import 'package:receyta/features/mascot/widgets/animated_mascot.dart';
import 'package:receyta/features/mascot/widgets/mascot_moment.dart';
import 'package:receyta/features/recipes/screens/ingredient_price_sheet.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_prefs.dart';
import 'package:receyta/features/shopping/screens/shopping_actions.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/action_menu_button.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/swipe_action_background.dart';
import 'package:receyta/widgets/sweep_strike_text.dart';

/// Largura fixa da coluna de quantidade — alinha os números em coluna.
const _quantityColumn = 60.0;

/// Uma lista de compras (E3–E5, RF-05.5–05.8): superfície escura, mesma
/// linguagem do modo cozinha (§9.8) — é outra tela "de mão suja"/uso rápido,
/// não de leitura. Rota empilhada (`/shopping/:id`), aberta a partir da tela
/// de listas; agrupada por corredor, marcar item risca e afunda pro fim da
/// seção.
class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key, required this.listId});

  final String listId;

  /// Lista concluída: tem itens e todos estão marcados.
  bool _allChecked(List<ShoppingListItem>? items) =>
      items != null && items.isNotEmpty && items.every((i) => i.checked);

  /// O botão "Desmarcar todos" só aparece com algo marcado.
  bool _hasChecked(WidgetRef ref, String id) =>
      ref
          .watch(shoppingListItemsProvider(id))
          .valueOrNull
          ?.any((i) => i.checked) ??
      false;

  /// O botão "Marcar todos" só aparece com algo pendente.
  bool _hasUnchecked(WidgetRef ref, String id) =>
      ref
          .watch(shoppingListItemsProvider(id))
          .valueOrNull
          ?.any((i) => !i.checked) ??
      false;

  Future<void> _share(WidgetRef ref) async {
    final list = ref.read(shoppingListProvider(listId)).valueOrNull;
    if (list == null) return;
    final items =
        await ref.read(shoppingListRepositoryProvider).itemsOf(list.id);
    if (items.isEmpty) return;
    await Share.share(
      buildShoppingListText(list.name, items),
      subject: list.name,
    );
  }

  Future<void> _toggleShared(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final controller = ref.read(spaceControllerProvider.notifier);
    if (list.spaceId == null) {
      if (ref.read(currentSpaceIdProvider) == null) {
        showAppSnackBar(message: 'Crie uma casa para compartilhar listas.');
        context.push('/space');
        return;
      }
      final result = await controller.setListShared(list.id, true);
      result.when(
        ok: (_) => showAppSnackBar(message: 'Lista compartilhada com a casa.'),
        err: (f) => showAppSnackBar(
          message: f.message,
          variant: AppSnackBarVariant.error,
        ),
      );
      return;
    }
    final ok = await AppDialog.confirm(
      context,
      icon: Icons.group_off_outlined,
      accent: context.colors.danger,
      title: 'Deixar de compartilhar?',
      message: 'Quem está na casa deixa de ver esta lista. Ela continua com '
          'você.',
      confirmLabel: 'Deixar de compartilhar',
    );
    if (!ok) return;
    final result = await controller.setListShared(list.id, false);
    result.when(
      ok: (_) {},
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final listAsync = ref.watch(shoppingListProvider(listId));
    final list = listAsync.valueOrNull;
    final showPrices =
        ref.watch(shoppingViewPrefsProvider.select((p) => p.itemPrices));
    final hasPrices = !ref.watch(shoppingCostProvider(listId)).isEmpty;

    ref.listen(shoppingListItemsProvider(listId), (previous, next) {
      if (!_allChecked(previous?.valueOrNull) && _allChecked(next.valueOrNull)) {
        showMascotMoment(kind: MascotKind.pote);
      }
    });

    return HeaderScaffold(
      title: list?.name ?? 'Compras',
      color: TileColor.lime,
      backgroundColor: colors.ink,
      trailing: list == null
          ? null
          : ActionMenuButton(
              items: [
                if (_hasUnchecked(ref, list.id))
                  ActionMenuItem(
                    icon: Icons.done_all,
                    label: 'Marcar todos',
                    hint: 'Dá a lista por concluída',
                    onTap: () => checkAllShoppingItems(ref, list.id),
                  ),
                if (_hasChecked(ref, list.id))
                  ActionMenuItem(
                    icon: Icons.remove_done,
                    label: 'Desmarcar todos',
                    hint: 'Volta todos os itens pra pendente',
                    onTap: () => uncheckAllShoppingItems(ref, list.id),
                  ),
                if (hasPrices)
                  ActionMenuItem(
                    icon: showPrices
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    label: showPrices
                        ? 'Ocultar preços dos itens'
                        : 'Mostrar preços dos itens',
                    hint: 'O valor da lista continua no cartão',
                    onTap: () => ref
                        .read(shoppingViewPrefsProvider.notifier)
                        .setItemPrices(!showPrices),
                  ),
                ActionMenuItem(
                  icon: Icons.ios_share,
                  label: 'Compartilhar',
                  hint: 'Como texto',
                  onTap: () => _share(ref),
                ),
                if (ref.watch(authUserProvider).valueOrNull != null)
                  ActionMenuItem(
                    icon: list.spaceId == null
                        ? Icons.group_add_outlined
                        : Icons.group_off_outlined,
                    label: list.spaceId == null
                        ? 'Compartilhar com a casa'
                        : 'Deixar de compartilhar',
                    hint: list.spaceId == null
                        ? 'Quem está na casa vê e marca os itens'
                        : 'Quem está na casa deixa de ver esta lista',
                    onTap: () => _toggleShared(context, ref, list),
                  ),
              ],
            ),
      body: listAsync.when(
        loading: () => const Center(child: BrandLoader()),
        error: (_, __) => _buildMessage(context, 'Não deu para carregar.'),
        data: (list) => list == null
            ? _buildMessage(context, 'Esta lista não existe mais.')
            : _buildList(context, ref, list),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String text) {
    return Center(
      child: Text(
        text,
        style: context.texts.bodyLarge
            ?.copyWith(color: context.colors.onSaturated),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, ShoppingList list) {
    final itemsAsync = ref.watch(shoppingListItemsProvider(list.id));
    return itemsAsync.when(
      loading: () => const Center(child: BrandLoader()),
      error: (_, __) => _buildMessage(context, 'Não deu para carregar.'),
      data: (items) => Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? const _EmptyListHint()
                : _buildGroups(context, items),
          ),
          _ListFooter(listId: list.id, items: items),
        ],
      ),
    );
  }

  Widget _buildGroups(BuildContext context, List<ShoppingListItem> items) =>
      _ShoppingItems(items: items);
}

/// Rodapé fixo: o valor da lista, sempre à vista e na altura do polegar, e o
/// campo de adicionar item.
class _ListFooter extends ConsumerWidget {
  const _ListFooter({required this.listId, required this.items});

  final String listId;
  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cost = ref.watch(shoppingCostProvider(listId));
    final allDone = items.isNotEmpty && items.every((i) => i.checked);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!cost.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              0,
            ),
            child: _CostBar(cost: cost, allDone: allDone),
          ),
        _AddItemBar(listId: listId, autofocus: items.isEmpty),
      ],
    );
  }
}

IconData _categoryIcon(String slug) => switch (slug) {
      'hortifruti' => Icons.eco_outlined,
      'acougue' => Icons.kebab_dining_outlined,
      'peixaria' => Icons.set_meal_outlined,
      'frios_laticinios' => Icons.egg_alt_outlined,
      'padaria' => Icons.bakery_dining_outlined,
      'mercearia' => Icons.shopping_basket_outlined,
      'massas_molhos' => Icons.ramen_dining_outlined,
      'enlatados_conservas' => Icons.inventory_2_outlined,
      'temperos_condimentos' => Icons.spa_outlined,
      'matinais_cereais' => Icons.breakfast_dining_outlined,
      'congelados' => Icons.ac_unit,
      'bebidas' => Icons.local_drink_outlined,
      'doces_sobremesas' => Icons.cake_outlined,
      'higiene_limpeza' => Icons.cleaning_services_outlined,
      _ => Icons.category_outlined,
    };

enum _MovePhase { still, leaving, entering }

/// Corpo rolável da lista. Marcar/desmarcar acontece em duas etapas pra o
/// usuário entender o que houve: primeiro o item muda no lugar (risco e
/// bolinha), e só depois de uma pausa a linha sai, desce (ou sobe) e reaparece
/// na posição nova. `_sortState` guarda o "checked" usado só pra ordenar — ele
/// acompanha o valor real com atraso.
class _ShoppingItems extends StatefulWidget {
  const _ShoppingItems({required this.items});

  final List<ShoppingListItem> items;

  @override
  State<_ShoppingItems> createState() => _ShoppingItemsState();
}

class _ShoppingItemsState extends State<_ShoppingItems> {
  static const _settleDelay = Duration(milliseconds: 750);
  static const _leaveDuration = Duration(milliseconds: 280);
  static const _enterDuration = Duration(milliseconds: 320);

  final _sortState = <String, bool>{};
  final _phase = <String, _MovePhase>{};
  final _timers = <String, Timer>{};

  /// Itens já deslizados pra fora: somem da tela na hora (o `Dismissible`
  /// exige isso) enquanto o banco ainda apaga e o stream não reemitiu.
  final _removed = <String>{};

  /// A seção "Comprados" começa recolhida: o que já está no carrinho sai do
  /// meio da lista.
  bool _boughtOpen = false;

  List<ShoppingListItem> get _visible => [
        for (final i in widget.items)
          if (!_removed.contains(i.id)) i
      ];

  void _setRemoved(String id, {required bool removed}) {
    setState(() => removed ? _removed.add(id) : _removed.remove(id));
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _ShoppingItems old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _sync() {
    final ids = {for (final i in widget.items) i.id};
    for (final gone
        in _sortState.keys.where((k) => !ids.contains(k)).toList()) {
      _sortState.remove(gone);
      _phase.remove(gone);
      _timers.remove(gone)?.cancel();
    }
    _removed.removeWhere((id) => !ids.contains(id));
    for (final item in _visible) {
      final known = _sortState[item.id];
      if (known == null) {
        _sortState[item.id] = item.checked;
      } else if (known == item.checked) {
        _timers.remove(item.id)?.cancel();
        _phase.remove(item.id);
      } else if (!_timers.containsKey(item.id)) {
        _timers[item.id] = Timer(_settleDelay, () => _leave(item.id));
      }
    }
  }

  /// Ordem visual (ids na sequência exata da tela, seções incluídas) pra um
  /// dado estado de ordenação.
  List<String> _visualOrder(Map<String, bool> state) {
    final proxied = [
      for (final i in _visible) i.copyWith(checked: state[i.id] ?? i.checked),
    ];
    final pending = [
      for (final i in proxied)
        if (!i.checked) i
    ];
    final bought = [
      for (final i in proxied)
        if (i.checked) i
    ];
    return [
      for (final g in groupShoppingItems(pending))
        for (final i in g.items) i.id,
      if (_boughtOpen)
        for (final g in groupShoppingItems(bought))
          for (final i in g.items) i.id,
    ];
  }

  /// Só anima a saída se a linha realmente muda de lugar; senão (já é a
  /// última da seção, única, etc.) fica só o risco no lugar — sem movimento
  /// à toa.
  void _leave(String id) {
    if (!mounted) return;
    final current = widget.items.where((i) => i.id == id).firstOrNull;
    if (current == null) return;
    final after = {..._sortState, id: current.checked};
    final moves = !listEquals(_visualOrder(_sortState), _visualOrder(after));
    if (!moves) {
      _timers.remove(id);
      setState(() => _sortState[id] = current.checked);
      return;
    }
    setState(() => _phase[id] = _MovePhase.leaving);
    _timers[id] = Timer(_leaveDuration, () => _enter(id));
  }

  void _enter(String id) {
    if (!mounted) return;
    final current = widget.items.where((i) => i.id == id).firstOrNull;
    setState(() {
      if (current != null) _sortState[id] = current.checked;
      _phase[id] = _MovePhase.entering;
    });
    _timers[id] = Timer(_enterDuration, () {
      if (!mounted) return;
      _timers.remove(id);
      setState(() => _phase.remove(id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final actualById = {for (final i in visible) i.id: i};
    final forSorting = [
      for (final i in visible)
        i.copyWith(checked: _sortState[i.id] ?? i.checked),
    ];
    final pending = [
      for (final i in forSorting)
        if (!i.checked) i
    ];
    final bought = [
      for (final i in forSorting)
        if (i.checked) i
    ];

    Widget row(ShoppingListItem item) {
      final phase = _phase[item.id] ?? _MovePhase.still;
      return _MoveTransition(
        key: ValueKey(item.id),
        phase: phase,
        movingDown: item.checked,
        leaveDuration: _leaveDuration,
        enterDuration: _enterDuration,
        child: _ItemRow(
          item: item,
          onRemoved: (removed) => _setRemoved(item.id, removed: removed),
        ),
      );
    }

    final children = <Widget>[_ProgressHeader(items: visible)];
    for (final group in groupShoppingItems(pending)) {
      final rows = [for (final i in group.items) actualById[i.id]!];
      children.add(
        _SectionHeader(slug: group.slug, label: group.label, items: rows),
      );
      children.addAll(rows.map(row));
    }
    if (bought.isNotEmpty) {
      children.add(
        _BoughtHeader(
          count: bought.length,
          open: _boughtOpen,
          onTap: () => setState(() => _boughtOpen = !_boughtOpen),
        ),
      );
      if (_boughtOpen) {
        for (final group in groupShoppingItems(bought)) {
          children.addAll(group.items.map((i) => row(actualById[i.id]!)));
        }
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      children: children,
    );
  }
}

/// Saída/entrada da linha: ao sair ela desliza pra direção do movimento
/// enquanto some e recolhe; na posição nova reaparece expandindo.
class _MoveTransition extends StatelessWidget {
  const _MoveTransition({
    super.key,
    required this.phase,
    required this.movingDown,
    required this.leaveDuration,
    required this.enterDuration,
    required this.child,
  });

  final _MovePhase phase;
  final bool movingDown;
  final Duration leaveDuration;
  final Duration enterDuration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final leaving = phase == _MovePhase.leaving;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: leaving ? 0 : 1),
      duration: leaving ? leaveDuration : enterDuration,
      curve: leaving ? Curves.easeInCubic : Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) {
        if (t == 1) return child!;
        final dy = leaving ? (1 - t) * 28 * (movingDown ? 1 : -1) : 0.0;
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            child: Opacity(
              opacity: t,
              child: Transform.translate(offset: Offset(0, dy), child: child),
            ),
          ),
        );
      },
    );
  }
}

/// "7/12" em escala grande ao lado de uma barra fina em lime que enche
/// conforme se marca.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.items});

  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = items.length;
    final done = items.where((i) => i.checked).length;
    final allDone = total > 0 && done == total;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Semantics(
        label: allDone
            ? 'Tudo comprado'
            : '$done de $total ${total == 1 ? 'item' : 'itens'}',
        excludeSemantics: true,
        child: Row(
          children: [
            if (allDone)
              Text(
                'Tudo comprado',
                style: AppTextStyles.display(24).copyWith(color: colors.lime),
              )
            else
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$done',
                      style: AppTextStyles.display(32)
                          .copyWith(color: colors.onSaturated),
                    ),
                    TextSpan(
                      text: '/$total',
                      style: AppTextStyles.display(18).copyWith(
                        color: colors.onSaturated.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: SizedBox(
                  height: 6,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: total == 0 ? 0 : done / total),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      backgroundColor:
                          colors.onSaturated.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(colors.lime),
                      minHeight: 6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O valor da lista. Vem recolhido (só "Valor da lista" e uma seta) pra não
/// tomar espaço dos itens; ao tocar mostra o estimado e, quando já se marcou
/// algo, quanto ainda falta comprar. A escolha fica guardada.
class _CostBar extends ConsumerWidget {
  const _CostBar({required this.cost, required this.allDone});

  final ShoppingCost cost;
  final bool allDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final prefs = ref.watch(shoppingViewPrefsProvider);
    final notifier = ref.read(shoppingViewPrefsProvider.notifier);
    final open = prefs.costOpen;
    final muted = colors.onSaturated.withValues(alpha: 0.65);

    return Semantics(
      button: true,
      expanded: open,
      label: 'Valor da lista',
      child: Material(
        color: colors.inkSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => notifier.setCostOpen(!open),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: open ? AppSpacing.sm : AppSpacing.xs + 2,
              ),
              child: open
                  ? _buildOpen(context, notifier, prefs, muted)
                  : _buildClosed(context, muted),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClosed(BuildContext context, Color muted) {
    return Row(
      children: [
        Icon(Icons.payments_outlined, size: 18, color: muted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Valor da lista',
            style: context.texts.labelLarge?.copyWith(color: muted),
          ),
        ),
        Icon(Icons.keyboard_arrow_up_rounded, color: muted),
      ],
    );
  }

  Widget _buildOpen(
    BuildContext context,
    ShoppingViewPrefsNotifier notifier,
    ShoppingViewPrefs prefs,
    Color muted,
  ) {
    final colors = context.colors;
    final showPending =
        cost.pendingCents > 0 && cost.pendingCents != cost.totalCents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'VALOR DA LISTA',
                style: context.texts.labelSmall?.copyWith(color: muted),
              ),
            ),
            IconButton(
              tooltip: prefs.itemPrices
                  ? 'Ocultar preços dos itens'
                  : 'Mostrar preços dos itens',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 36, height: 32),
              padding: EdgeInsets.zero,
              onPressed: () => notifier.setItemPrices(!prefs.itemPrices),
              icon: Icon(
                prefs.itemPrices
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: muted,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: muted),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CostStat(
              label: allDone ? 'GASTO ESTIMADO' : 'ESTIMADO',
              cents: cost.totalCents,
              color: colors.onSaturated,
              size: 24,
            ),
            if (showPending)
              _CostStat(
                label: 'FALTA COMPRAR',
                cents: cost.pendingCents,
                color: colors.lime,
                size: 24,
                alignEnd: true,
              ),
          ],
        ),
        if (cost.missingCount > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: muted),
              const SizedBox(width: 6),
              Text(
                '${cost.missingCount} sem preço',
                style: context.texts.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CostStat extends StatelessWidget {
  const _CostStat({
    required this.label,
    required this.cents,
    required this.color,
    this.size = 30,
    this.alignEnd = false,
  });

  final String label;
  final int cents;
  final Color color;
  final double size;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: '$label ${formatMoney(cents)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.texts.labelSmall
                ?.copyWith(color: colors.onSaturated.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 2),
          MoneyText(cents: cents, size: size, color: color),
        ],
      ),
    );
  }
}

/// "HORTIFRÚTI ———— R$ 18,50  3": ícone e nome do corredor, linha fina,
/// o quanto falta gastar nele e quantos itens faltam.
class _SectionHeader extends ConsumerWidget {
  const _SectionHeader({
    required this.slug,
    required this.label,
    required this.items,
  });

  final String slug;
  final String label;
  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final byItem = items.isEmpty
        ? const <String, int>{}
        : ref.watch(shoppingCostProvider(items.first.listId)).byItem;
    final showPrices =
        ref.watch(shoppingViewPrefsProvider.select((p) => p.itemPrices));
    final subtotal = showPrices
        ? items.fold<int>(0, (sum, i) => sum + (byItem[i.id] ?? 0))
        : 0;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 2),
      child: Row(
        children: [
          Icon(_categoryIcon(slug), size: 16, color: colors.lime),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: context.texts.labelMedium
                ?.copyWith(color: colors.lime, letterSpacing: 1.2),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Container(
              height: 1,
              color: colors.onSaturated.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text.rich(
            TextSpan(
              children: [
                if (subtotal > 0)
                  TextSpan(
                    text: '${formatMoney(subtotal)}  ',
                    style: TextStyle(
                      color: colors.onSaturated.withValues(alpha: 0.55),
                    ),
                  ),
                TextSpan(
                  text: '${items.length}',
                  style: TextStyle(
                    color: colors.onSaturated.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
            style: context.texts.labelMedium,
          ),
        ],
      ),
    );
  }
}

/// "COMPRADOS 7 ———— ⌄": o que já está no carrinho, recolhido por padrão.
class _BoughtHeader extends StatelessWidget {
  const _BoughtHeader({
    required this.count,
    required this.open,
    required this.onTap,
  });

  final int count;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Semantics(
        button: true,
        expanded: open,
        label: 'Comprados, $count',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Text(
                  'COMPRADOS',
                  style: context.texts.labelMedium?.copyWith(
                    color: colors.onSaturated.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$count',
                  style: context.texts.labelMedium?.copyWith(
                    color: colors.onSaturated.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Container(
                    height: 1,
                    color: colors.onSaturated.withValues(alpha: 0.12),
                  ),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.onSaturated.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha do item. Toque ou deslizar pra direita marca/desmarca (a linha volta
/// pro lugar); deslizar pra esquerda tira da lista, depois de confirmar.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item, required this.onRemoved});

  final ShoppingListItem item;

  /// Esconde (true) ou traz de volta (false) a linha na tela — o pai guarda.
  final ValueChanged<bool> onRemoved;

  void _toggle(WidgetRef ref) {
    HapticFeedback.selectionClick();
    ref.read(shoppingListRepositoryProvider).setChecked(item.id, !item.checked);
    if (!item.checked) _offerPrice(ref);
  }

  void _offerPrice(WidgetRef ref) {
    final id = item.ingredientId;
    final ingredient =
        id == null ? null : ref.read(ingredientCatalogProvider)[id];
    if (ingredient == null || ingredient.price != null) return;
    final unit = item.unitId;
    showAppSnackBar(
      message: 'Quanto pagou em ${ingredient.displayName}?',
      actionLabel: 'Informar',
      onAction: () {
        final context = rootNavigatorKey.currentContext;
        if (context == null) return;
        showIngredientPriceSheet(
          context,
          ingredient,
          suggestedUnit: unit != null && isPriceUnit(unit) ? unit : 'unidade',
          suggestedQuantity: item.quantity,
        );
      },
    );
  }

  Future<bool> _confirmRemove(BuildContext context) {
    HapticFeedback.mediumImpact();
    return AppDialog.confirm(
      context,
      icon: Icons.remove_shopping_cart_outlined,
      accent: context.colors.danger,
      title: 'Tirar "${item.displayName}" da lista?',
      message: 'O item sai da lista. Isso não dá para desfazer.',
      confirmLabel: 'Tirar',
    );
  }

  Future<void> _remove(WidgetRef ref) async {
    onRemoved(true);
    final result =
        await ref.read(shoppingListRepositoryProvider).deleteItem(item.id);
    result.when(
      ok: (_) {},
      err: (f) {
        onRemoved(false);
        showAppSnackBar(message: f.message, variant: AppSnackBarVariant.error);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('swipe-${item.id}'),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.25,
        DismissDirection.endToStart: 0.4,
      },
      background: SwipeActionBackground(
        alignment: Alignment.centerLeft,
        icon: item.checked ? Icons.undo : Icons.check,
        label: item.checked ? 'Desmarcar' : 'Marcar',
        color: context.colors.lime,
      ),
      secondaryBackground: SwipeActionBackground(
        alignment: Alignment.centerRight,
        icon: Icons.delete_outline,
        label: 'Tirar',
        color: context.colors.danger,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _toggle(ref);
          return false;
        }
        return _confirmRemove(context);
      },
      onDismissed: (_) => _remove(ref),
      child: _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final done = item.checked;

    return InkWell(
      onTap: () => _toggle(ref),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.onSaturated.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CheckDot(done: done),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(width: _quantityColumn, child: _buildQuantity(context)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: _buildName(context, ref)),
            _buildPrice(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildPrice(BuildContext context, WidgetRef ref) {
    final cents = ref.watch(
      shoppingCostProvider(item.listId).select((c) => c.byItem[item.id]),
    );
    final show =
        ref.watch(shoppingViewPrefsProvider.select((p) => p.itemPrices));
    if (cents == null || !show) return const SizedBox.shrink();
    final alpha = item.checked ? 0.3 : 0.7;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: SizedBox(
        width: 60,
        child: Align(
          alignment: Alignment.centerRight,
          child: MoneyText(
            cents: cents,
            size: 15,
            showSymbol: false,
            color: context.colors.onSaturated.withValues(alpha: alpha),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantity(BuildContext context) {
    final colors = context.colors;
    final qty = shoppingItemQuantity(item);
    if (qty == null) return const SizedBox.shrink();
    final unit = shoppingItemUnit(item);
    final alpha = item.checked ? 0.35 : 1.0;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: qty,
            style: context.texts.titleMedium?.copyWith(
              color: colors.onSaturated.withValues(alpha: alpha),
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          if (unit != null)
            TextSpan(
              text: ' $unit',
              style: context.texts.bodySmall?.copyWith(
                color: colors.onSaturated.withValues(alpha: 0.6 * alpha),
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// "Ana marcou" / "Beto adicionou": só nas listas da casa e só quando foi
  /// outra pessoa (o que a própria pessoa fez não precisa de aviso).
  String? _authorNote(WidgetRef ref) {
    final myId = ref.watch(authUserProvider).valueOrNull?.id;
    final names = ref.watch(memberNamesProvider);
    String name(String id) => names[id] ?? 'Alguém da casa';
    if (item.checked) {
      final by = item.checkedBy;
      if (by != null && by != myId) return '${name(by)} marcou';
      return null;
    }
    final by = item.addedBy;
    if (by != null && by != myId) return '${name(by)} adicionou';
    return null;
  }

  Widget _buildName(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final done = item.checked;
    final origins = shoppingItemOrigins(item);
    final author = _authorNote(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SweepStrikeText(
          text: item.displayName,
          done: done,
          lineColor: colors.onSaturated.withValues(alpha: 0.5),
          style: context.texts.bodyLarge?.copyWith(
            color: done
                ? colors.onSaturated.withValues(alpha: 0.4)
                : colors.onSaturated,
          ),
        ),
        if (author != null) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 13,
                color: colors.lime.withValues(alpha: done ? 0.5 : 0.9),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(
                    color:
                        colors.onSaturated.withValues(alpha: done ? 0.4 : 0.65),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (origins.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            origins.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall?.copyWith(
              color: colors.onSaturated.withValues(alpha: done ? 0.25 : 0.45),
            ),
          ),
        ],
      ],
    );
  }
}

/// Receita de origem como etiqueta só de contorno (fundo nunca tingido).
class _OriginChip extends StatelessWidget {
  const _OriginChip({required this.name, required this.dim});

  final String name;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final alpha = dim ? 0.3 : 0.6;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
            color: colors.onSaturated.withValues(alpha: alpha * 0.6)),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.bodySmall
            ?.copyWith(color: colors.onSaturated.withValues(alpha: alpha)),
      ),
    );
  }
}

/// Bolinha de marcar com um "pop" ao virar feito.
class _CheckDot extends StatefulWidget {
  const _CheckDot({required this.done});

  final bool done;

  @override
  State<_CheckDot> createState() => _CheckDotState();
}

class _CheckDotState extends State<_CheckDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 25),
    TweenSequenceItem(
      tween:
          Tween(begin: 0.8, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween:
          Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
      weight: 35,
    ),
  ]).animate(_pop);

  @override
  void didUpdateWidget(covariant _CheckDot old) {
    super.didUpdateWidget(old);
    if (widget.done && !old.done) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final done = widget.done;
    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? colors.lime : Colors.transparent,
          border: Border.all(
            color:
                done ? colors.lime : colors.onSaturated.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: done ? Icon(Icons.check, size: 16, color: colors.ink) : null,
      ),
    );
  }
}

/// Estado da lista sem itens: diz o que fazer e mostra exemplos do que o
/// campo de baixo entende (quantidade e unidade saem do texto).
class _EmptyListHint extends StatelessWidget {
  const _EmptyListHint();

  static const _examples = ['2 caixas de leite', '500 g de queijo', 'pão'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = colors.onSaturated.withValues(alpha: 0.7);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedMascot(
              kind: MascotKind.pote,
              mood: MascotMood.sad,
              width: 120,
              semanticLabel: 'Pote, triste',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sua lista está vazia',
              style: context.texts.displaySmall
                  ?.copyWith(color: colors.onSaturated),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Digite o que precisa comprar no campo abaixo. A quantidade e '
              'a unidade o app entende sozinho.',
              style: context.texts.bodyMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in _examples) _OriginChip(name: e, dim: false),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Icon(Icons.arrow_downward, size: 20, color: muted),
          ],
        ),
      ),
    );
  }
}

/// Campo de item avulso: pílula do mesmo estilo da navbar; o `+` só aparece
/// com texto digitado.
class _AddItemBar extends ConsumerStatefulWidget {
  const _AddItemBar({required this.listId, this.autofocus = false});

  final String listId;

  /// Lista recém-criada e vazia: o próximo passo óbvio é digitar, então o
  /// teclado já abre. Só vale na montagem do campo.
  final bool autofocus;

  @override
  ConsumerState<_AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends ConsumerState<_AddItemBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final result = await ref
        .read(shoppingListRepositoryProvider)
        .addManualItem(widget.listId, text);
    result.when(
      ok: (_) => _controller.clear(),
      err: (f) => showAppSnackBar(
          message: f.message, variant: AppSnackBarVariant.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
        style: context.texts.bodyLarge?.copyWith(color: colors.onSaturated),
        cursorColor: colors.lime,
        decoration: InputDecoration(
          hintText: 'Adicionar item (ex.: 2 caixas de leite)',
          hintStyle: context.texts.bodyMedium?.copyWith(
            color: colors.onSaturated.withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: colors.inkSoft,
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            borderSide: BorderSide.none,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: value.text.trim().isEmpty
                  ? const SizedBox.shrink(key: ValueKey('empty'))
                  : Padding(
                      key: const ValueKey('add'),
                      padding: const EdgeInsets.all(4),
                      child: CircleIconButton(
                        icon: Icons.add,
                        tooltip: 'Adicionar item',
                        onTap: _submit,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
