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
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// 4ª aba da `PillNavBar` (§9.2). Sem login ainda: o perfil é local (apelido e
/// cor, só neste aparelho). Um bloco grande no topo, com a cor e a textura
/// escolhidas, leva o nome e os números do seu livro; abaixo, os atalhos de
/// manutenção (histórico, tags, ingredientes, lixeira) em lista aberta, sem
/// cartões. Quando o login chegar, ele só preenche o mesmo bloco.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(appSettingsProvider);
    final tile = resolveTileAppearance(colors, color: settings.profileColor);
    final lightHero = tile.background.computeLuminance() > 0.6;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightHero ? SystemBars.onLight : SystemBars.onDark,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: const [
          _Hero(),
          SizedBox(height: AppSpacing.lg),
          _Shortcuts(),
          SizedBox(height: AppSpacing.lg),
          _SyncNote(),
        ],
      ),
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(appSettingsProvider);
    final tile = resolveTileAppearance(colors, color: settings.profileColor);
    final stats = ref.watch(libraryStatsProvider).valueOrNull;
    final name = settings.nickname;
    final initial = name.isEmpty ? null : name.characters.first.toUpperCase();
    final onColor = tile.onColor;

    String number(int? v) => v == null ? '–' : '$v';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.lg + 10),
      ),
      child: Container(
        width: double.infinity,
        color: tile.background,
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: SizedBox(
                width: 300,
                height: 300,
                child: TilePattern(
                  motif: tile.motif,
                  background: tile.background,
                  patternColor: tile.patternColor,
                  patternColorAlt: tile.patternColorAlt,
                  tile: 64,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.screen,
                  AppSpacing.screen,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CONTA',
                          style: context.texts.bodyMedium
                              ?.copyWith(color: onColor),
                        ),
                        const Spacer(),
                        CircleIconButton(
                          icon: Icons.settings_outlined,
                          tooltip: 'Configurações',
                          onTap: () => context.push('/settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      button: true,
                      label: 'Editar perfil',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        onTap: () => showProfileEditSheet(context),
                        child: Row(
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colors.paper,
                                shape: BoxShape.circle,
                              ),
                              child: initial == null
                                  ? Icon(Icons.person_outline,
                                      size: 42, color: colors.ink)
                                  : Text(
                                      initial,
                                      style: AppTextStyles.display(52)
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
                                    style: AppTextStyles.display(44)
                                        .copyWith(color: onColor),
                                  ),
                                  const SizedBox(height: AppSpacing.xs / 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Toque pra editar',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.texts.bodyMedium
                                              ?.copyWith(color: onColor),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.edit_outlined,
                                          size: 16, color: onColor),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        _Stat(
                          value: number(stats?.recipes),
                          label: 'Receitas',
                          color: onColor,
                        ),
                        _StatDivider(color: onColor),
                        _Stat(
                          value: number(stats?.folders),
                          label: 'Pastas',
                          color: onColor,
                        ),
                        _StatDivider(color: onColor),
                        _Stat(
                          value: number(stats?.lists),
                          label: 'Listas',
                          color: onColor,
                        ),
                        _StatDivider(color: onColor),
                        _Stat(
                          value: number(stats?.plannedMeals),
                          label: 'Refeições',
                          color: onColor,
                        ),
                      ],
                    ),
                    if (stats?.topRecipe != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _TopRecipePill(
                        name: stats!.topRecipe!,
                        times: stats.topRecipeCount,
                      ),
                    ],
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.display(54).copyWith(color: color),
            ),
          ),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.5,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: color.withValues(alpha: 0.35),
    );
  }
}

class _TopRecipePill extends StatelessWidget {
  const _TopRecipePill({required this.name, required this.times});

  final String name;
  final int times;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: 20, color: colors.coral),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Mais cozinhada · $name · '
              '${times == 1 ? '1 vez' : '$times vezes'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodyMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Atalhos de manutenção do livro numa lista aberta: títulos grandes na
/// fonte de display, separados por um fio, sem cartões.
class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  static const _rows = [
    (Icons.history, 'Histórico', 'Tudo o que você já cozinhou', '/history'),
    (Icons.sell_outlined, 'Tags', 'Organize e renomeie', '/tags'),
    (
      Icons.kitchen_outlined,
      'Despensa',
      'O que você sempre tem fica fora das compras',
      '/ingredients?despensa=1'
    ),
    (
      Icons.egg_alt_outlined,
      'Ingredientes',
      'Mescle duplicados, apague os sem uso',
      '/ingredients'
    ),
    (
      Icons.delete_outline,
      'Lixeira',
      'Receitas apagadas, por tempo limitado',
      '/trash'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEU LIVRO',
            style: context.texts.labelSmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1.5, color: colors.paperSoft),
            InkWell(
              onTap: () => context.push(_rows[i].$4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 84),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_rows[i].$1, size: 22, color: colors.lime),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _rows[i].$2,
                            style: AppTextStyles.display(25),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _rows[i].$3,
                            style: context.texts.bodyMedium
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: colors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aviso de que o login e a sincronização ainda vêm, em texto simples.
class _SyncNote extends StatelessWidget {
  const _SyncNote();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_sync_outlined, color: colors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sincronização em breve',
                  style: context.texts.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Login e sincronização entre aparelhos chegam mais pra '
                  'frente. Por enquanto, seus dados ficam só neste aparelho.',
                  style: context.texts.bodyMedium
                      ?.copyWith(color: colors.textMuted),
                ),
                TextButton(
                  onPressed: () => context.push('/settings'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('Fazer backup nas configurações'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
