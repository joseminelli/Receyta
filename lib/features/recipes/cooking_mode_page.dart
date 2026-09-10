import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/features/recipes/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';

/// Modo cozinha mínimo (RF-01.11 / G1 parcial): superfície escura reaproveitada
/// de Compras, tela que não apaga (wakelock), passos numa lista de corpo grande
/// que você rola com a mão suja, ingredientes num toque no topo. Timers e
/// escala de porção ficam pro G1 completo.
class CookingModePage extends ConsumerStatefulWidget {
  const CookingModePage({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<CookingModePage> createState() => _CookingModePageState();
}

class _CookingModePageState extends ConsumerState<CookingModePage> {
  final _done = <int>{};
  bool _ingredientsOpen = true;

  @override
  void initState() {
    super.initState();
    _setWakelock(true);
  }

  @override
  void dispose() {
    _setWakelock(false);
    super.dispose();
  }

  /// O plugin não existe em teste nem na web — falha silenciosa é aceitável,
  /// manter a tela ligada é conveniência, não correção.
  Future<void> _setWakelock(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.ink,
      body: ref.watch(recipeDetailProvider(widget.recipeId)).when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const _Message(text: 'Receita não encontrada'),
            data: (detail) {
              if (detail == null) {
                return const _Message(text: 'Receita não encontrada');
              }
              return SafeArea(
                child: Column(
                  children: [
                    _TopBar(name: detail.recipe.name),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          AppSpacing.xs,
                          AppSpacing.screen,
                          AppSpacing.xxl,
                        ),
                        children: [
                          _IngredientsCard(
                            ingredients: detail.ingredients,
                            open: _ingredientsOpen,
                            onToggle: () => setState(
                              () => _ingredientsOpen = !_ingredientsOpen,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _SectionLabel('Preparo'),
                          const SizedBox(height: AppSpacing.md),
                          if (detail.steps.isEmpty)
                            Text(
                              'Esta receita não tem passos.',
                              style: context.texts.bodyLarge
                                  ?.copyWith(color: colors.textBody),
                            )
                          else
                            for (var i = 0; i < detail.steps.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _StepCard(
                                  number: i + 1,
                                  text: detail.steps[i].text,
                                  done: _done.contains(i),
                                  onTap: () => setState(() {
                                    _done.contains(i)
                                        ? _done.remove(i)
                                        : _done.add(i);
                                  }),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
            color: colors.onSaturated,
            tooltip: 'Sair',
          ),
          Expanded(
            child: Text(
              name,
              style: context.texts.titleMedium
                  ?.copyWith(color: colors.onSaturated),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.lightbulb_outline,
              size: 16, color: colors.lime.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

/// Ingredientes no topo, recolhíveis: abertos por padrão, um toque some com
/// eles quando você já separou tudo.
class _IngredientsCard extends StatelessWidget {
  const _IngredientsCard({
    required this.ingredients,
    required this.open,
    required this.onToggle,
  });

  final List<RecipeIngredient> ingredients;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.inkSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    'INGREDIENTES',
                    style: context.texts.labelSmall
                        ?.copyWith(color: colors.lime),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${ingredients.length}',
                    style: context.texts.labelSmall?.copyWith(
                      color: colors.onSaturated.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    color: colors.onSaturated.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ingredients.isEmpty)
                    Text(
                      'Nenhum ingrediente cadastrado.',
                      style: context.texts.bodyMedium
                          ?.copyWith(color: colors.textBody),
                    )
                  else
                    for (final i in ingredients)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          i.rawText,
                          style: context.texts.bodyLarge?.copyWith(
                            color: colors.onSaturated,
                            height: 1.35,
                          ),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.texts.labelSmall?.copyWith(color: context.colors.lime),
    );
  }
}

/// Passo em cartão largo, número em escala grande. Toque marca como feito —
/// o cartão recua e o texto risca, pra achar onde parou de relance.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.text,
    required this.done,
    required this.onTap,
  });

  final int number;
  final String text;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: done ? colors.ink : colors.inkSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  '$number'.padLeft(2, '0'),
                  style: AppTextStyles.display(40).copyWith(
                    color: done
                        ? colors.onSaturated.withValues(alpha: 0.25)
                        : colors.lime,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                  child: Text(
                    text,
                    style: context.texts.bodyLarge?.copyWith(
                      color: done
                          ? colors.onSaturated.withValues(alpha: 0.4)
                          : colors.onSaturated,
                      fontSize: 20,
                      height: 1.4,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: context.texts.bodyLarge
              ?.copyWith(color: context.colors.onSaturated),
        ),
      ),
    );
  }
}
