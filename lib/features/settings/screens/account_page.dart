import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/features/settings/controllers/library_stats.dart';
import 'package:receyta/features/settings/screens/profile_edit_sheet.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/google_g_mark.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// 4ª aba da `PillNavBar` (§9.2). O login com Google é opcional: sem ele o
/// perfil é local (apelido e cor, só neste aparelho); com ele, o nome e a foto
/// do Google preenchem o bloco. Um bloco grande no topo, com a cor e a textura
/// escolhidas, leva o nome e os números do seu livro; abaixo, os atalhos de
/// manutenção (histórico, tags, ingredientes, lixeira) em lista aberta, sem
/// cartões.
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
    final user = ref.watch(authUserProvider).valueOrNull;
    final name = settings.nickname.isNotEmpty
        ? settings.nickname
        : (user?.name?.split(' ').first ?? '');
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
                              clipBehavior: Clip.antiAlias,
                              child: _Avatar(
                                url: user?.avatarUrl,
                                initial: initial,
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
                    if (user == null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _GoogleSignInButton(onColor: onColor),
                    ],
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.initial});

  final String? url;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fallback = initial == null
        ? Icon(Icons.person_outline, size: 42, color: colors.ink)
        : Text(
            initial!,
            style: AppTextStyles.display(52).copyWith(color: colors.ink),
          );
    if (url == null) return fallback;
    return Image.network(
      url!,
      width: 92,
      height: 92,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}

/// Entrar com o Google, no alto do perfil: pílula `paper` cheia sobre o bloco
/// colorido (fundo sempre paper, nunca uma cor de acento — só o texto leva
/// `ink`), com a letra num medalhão. Some quando já há conta conectada; sair
/// fica nas Configurações. O login é opcional — a linha embaixo diz isso.
class _GoogleSignInButton extends ConsumerWidget {
  const _GoogleSignInButton({required this.onColor});

  final Color onColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final busy = ref.watch(authControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Entrar com Google',
          child: Material(
            color: colors.paper,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: busy ? null : () => _signIn(context, ref),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.paper,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.paperSoft,
                            width: 1.5,
                          ),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const GoogleGMark(size: 24),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          busy ? 'Entrando…' : 'Entrar com Google',
                          style: context.texts.titleMedium?.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: colors.ink),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Opcional · guarda as fotos das suas receitas na nuvem',
          style: context.texts.bodySmall
              ?.copyWith(color: onColor.withValues(alpha: 0.85)),
        ),
      ],
    );
  }

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    final failure = await ref.read(authControllerProvider.notifier).signIn();
    if (failure == null || !context.mounted) return;
    AppSnackBar.show(
      context,
      message: failure.message,
      variant: AppSnackBarVariant.error,
    );
  }
}
