import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/data/services/retro_export_service.dart';
import 'package:receyta/domain/engine/retrospective.dart';
import 'package:receyta/features/recipes/controllers/retrospective_view_model.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/state_badge.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// "Seu mês / seu ano na cozinha": o resumo do que você cozinhou, com seletor
/// de período e um botão que compartilha tudo como imagem.
class RetrospectivePage extends ConsumerStatefulWidget {
  const RetrospectivePage({super.key, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  ConsumerState<RetrospectivePage> createState() => _RetrospectivePageState();
}

class _RetrospectivePageState extends ConsumerState<RetrospectivePage> {
  late RetroPeriod _period = RetroPeriod.monthOf(widget._clock());

  bool get _canGoForward => _period.shift(1).start.isBefore(widget._clock());

  void _setKind(RetroKind kind) {
    if (kind == _period.kind) return;
    final now = widget._clock();
    setState(() {
      if (kind == RetroKind.year) {
        _period = RetroPeriod.yearOf(_period.start);
      } else {
        // Ano de volta pra mês: o mês atual se for este ano, senão dezembro.
        _period = _period.start.year == now.year
            ? RetroPeriod.monthOf(now)
            : RetroPeriod.monthOf(DateTime(_period.start.year, 12));
      }
    });
  }

  Future<void> _share(Retrospective retro) async {
    final result = await ref.read(retroExportServiceProvider).share(retro);
    result.when(
      ok: (_) {},
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final retro = ref.watch(retrospectiveProvider(_period));
    final data = retro.valueOrNull;

    return HeaderScaffold(
      title: 'Retrospectiva',
      subtitle: _period.label,
      color: TileColor.coral,
      trailing: CircleIconButton(
        icon: Icons.ios_share,
        tooltip: 'Compartilhar imagem',
        onTap: data == null || data.isEmpty ? null : () => _share(data),
      ),
      body: Column(
        children: [
          _PeriodBar(
            period: _period,
            canGoForward: _canGoForward,
            onKind: _setKind,
            onPrev: () => setState(() => _period = _period.shift(-1)),
            onNext: _canGoForward
                ? () => setState(() => _period = _period.shift(1))
                : null,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_period),
                child: retro.when(
                  loading: () => const Center(child: BrandLoader()),
                  error: (_, __) => const _Message(
                    icon: Icons.priority_high_rounded,
                    title: 'Não deu para montar a retrospectiva',
                  ),
                  data: (r) => r.isEmpty
                      ? _Message(
                          icon: Icons.restaurant_outlined,
                          title: 'Nada cozinhado em ${_period.inSentence}',
                          body: 'Marque "Cozinhei!" nas receitas que fizer e '
                              'elas entram aqui.',
                        )
                      : _Content(retro: r, onShare: () => _share(r)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seletor Mês/Ano e as setas pra navegar entre períodos.
class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.period,
    required this.canGoForward,
    required this.onKind,
    required this.onPrev,
    required this.onNext,
  });

  final RetroPeriod period;
  final bool canGoForward;
  final ValueChanged<RetroKind> onKind;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          for (final kind in RetroKind.values) ...[
            PillButton(
              label: kind == RetroKind.month ? 'Mês' : 'Ano',
              variant: kind == period.kind
                  ? PillButtonVariant.primary
                  : PillButtonVariant.secondary,
              dense: true,
              onPressed: () => onKind(kind),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Spacer(),
          IconButton(
            tooltip: 'Período anterior',
            onPressed: onPrev,
            icon: Icon(Icons.chevron_left_rounded, color: colors.ink),
          ),
          IconButton(
            tooltip: 'Próximo período',
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: canGoForward ? colors.ink : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.retro, required this.onShare});

  final Retrospective retro;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final r = retro;
    final stats = <(IconData, String, String)>[
      (
        Icons.timer_outlined,
        'No fogão',
        r.totalMinutes > 0 ? formatCookingTime(r.totalMinutes) : '—',
      ),
      (
        Icons.menu_book_outlined,
        r.distinctRecipes == 1 ? 'Receita diferente' : 'Receitas diferentes',
        '${r.distinctRecipes}',
      ),
      (
        Icons.local_fire_department_outlined,
        'Maior sequência',
        r.bestStreak == 1 ? '1 dia' : '${r.bestStreak} dias',
      ),
      (
        Icons.event_outlined,
        'Dia favorito',
        r.busiestWeekday == null ? '—' : retroWeekdayName(r.busiestWeekday!),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      children: [
        _Entrance(index: 0, child: _BigNumber(retro: r)),
        const SizedBox(height: AppSpacing.sm),
        _Entrance(
          index: 1,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.45,
            children: [
              for (final (icon, label, value) in stats)
                _StatTile(icon: icon, label: label, value: value),
            ],
          ),
        ),
        if (r.topRecipe != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _Entrance(index: 2, child: _TopRecipeCard(retro: r)),
        ],
        const SizedBox(height: AppSpacing.sm),
        _Entrance(index: 3, child: _Extras(retro: r)),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: 'Compartilhar imagem',
          icon: Icons.ios_share,
          onPressed: onShare,
        ),
      ],
    );
  }
}

/// Fade + subida leve, cada bloco um pouco depois do anterior.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 110),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 22),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// O número grande: quantas vezes você cozinhou.
class _BigNumber extends StatelessWidget {
  const _BigNumber({required this.retro});

  final Retrospective retro;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final n = retro.cookCount;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$n',
            style: AppTextStyles.display(96).copyWith(
              color: colors.lime,
              height: 0.95,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              n == 1
                  ? 'vez que você cozinhou em ${retro.period.inSentence}'
                  : 'vezes que você cozinhou em ${retro.period.inSentence}',
              style: context.texts.titleMedium?.copyWith(
                color: colors.onSaturated,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: context.texts.labelLarge
                      ?.copyWith(color: colors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.display(38).copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// A receita campeã, no azulejo dela. Toque abre a receita.
class _TopRecipeCard extends StatelessWidget {
  const _TopRecipeCard({required this.retro});

  final Retrospective retro;

  @override
  Widget build(BuildContext context) {
    final top = retro.topRecipe!;
    final tile = resolveTileAppearance(
      context.colors,
      color: top.tileColor,
      motif: top.tileMotif,
      seedId: top.id,
    );
    final on = tile.onColor;
    return Material(
      color: tile.background,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/recipe/${top.id}'),
        child: Stack(
          children: [
            Positioned.fill(
              child: TilePattern(
                motif: tile.motif,
                background: tile.background,
                patternColor: tile.patternColor,
                patternColorAlt: tile.patternColorAlt,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECEITA CAMPEÃ',
                    style: context.texts.labelSmall?.copyWith(color: on),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    top.name,
                    style: AppTextStyles.display(32)
                        .copyWith(color: on, height: 1.05),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    top.times == 1 ? 'feita 1 vez' : 'feita ${top.times} vezes',
                    style: context.texts.bodyLarge
                        ?.copyWith(color: on.withValues(alpha: 0.92)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tag favorita e receitas novas do período, em linhas curtas.
class _Extras extends StatelessWidget {
  const _Extras({required this.retro});

  final Retrospective retro;

  @override
  Widget build(BuildContext context) {
    final lines = <(IconData, String)>[
      if (retro.topTag != null)
        (
          Icons.sell_outlined,
          'Tag favorita: ${retro.topTag!.name} (${retro.topTag!.times}×)',
        ),
      if (retro.newRecipes > 0)
        (
          Icons.add_circle_outline,
          retro.newRecipes == 1
              ? '1 receita nova salva'
              : '${retro.newRecipes} receitas novas salvas',
        ),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Column(
      children: [
        for (final (icon, text) in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(text, style: context.texts.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateBadge(
              icon: icon,
              background: colors.ink,
              foreground: colors.lime,
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
                body!,
                style: context.texts.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
