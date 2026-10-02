import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/domain/engine/cook_log_filter.dart';
import 'package:receyta/domain/engine/cook_log_format.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart';
import 'package:receyta/features/recipes/controllers/cook_log_view_model.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/state_badge.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Tudo o que você cozinhou (G7), do mais recente ao mais antigo, agrupado por
/// mês, com busca, filtros e remoção (com "Desfazer"). Cada linha abre a
/// receita.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _search = TextEditingController();
  String _query = '';
  CookLogFilter _filter = CookLogFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _remove(CookLog log) async {
    final repo = ref.read(cookLogRepositoryProvider);
    await repo.remove(log.id);
    showAppSnackBar(
      message: 'Registro apagado',
      actionLabel: 'Desfazer',
      onAction: () => repo.add(
        log.recipeId,
        cookedAt: log.cookedAt,
        note: log.note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logs = ref.watch(allCookLogsProvider);
    final all = logs.valueOrNull ?? const <CookLog>[];

    return Scaffold(
      backgroundColor: colors.paper,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemBars.onDark,
        child: Column(
          children: [
            _Header(
                total: all.length,
                recipes: {for (final l in all) l.recipeId}.length),
            Expanded(
              child: logs.when(
                loading: () => const Center(child: BrandLoader()),
                error: (_, __) => _message(
                  context,
                  icon: Icons.priority_high_rounded,
                  background: colors.danger,
                  foreground: colors.onSaturated,
                  title: 'Não deu para carregar o histórico',
                ),
                data: (items) => items.isEmpty
                    ? _message(
                        context,
                        icon: Icons.restaurant_outlined,
                        background: colors.ink,
                        foreground: colors.lime,
                        title: 'Nada cozinhado ainda',
                        body: 'Toque em "Cozinhei!" no modo cozinha, ou '
                            'registre pelo cartão "Cozinhei" de qualquer '
                            'receita.',
                      )
                    : _buildBody(context, items),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required Color background,
    required Color foreground,
    required String title,
    String? body,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateBadge(
              icon: icon,
              background: background,
              foreground: foreground,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: context.texts.displaySmall,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: context.texts.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<CookLog> items) {
    final colors = context.colors;
    final now = DateTime.now();
    final shown = filterCookLogs(
      items,
      query: _query,
      filter: _filter,
      now: now,
    );

    final children = <Widget>[];
    String? month;
    for (final log in shown) {
      final label = formatMonthYear(log.cookedAt);
      if (label != month) {
        month = label;
        children.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Text(label, style: AppTextStyles.display(30)),
          ),
        );
      }
      children.add(
        _HistoryRow(log: log, now: now, onRemove: () => _remove(log)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xs,
          ),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Buscar por receita ou nota',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            children: [
              for (final f in CookLogFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Center(
                    child: ChoicePill(
                      label: f.label,
                      selected: f == _filter,
                      onTap: () => setState(() => _filter = f),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Nada com esse filtro.',
                      style: context.texts.bodyLarge
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.xs,
                    AppSpacing.screen,
                    AppSpacing.xl,
                  ),
                  children: children,
                ),
        ),
      ],
    );
  }
}

/// Cabeçalho roxo (a cor da agenda), com a textura de meias-luas, no mesmo
/// desenho do das configurações.
class _Header extends StatelessWidget {
  const _Header({required this.total, required this.recipes});

  final int total;
  final int recipes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.lg),
      ),
      child: Container(
        width: double.infinity,
        color: colors.violet,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: SizedBox(
                width: 240,
                height: 240,
                child: TilePattern(
                  motif: TileMotif.meiaLua,
                  background: colors.violet,
                  patternColor: colors.violetPattern,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Voltar',
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      total == 0
                          ? 'HISTÓRICO'
                          : '$total ${total == 1 ? 'VEZ' : 'VEZES'} · '
                              '$recipes ${recipes == 1 ? 'RECEITA' : 'RECEITAS'}',
                      style: context.texts.labelSmall
                          ?.copyWith(color: colors.violetMuted),
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      'O que você cozinhou',
                      style: AppTextStyles.display(38)
                          .copyWith(color: colors.onSaturated),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.log,
    required this.now,
    required this.onRemove,
  });

  final CookLog log;
  final DateTime now;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final day = log.cookedAt.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => context.push('/recipe/${log.recipeId}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    children: [
                      Text('${day.day}', style: AppTextStyles.display(34)),
                      Text(
                        formatCookedDate(day, now)
                            .split(',')
                            .first
                            .toUpperCase(),
                        style: context.texts.labelSmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.recipeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (log.hasNote)
                        Text(log.note!, style: context.texts.bodyMedium),
                      Text(
                        cookedAgo(log.cookedAt, now),
                        style: context.texts.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Apagar do histórico',
                  icon: Icon(Icons.delete_outline, color: colors.textMuted),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
