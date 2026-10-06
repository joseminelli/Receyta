import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/format_bytes.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';
import 'package:receyta/data/sync/sync_coordinator.dart';
import 'package:receyta/domain/engine/sync_status_text.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/features/settings/controllers/library_stats.dart';
import 'package:receyta/features/settings/controllers/profile_preview.dart';
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
    final color = ref.watch(effectiveProfileColorProvider);
    final tile = resolveTileAppearance(colors, color: color);
    final lightHero = tile.background.computeLuminance() > 0.6;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightHero ? SystemBars.onLight : SystemBars.onDark,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: const [
          _Hero(),
          _SyncStatusTile(),
          _PhotoQuotaTile(),
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
    final tile = resolveTileAppearance(
      colors,
      color: ref.watch(effectiveProfileColorProvider),
    );
    final stats = ref.watch(libraryStatsProvider).valueOrNull;
    final auth = ref.watch(authUserProvider);
    final user = auth.valueOrNull;
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
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
                // Troca de cor/textura em fusão suave, não de uma vez.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: TilePattern(
                    key: ValueKey((tile.background, tile.motif)),
                    motif: tile.motif,
                    background: tile.background,
                    patternColor: tile.patternColor,
                    patternColorAlt: tile.patternColorAlt,
                    tile: 64,
                  ),
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
                        child: _LoginReveal(
                          trigger: user?.id,
                          ready: auth.hasValue,
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
      frameBuilder: (_, child, frame, syncLoaded) {
        if (syncLoaded) return child;
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Center(child: fallback),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              child: child,
            ),
          ],
        );
      },
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

/// Entrada com "bounce" do nome e da foto quando a pessoa **acaba de entrar na
/// conta**: escala elástica com um respiro de fade. Só dispara na troca de
/// "sem conta" pra "com conta" depois que o estado já tinha carregado — abrir
/// a aba com a conta já conectada não anima (senão toda visita pulava).
class _LoginReveal extends StatefulWidget {
  const _LoginReveal({
    required this.trigger,
    required this.ready,
    required this.child,
  });

  /// Identifica quem está logado; `null` = ninguém.
  final String? trigger;

  /// O estado de login já foi lido (não é o primeiro quadro de carregamento).
  final bool ready;
  final Widget child;

  @override
  State<_LoginReveal> createState() => _LoginRevealState();
}

class _LoginRevealState extends State<_LoginReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.55, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.35, curve: Curves.easeOut),
  );

  @override
  void didUpdateWidget(covariant _LoginReveal old) {
    super.didUpdateWidget(old);
    final justLoggedIn = old.ready &&
        widget.ready &&
        old.trigger == null &&
        widget.trigger != null;
    if (justLoggedIn) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.centerLeft,
        child: widget.child,
      ),
    );
  }
}

/// Estado do sync com a conta, logo abaixo do perfil: "Sincronizado · há 2
/// min", "Sincronizando…" ou a falha, com o botão de sincronizar agora. Só
/// aparece com conta conectada.
class _SyncStatusTile extends ConsumerStatefulWidget {
  const _SyncStatusTile();

  @override
  ConsumerState<_SyncStatusTile> createState() => _SyncStatusTileState();
}

class _SyncStatusTileState extends ConsumerState<_SyncStatusTile> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // O "há N min" envelhece sozinho.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncCoordinatorProvider);
    if (!sync.enabled) return const SizedBox.shrink();

    final colors = context.colors;
    final now = ref.watch(syncClockProvider)();
    final syncing = sync.phase == SyncPhase.syncing;
    final failed = sync.phase == SyncPhase.error;
    final last = sync.lastSyncAt;

    final text = syncing
        ? 'Sincronizando…'
        : failed
            ? 'Sem conexão. Tentamos de novo sozinhos.'
            : last == null
                ? 'Aguardando a primeira sincronização'
                : 'Sincronizado · ${formatSyncAgo(last, now)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        0,
      ),
      child: Semantics(
        container: true,
        label: text,
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: syncing
                  ? const CircularProgressIndicator(strokeWidth: 2.5)
                  : Icon(
                      failed
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                      size: 22,
                      color: failed ? colors.danger : colors.textMuted,
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: context.texts.bodyMedium?.copyWith(
                  color: failed ? colors.danger : colors.textMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: syncing
                  ? null
                  : () => ref
                      .read(syncCoordinatorProvider.notifier)
                      .requestSync(immediate: true),
              child: const Text('Sincronizar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Fotos na nuvem · 12 MB de 30 MB", com uma barra. Perto do teto avisa; no
/// teto explica que as fotos novas ficam só neste aparelho (e quantas esperam).
/// Some quando não há conta ou o servidor não informa o uso.
class _PhotoQuotaTile extends ConsumerWidget {
  const _PhotoQuotaTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(syncCoordinatorProvider.select((s) => s.enabled));
    if (!enabled) return const SizedBox.shrink();
    final quota = ref.watch(photoQuotaProvider).valueOrNull;
    if (quota == null) return const SizedBox.shrink();

    final colors = context.colors;
    final full = quota.blocked;
    final accent = full ? colors.danger : colors.ink;
    final detail = full
        ? 'Limite atingido. As fotos novas ficam só neste aparelho'
            '${quota.pending > 0 ? ' (${quota.pending} esperando)' : ''}. '
            'Apague fotos de receitas que não usa mais para liberar espaço.'
        : quota.nearLimit
            ? 'Quase no limite. Apague fotos de receitas que não usa mais '
                'para abrir espaço.'
            : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        0,
      ),
      child: Semantics(
        container: true,
        label: 'Fotos na nuvem: ${formatBytes(quota.usedBytes)} de '
            '${formatBytes(quota.quotaBytes)}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined,
                    size: 22, color: full ? colors.danger : colors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Fotos na nuvem',
                    style: context.texts.bodyMedium
                        ?.copyWith(color: colors.textMuted),
                  ),
                ),
                Text(
                  '${formatBytes(quota.usedBytes)} de '
                  '${formatBytes(quota.quotaBytes)}',
                  style: context.texts.bodyMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: quota.fraction,
                minHeight: 8,
                backgroundColor: colors.paperSoft,
                color: accent,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail,
                style: context.texts.bodySmall?.copyWith(
                  color: full ? colors.danger : colors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
