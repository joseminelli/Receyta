import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart';
import 'package:receyta/features/recipes/controllers/recipe_status_view_model.dart';
import 'package:receyta/features/shopping/screens/add_to_shopping_list_flow.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';
import 'package:receyta/widgets/app_sheet.dart';

/// Altura fixa dos dois cartões: baixa o bastante pra não empurrar os
/// ingredientes pra longe.
const _cardHeight = 64.0;

/// Dois cartões lado a lado no detalhe da receita: se ela está em alguma lista
/// de compras e se está agendada. Compactos e de uma linha só de texto, pra
/// não atrapalhar a leitura de ingredientes e preparo. Cada um é um atalho:
/// ativo, leva à lista ou ao dia; vazio, convida a adicionar.
class RecipeStatusCards extends ConsumerWidget {
  const RecipeStatusCards({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(recipeShoppingListsProvider(recipeId));
    final plan = ref.watch(
      recipeUpcomingPlanProvider((recipeId: recipeId, from: today())),
    );

    // Enquanto os dois não chegam, reserva o espaço (sem piscar "fora da
    // lista" por um quadro).
    if (!lists.hasValue || !plan.hasValue) {
      return const SizedBox(height: _cardHeight);
    }

    return Row(
      children: [
        Expanded(
          child: _ShoppingCard(
            recipeId: recipeId,
            lists: lists.requireValue,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _PlanCard(
            recipeId: recipeId,
            upcoming: plan.requireValue,
          ),
        ),
      ],
    );
  }
}

class _ShoppingCard extends ConsumerWidget {
  const _ShoppingCard({required this.recipeId, required this.lists});

  final String recipeId;
  final List<ShoppingList> lists;

  Future<void> _chooseList(BuildContext context) async {
    final picked = await showModalBottomSheet<ShoppingList>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => AppSheetFrame(
        title: 'Em qual lista?',
        scrollable: true,
        child: AppSheetOptions(
          children: [
            for (final l in lists)
              AppSheetOption(
                icon: Icons.shopping_bag_outlined,
                title: l.name,
                onTap: () => Navigator.of(sheet).pop(l),
              ),
          ],
        ),
      ),
    );
    if (picked != null && context.mounted) {
      context.push('/shopping/${picked.id}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = lists.isNotEmpty;
    final String value;
    final String sub;
    final VoidCallback onTap;
    if (!active) {
      value = 'Fora da lista';
      sub = 'Toque pra adicionar';
      onTap = () => addRecipeToShoppingListFlow(context, ref, recipeId);
    } else if (lists.length == 1) {
      value = 'Na lista';
      sub = lists.single.name;
      onTap = () => context.push('/shopping/${lists.single.id}');
    } else {
      value = 'Em ${lists.length} listas';
      sub = lists.map((l) => l.name).join(', ');
      onTap = () => _chooseList(context);
    }
    return _StatusCard(
      label: 'Lista de compras',
      icon: active ? Icons.shopping_bag : Icons.add_shopping_cart_outlined,
      color: TileColor.coral,
      motif: TileMotif.ponto,
      active: active,
      value: value,
      sub: sub,
      onTap: onTap,
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.recipeId, required this.upcoming});

  final String recipeId;
  final List<MealPlanEntry> upcoming;

  Future<void> _schedule(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final slot = await pickMealSlot(
      context,
      title: 'Agendar receita',
      confirmLabel: 'Agendar',
      weekStart: mondayOf(today()),
      initialDay: today(),
      initialMeal: MealType.lunch,
    );
    if (slot == null) return;
    final result = await ref
        .read(mealPlanRepositoryProvider)
        .add(recipeId, slot.day, slot.meal);
    result.when(
      ok: (_) => showAppSnackBar(
        message: 'Agendada: ${relativeDayLabel(slot.day).toLowerCase()} '
            '(${slot.meal.label})',
        actionLabel: 'Ver dia',
        onAction: () => router.push('/planner/day/${dayToParam(slot.day)}'),
      ),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = upcoming.isEmpty ? null : upcoming.first;
    if (next == null) {
      return _StatusCard(
        label: 'Agenda',
        icon: Icons.event_outlined,
        color: TileColor.violet,
        motif: TileMotif.meiaLua,
        active: false,
        value: 'Sem data',
        sub: 'Toque pra agendar',
        onTap: () => _schedule(context, ref),
      );
    }
    final more = upcoming.length - 1;
    return _StatusCard(
      label: 'Agenda',
      icon: Icons.event_available,
      color: TileColor.violet,
      motif: TileMotif.meiaLua,
      active: true,
      value: relativeDayLabel(next.date),
      sub: more > 0
          ? '${next.mealType.label} · +$more ${more == 1 ? 'data' : 'datas'}'
          : next.mealType.label,
      onTap: () => context.push('/planner/day/${dayToParam(next.date)}'),
    );
  }
}

/// Cartão de status. Ativo, é um bloco da cor da seção (coral = compras, violeta
/// = agenda) com a textura da identidade num canto, como os azulejos do app;
/// vazio, fica neutro (`paperSoft`) com o ícone só em contorno — assim o que já
/// está "resolvido" se destaca e o que falta não grita.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.motif,
    required this.active,
    required this.value,
    required this.sub,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final TileColor color;
  final TileMotif motif;
  final bool active;
  final String value;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = resolveTileAppearance(colors, color: color, motif: motif);
    final textColor = active ? tile.onColor : colors.textMuted;
    final valueColor = active ? tile.onColor : colors.ink;

    return Semantics(
      button: true,
      label: '$label: $value, $sub',
      excludeSemantics: true,
      child: Material(
        color: active ? tile.background : colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _cardHeight,
            child: Stack(
              children: [
                if (active)
                  Positioned(
                    top: -18,
                    right: -18,
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: TilePattern(
                        motif: tile.motif,
                        background: tile.background,
                        patternColor: tile.patternColor,
                        patternColorAlt: tile.patternColorAlt,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _buildIcon(colors, tile),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.labelSmall?.copyWith(
                                color: textColor.withValues(
                                  alpha: active ? 0.85 : 1,
                                ),
                              ),
                            ),
                            Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.bodyMedium?.copyWith(
                                fontWeight:
                                    active ? FontWeight.w800 : FontWeight.w600,
                                color: valueColor,
                              ),
                            ),
                            Text(
                              sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.bodySmall?.copyWith(
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ativo: bolinha `paper` com o ícone em `ink` sobre o bloco colorido.
  /// Vazio: só o contorno, em cinza.
  Widget _buildIcon(
    AppColors colors,
    TileAppearance tile,
  ) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? colors.paper : Colors.transparent,
        border: active ? null : Border.all(color: colors.textMuted, width: 1.5),
      ),
      child: Icon(
        icon,
        size: 17,
        color: active ? colors.ink : colors.textMuted,
      ),
    );
  }
}
