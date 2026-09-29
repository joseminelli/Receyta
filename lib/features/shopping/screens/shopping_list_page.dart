import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/engine/shopping_text.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/domain/models/shopping_list_item.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final listAsync = ref.watch(shoppingListProvider(listId));
    final list = listAsync.valueOrNull;

    return Scaffold(
      backgroundColor: colors.ink,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, ref, list),
            Expanded(
              child: listAsync.when(
                loading: () => const Center(child: BrandLoader()),
                error: (_, __) =>
                    _buildMessage(context, 'Não deu para carregar.'),
                data: (list) => list == null
                    ? _buildMessage(context, 'Esta lista não existe mais.')
                    : _buildList(context, ref, list),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, ShoppingList? list) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Voltar',
            onTap: () => context.pop(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              list?.name ?? 'Compras',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.texts.displaySmall
                  ?.copyWith(color: colors.onSaturated),
            ),
          ),
          if (list != null) ...[
            const SizedBox(width: AppSpacing.xs),
            CircleIconButton(
              icon: Icons.ios_share,
              tooltip: 'Compartilhar como texto',
              onTap: () => _share(ref),
            ),
          ],
        ],
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
                ? _buildMessage(context, 'Lista vazia.')
                : _buildGroups(context, items),
          ),
          _AddItemBar(listId: list.id),
        ],
      ),
    );
  }

  Widget _buildGroups(BuildContext context, List<ShoppingListItem> items) =>
      _ShoppingItems(items: items);
}

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

  List<ShoppingListItem> get _visible =>
      [for (final i in widget.items) if (!_removed.contains(i.id)) i];

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
    return [
      for (final g in groupShoppingItems(proxied, sinkChecked: true))
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

    final children = <Widget>[_ProgressHeader(items: visible)];
    for (final group in groupShoppingItems(forSorting, sinkChecked: true)) {
      final rows = [for (final i in group.items) actualById[i.id]!];
      children.add(_SectionHeader(label: group.label, items: rows));
      for (final item in rows) {
        final phase = _phase[item.id] ?? _MovePhase.still;
        children.add(
          _MoveTransition(
            key: ValueKey(item.id),
            phase: phase,
            movingDown: item.checked,
            leaveDuration: _leaveDuration,
            enterDuration: _enterDuration,
            child: _ItemRow(
              item: item,
              onRemoved: (removed) =>
                  _setRemoved(item.id, removed: removed),
            ),
          ),
        );
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

/// "7 de 12 itens" + barra fina em lime que enche conforme se marca.
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
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            allDone
                ? 'Tudo comprado'
                : '$done de $total ${total == 1 ? 'item' : 'itens'}',
            style: context.texts.titleMedium?.copyWith(
              color: allDone ? colors.lime : colors.onSaturated,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: SizedBox(
              height: 6,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: total == 0 ? 0 : done / total),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: colors.onSaturated.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(colors.lime),
                  minHeight: 6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "HORTIFRÚTI ———— 2/5": nome do corredor, linha fina e progresso; a seção
/// inteira marcada apaga.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.items});

  final String label;
  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final done = items.where((i) => i.checked).length;
    final complete = done == items.length;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: complete ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 2),
        child: Row(
          children: [
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
            Text(
              '$done/${items.length}',
              style: context.texts.labelMedium?.copyWith(
                color: colors.onSaturated.withValues(alpha: 0.6),
              ),
            ),
          ],
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
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        icon: item.checked ? Icons.undo : Icons.check,
        label: item.checked ? 'Desmarcar' : 'Marcar',
        color: context.colors.lime,
      ),
      secondaryBackground: _SwipeBackground(
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
            Expanded(child: _buildName(context)),
          ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          qty,
          style: context.texts.titleMedium?.copyWith(
            color: colors.onSaturated.withValues(alpha: alpha),
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(width: 5),
        if (unit != null)
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall?.copyWith(
              color: colors.onSaturated.withValues(alpha: 0.6 * alpha),
            ),
          ),
      ],
    );
  }

  Widget _buildName(BuildContext context) {
    final colors = context.colors;
    final done = item.checked;
    final origins = shoppingItemOrigins(item);
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
        if (origins.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final name in origins) _OriginChip(name: name, dim: done),
            ],
          ),
        ],
      ],
    );
  }
}

/// Fundo revelado ao deslizar a linha: superfície neutra, só o ícone e o
/// rótulo levam a cor da ação (fundo nunca tingido).
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final leading = alignment == Alignment.centerLeft;
    final children = [
      Icon(icon, color: color),
      const SizedBox(width: AppSpacing.xs),
      Text(
        label,
        style: context.texts.labelLarge?.copyWith(color: color),
      ),
    ];
    return Container(
      color: context.colors.inkSoft,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: leading ? children : children.reversed.toList(),
      ),
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

/// Campo de item avulso: pílula do mesmo estilo da navbar; o `+` só aparece
/// com texto digitado.
class _AddItemBar extends ConsumerStatefulWidget {
  const _AddItemBar({required this.listId});

  final String listId;

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
