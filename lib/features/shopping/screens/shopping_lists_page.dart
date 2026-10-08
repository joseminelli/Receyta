import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/space/controllers/new_lists_share.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';
import 'package:receyta/features/shopping/screens/shopping_actions.dart';
import 'package:receyta/features/shopping/screens/shopping_recipe_picker.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/swipe_action_background.dart';
import 'package:receyta/widgets/app_sheet.dart';

/// Folga pra `PillNavBar` flutuante (78 de altura visível) + respiro — a
/// home_shell usa `extendBody`, então a aba desenha por baixo dela.
const _navBarClearance = 96.0;

/// Aba "Compras" (RF-05.9): as suas listas, "Em andamento" primeiro e
/// "Concluídas" (tudo marcado) por último. Tocar abre `ShoppingListPage`;
/// deslizar pra direita duplica, pra esquerda exclui (com confirmação).
/// Criar uma nova é a partir de receitas (agrega os ingredientes) ou em
/// branco (itens avulsos).
class ShoppingListsPage extends ConsumerStatefulWidget {
  const ShoppingListsPage({super.key});

  @override
  ConsumerState<ShoppingListsPage> createState() => _ShoppingListsPageState();
}

class _ShoppingListsPageState extends ConsumerState<ShoppingListsPage> {
  /// Listas já deslizadas pra fora: somem da tela na hora (o `Dismissible`
  /// exige isso) enquanto o banco ainda apaga e o stream não reemitiu.
  final _removed = <String>{};

  ShoppingListRepository get _repo => ref.read(shoppingListRepositoryProvider);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final listsAsync = ref.watch(shoppingListsProvider);
    final lists = [
      for (final s in listsAsync.valueOrNull ?? const <ShoppingListSummary>[])
        if (!_removed.contains(s.list.id)) s,
    ];

    return HeaderScaffold(
      title: 'Compras',
      subtitle: lists.isEmpty
          ? null
          : _summaryLine(
              lists.length,
              lists.where((s) => !_isComplete(s)).length,
            ),
      color: TileColor.lime,
      showBack: false,
      backgroundColor: colors.ink,
      trailing: CircleIconButton(
        icon: Icons.add,
        tooltip: 'Nova lista',
        onTap: () => _openCreateSheet(context),
      ),
      body: listsAsync.when(
        loading: () => const Center(child: BrandLoader()),
        error: (_, __) => _buildMessage(context, 'Não deu para carregar.'),
        data: (_) => lists.isEmpty ? _buildEmpty(context) : _buildLists(lists),
      ),
    );
  }

  String _summaryLine(int total, int active) {
    final lists = total == 1 ? '1 lista' : '$total listas';
    if (active == 0) return '$lists · tudo comprado';
    return '$lists · $active em andamento';
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

  Widget _buildEmpty(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 56, color: colors.lime),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhuma lista ainda',
              style: context.texts.displaySmall
                  ?.copyWith(color: colors.onSaturated),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Escolha as receitas da semana e a lista sai pronta, com as '
              'quantidades já somadas.',
              style: context.texts.bodyMedium?.copyWith(
                color: colors.onSaturated.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: 'Gerar de receitas',
              icon: Icons.add_shopping_cart_outlined,
              onPressed: () => _createFromRecipes(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: 'Lista em branco',
              variant: PillButtonVariant.ghost,
              onPressed: () => _createEmpty(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLists(List<ShoppingListSummary> lists) {
    final active = [
      for (final s in lists)
        if (!_isComplete(s)) s
    ];
    final done = [
      for (final s in lists)
        if (_isComplete(s)) s
    ];
    final children = <Widget>[
      if (active.isNotEmpty) ...[
        _SectionLabel('Em andamento', count: active.length),
        for (final s in active) _buildCard(s),
      ],
      if (done.isNotEmpty) ...[
        _SectionLabel('Concluídas', count: done.length),
        for (final s in done) _buildCard(s),
      ],
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        _navBarClearance,
      ),
      children: children,
    );
  }

  Widget _buildCard(ShoppingListSummary summary) {
    final list = summary.list;
    final radius = BorderRadius.circular(AppRadii.md);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ClipRRect(
        borderRadius: radius,
        child: Dismissible(
          key: ValueKey('list-${list.id}'),
          dismissThresholds: const {
            DismissDirection.startToEnd: 0.3,
            DismissDirection.endToStart: 0.4,
          },
          background: SwipeActionBackground(
            alignment: Alignment.centerLeft,
            icon: Icons.copy_all_outlined,
            label: 'Duplicar',
            color: colors.lime,
            borderRadius: radius,
          ),
          secondaryBackground: SwipeActionBackground(
            alignment: Alignment.centerRight,
            icon: Icons.delete_outline,
            label: 'Excluir',
            color: colors.danger,
            borderRadius: radius,
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              _duplicate(list);
              return false;
            }
            return _confirmDelete(list);
          },
          onDismissed: (_) => _delete(list),
          child: _ListCard(
            summary: summary,
            onOpen: () => context.push('/shopping/${list.id}'),
            onMenu: () => _openListMenu(summary),
          ),
        ),
      ),
    );
  }

  bool _isComplete(ShoppingListSummary s) =>
      s.total > 0 && s.checked == s.total;

  /// Como criar a lista (de receitas ou em branco) e, se a pessoa tem uma casa,
  /// se ela já nasce compartilhada. A última escolha do interruptor fica
  /// guardada.
  Future<void> _openCreateSheet(BuildContext context) async {
    final hasSpace = ref.read(currentSpaceIdProvider) != null;
    final flag = ref.read(newListsSharedProvider.notifier);
    var shared = hasSpace &&
        (await ref.read(newListsSharedProvider.future).catchError((_) => false));
    if (!context.mounted) return;

    final choice =
        await showModalBottomSheet<({bool fromRecipes, bool shared})>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => StatefulBuilder(
        builder: (_, setSheet) => AppSheetFrame(
          title: 'Nova lista',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSheetOptions(
                children: [
                  AppSheetOption(
                    icon: Icons.add_shopping_cart_outlined,
                    title: 'A partir de receitas',
                    subtitle: 'Soma os ingredientes das que você escolher',
                    onTap: () => Navigator.of(sheet)
                        .pop((fromRecipes: true, shared: shared)),
                  ),
                  AppSheetOption(
                    icon: Icons.edit_note,
                    title: 'Lista em branco',
                    subtitle: 'Você adiciona os itens',
                    onTap: () => Navigator.of(sheet)
                        .pop((fromRecipes: false, shared: shared)),
                  ),
                ],
              ),
              if (hasSpace) ...[
                const SizedBox(height: AppSpacing.xs),
                _ShareNewListRow(
                  value: shared,
                  onChanged: (v) {
                    setSheet(() => shared = v);
                    flag.set(v);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice.fromRecipes) {
      await _createFromRecipes(context, shared: choice.shared);
    } else {
      await _createEmpty(context, shared: choice.shared);
    }
  }

  Future<void> _createFromRecipes(
    BuildContext context, {
    bool shared = false,
  }) async {
    final ids = await pickRecipesForShoppingList(context, ref);
    if (ids == null || ids.isEmpty) return;
    final result = await _repo.generateFromRecipes(ids);
    if (!mounted) return;
    await _openCreated(result, shared: shared);
  }

  Future<void> _createEmpty(BuildContext context, {bool shared = false}) async {
    final name = await _promptListName(
      context,
      title: 'Nova lista',
      action: 'Criar',
    );
    if (name == null) return;
    final result = await _repo.createEmpty(name: name);
    if (!mounted) return;
    await _openCreated(result, shared: shared);
  }

  Future<void> _openCreated(
    Result<ShoppingList> result, {
    bool shared = false,
  }) async {
    switch (result) {
      case Err(:final failure):
        showAppSnackBar(
          message: failure.message,
          variant: AppSnackBarVariant.error,
        );
      case Ok(:final value):
        if (shared) {
          final r = await ref
              .read(spaceControllerProvider.notifier)
              .setListShared(value.id, true);
          if (r is Err<void>) {
            showAppSnackBar(
              message: r.failure.message,
              variant: AppSnackBarVariant.error,
            );
          }
        }
        if (mounted) context.push('/shopping/${value.id}');
    }
  }

  Future<void> _openListMenu(ShoppingListSummary summary) {
    final list = summary.list;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => AppSheetFrame(
        title: list.name,
        scrollable: true,
        child: AppSheetOptions(
          children: [
            AppSheetOption(
              icon: Icons.drive_file_rename_outline,
              title: 'Renomear',
              onTap: () {
                Navigator.of(sheet).pop();
                _rename(list);
              },
            ),
            AppSheetOption(
              icon: Icons.done_all,
              title: 'Marcar todos',
              enabled: summary.checked < summary.total,
              subtitle: summary.total == 0
                  ? 'A lista está vazia'
                  : summary.checked == summary.total
                      ? 'Todos os itens já estão marcados'
                      : 'Dá a lista por concluída',
              onTap: () {
                Navigator.of(sheet).pop();
                checkAllShoppingItems(ref, list.id);
              },
            ),
            AppSheetOption(
              icon: Icons.remove_done,
              title: 'Desmarcar todos',
              enabled: summary.checked > 0,
              subtitle: summary.checked == 0
                  ? 'Nenhum item marcado'
                  : 'Deixa a lista pronta pra próxima compra',
              onTap: () {
                Navigator.of(sheet).pop();
                uncheckAllShoppingItems(ref, list.id);
              },
            ),
            AppSheetOption(
              icon: Icons.copy_all_outlined,
              title: 'Duplicar',
              subtitle: 'Mesma lista, com tudo desmarcado',
              onTap: () {
                Navigator.of(sheet).pop();
                _duplicate(list);
              },
            ),
            if (ref.read(authUserProvider).valueOrNull != null)
              AppSheetOption(
                icon: list.spaceId == null
                    ? Icons.group_add_outlined
                    : Icons.group_off_outlined,
                title: list.spaceId == null
                    ? 'Compartilhar com a casa'
                    : 'Deixar de compartilhar',
                subtitle: list.spaceId == null
                    ? 'Quem está na casa vê e marca os itens'
                    : 'Quem está na casa deixa de ver esta lista',
                onTap: () {
                  Navigator.of(sheet).pop();
                  _toggleShared(list);
                },
              ),
            AppSheetOption(
              icon: Icons.delete_outline,
              title: 'Excluir lista',
              danger: true,
              onTap: () async {
                Navigator.of(sheet).pop();
                if (await _confirmDelete(list)) _delete(list);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleShared(ShoppingList list) async {
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
    _report(await controller.setListShared(list.id, false));
  }

  Future<void> _rename(ShoppingList list) async {
    final name = await _promptListName(
      context,
      title: 'Renomear lista',
      initial: list.name,
    );
    if (name == null || name == list.name) return;
    _report(await _repo.rename(list.id, name));
  }

  Future<void> _duplicate(ShoppingList list) async {
    HapticFeedback.selectionClick();
    final result = await _repo.duplicate(list.id);
    result.when(
      ok: (copy) => showAppSnackBar(message: 'Lista duplicada: ${copy.name}'),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  Future<bool> _confirmDelete(ShoppingList list) {
    HapticFeedback.mediumImpact();
    return AppDialog.confirm(
      context,
      icon: Icons.delete_outline,
      accent: context.colors.danger,
      title: 'Excluir "${list.name}"?',
      message: 'A lista e os itens dela saem do app. Isso não dá para '
          'desfazer.',
      confirmLabel: 'Excluir',
    );
  }

  Future<void> _delete(ShoppingList list) async {
    setState(() => _removed.add(list.id));
    final result = await _repo.deleteList(list.id);
    result.when(
      ok: (_) {},
      err: (f) {
        if (mounted) setState(() => _removed.remove(list.id));
        showAppSnackBar(message: f.message, variant: AppSnackBarVariant.error);
      },
    );
  }

  void _report(Result<void> result) {
    result.when(
      ok: (_) {},
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }
}

/// Diálogo de nome de lista — serve pra criar e renomear. Devolve o texto
/// (sem espaços nas pontas; vazio só na criação, que cai no nome padrão), ou
/// nulo se cancelou.
Future<String?> _promptListName(
  BuildContext context, {
  required String title,
  String initial = '',
  String action = 'Salvar',
}) {
  final controller = TextEditingController(text: initial);
  return AppDialog.show<String>(
    context,
    icon: Icons.shopping_bag_outlined,
    accent: context.colors.lime,
    title: title,
    content: TextField(
      controller: controller,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(hintText: 'Nome da lista (opcional)'),
      onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
    ),
    actions: [
      PillButton(
        label: 'Cancelar',
        variant: PillButtonVariant.ghost,
        dense: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      PillButton(
        label: action,
        dense: true,
        onPressed: () => Navigator.of(context).pop(controller.text.trim()),
      ),
    ],
  );
}

/// "EM ANDAMENTO ———— 2": mesmo cabeçalho de seção da tela da lista.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
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
            '$count',
            style: context.texts.labelMedium?.copyWith(
              color: colors.onSaturated.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão de uma lista: anel de progresso, nome, "X de Y itens · Hoje" e
/// seta. Lista toda marcada apaga um pouco; o ⋯ abre renomear/duplicar/
/// excluir.
class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.summary,
    required this.onOpen,
    required this.onMenu,
  });

  final ShoppingListSummary summary;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  bool get _complete => summary.total > 0 && summary.checked == summary.total;

  String get _subtitle {
    final total = summary.total;
    final when = _relativeDay(summary.list.createdAt.toLocal());
    if (total == 0) return 'Vazia · $when';
    if (_complete) {
      return '$total ${total == 1 ? 'item' : 'itens'} · $when';
    }
    return '${summary.checked} de $total ${total == 1 ? 'item' : 'itens'} · '
        '$when';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.inkSoft,
      child: InkWell(
        onTap: onOpen,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _complete ? 0.6 : 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                _ProgressRing(summary: summary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.list.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleMedium
                            ?.copyWith(color: colors.onSaturated),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (summary.list.spaceId != null) ...[
                            Icon(
                              Icons.people_alt_outlined,
                              size: 14,
                              color: colors.lime,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              _subtitle,
                              style: context.texts.bodySmall?.copyWith(
                                color:
                                    colors.onSaturated.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Mais opções',
                  onPressed: onMenu,
                  icon: Icon(
                    Icons.more_horiz,
                    color: colors.onSaturated.withValues(alpha: 0.7),
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

/// "Hoje", "Ontem" ou "dd/mm".
String _relativeDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}

/// Anel de progresso do cartão: porcentagem no centro, check quando tudo foi
/// comprado, ícone de edição quando a lista ainda está vazia.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.summary});

  final ShoppingListSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = summary.total;
    final value = total == 0 ? 0.0 : summary.checked / total;
    final complete = total > 0 && summary.checked == total;

    final Widget center;
    if (total == 0) {
      center = Icon(
        Icons.edit_note,
        size: 22,
        color: colors.onSaturated.withValues(alpha: 0.5),
      );
    } else if (complete) {
      center = Icon(Icons.check, size: 22, color: colors.lime);
    } else {
      center = Text(
        '${(value * 100).round()}%',
        style: context.texts.labelMedium?.copyWith(color: colors.onSaturated),
      );
    }

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: value),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: colors.onSaturated.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(colors.lime),
              ),
            ),
          ),
          center,
        ],
      ),
    );
  }
}

/// Interruptor "Compartilhar com a casa" da folha de nova lista.
class _ShareNewListRow extends StatelessWidget {
  const _ShareNewListRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_outlined, color: colors.ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compartilhar com a casa',
                  style: context.texts.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  value
                      ? 'Quem está na casa vê e marca os itens'
                      : 'A lista fica só com você',
                  style: context.texts.bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
