import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/features/settings/controllers/library_stats.dart';
import 'package:receyta/features/settings/screens/profile_edit_sheet.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// 4ª aba da `PillNavBar` (§9.2). Sem login ainda: o perfil é local (apelido e
/// cor do avatar, só neste aparelho), seguido de "seu livro em números" e do
/// aviso de que a sincronização vem depois. Quando o login chegar, ele só
/// preenche o mesmo bloco de perfil.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemBars.onLight,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.screen,
            120,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.md),
            const _ProfileCard(),
            const SizedBox(height: AppSpacing.lg),
            const _StatsSection(),
            const SizedBox(height: AppSpacing.xs),
            const _HistoryLink(),
            const SizedBox(height: AppSpacing.lg),
            const _SyncCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text('Conta', style: context.texts.displaySmall),
        const Spacer(),
        CircleIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Configurações',
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(appSettingsProvider);
    final tile = resolveTileAppearance(colors, color: settings.profileColor);
    final name = settings.nickname;
    final initial = name.isEmpty ? null : name.characters.first.toUpperCase();

    return Semantics(
      button: true,
      label: 'Editar perfil',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Stack(
          children: [
            Positioned.fill(
              child: TilePattern(
                motif: tile.motif,
                background: tile.background,
                patternColor: tile.patternColor,
                patternColorAlt: tile.patternColorAlt,
                tile: 56,
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => showProfileEditSheet(context),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.paperSoft,
                          shape: BoxShape.circle,
                        ),
                        child: initial == null
                            ? Icon(Icons.person_outline,
                                size: 36, color: colors.ink)
                            : Text(
                                initial,
                                style: AppTextStyles.display(40)
                                    .copyWith(color: colors.ink),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Seu nome aqui' : name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.display(30)
                                  .copyWith(color: tile.onColor),
                            ),
                            const SizedBox(height: AppSpacing.xs / 2),
                            Text(
                              'Toque pra editar',
                              style: context.texts.bodyMedium
                                  ?.copyWith(color: tile.onColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_outlined, color: tile.onColor),
                    ],
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

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final stats = ref.watch(libraryStatsProvider);
    final data = stats.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            'SEU LIVRO EM NÚMEROS',
            style: context.texts.labelSmall?.copyWith(color: colors.textMuted),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _StatTile(value: data?.recipes, label: 'Receitas'),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _StatTile(value: data?.folders, label: 'Pastas'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _StatTile(value: data?.lists, label: 'Listas de compras'),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _StatTile(
                value: data?.plannedMeals,
                label: 'Refeições planejadas',
              ),
            ),
          ],
        ),
        if (data != null && data.topRecipe != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _TopRecipeCard(name: data.topRecipe!, times: data.topRecipeCount),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final int? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value == null ? '–' : '$value',
            style: AppTextStyles.display(44).copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.xs / 2),
          Text(
            label,
            style: context.texts.bodyMedium?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TopRecipeCard extends StatelessWidget {
  const _TopRecipeCard({required this.name, required this.times});

  final String name;
  final int times;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_outlined, color: colors.coral),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mais cozinhada',
                  style: context.texts.bodyMedium
                      ?.copyWith(color: colors.textMuted),
                ),
                Text(name, style: AppTextStyles.display(22)),
              ],
            ),
          ),
          Text(
            times == 1 ? '1 vez' : '$times vezes',
            style: context.texts.bodyMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLink extends StatelessWidget {
  const _HistoryLink();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paperSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () => context.push('/history'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.history, color: colors.ink),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Histórico do que você cozinhou',
                  style: context.texts.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_sync_outlined, size: 32, color: colors.lime),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sincronização em breve',
            style:
                AppTextStyles.display(26).copyWith(color: colors.onSaturated),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Login e sincronização entre aparelhos chegam mais pra frente. '
            'Por enquanto, seus dados ficam só neste aparelho — guarde uma '
            'cópia pelo backup nas Configurações.',
            style: context.texts.bodyMedium?.copyWith(
              color: colors.onSaturated.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Ver backup',
            icon: Icons.backup_outlined,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}
