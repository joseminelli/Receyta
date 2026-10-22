import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/format_bytes.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';
import 'package:receyta/data/sync/sync_coordinator.dart';
import 'package:receyta/domain/engine/sync_status_text.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';

/// Última rodada que deu certo, mesmo com o sync pausado (o coordenador zera o
/// estado quando o acesso acaba; o instante fica guardado no aparelho).
final lastSyncProvider = FutureProvider.autoDispose<DateTime?>((ref) async {
  ref.watch(syncCoordinatorProvider.select((s) => s.lastSyncAt));
  final prefs = await SharedPreferences.getInstance();
  return DateTime.tryParse(prefs.getString(SyncCoordinator.lastSyncKey) ?? '')
      ?.toUtc();
});

/// Quantas fotos esperam pra subir pra nuvem.
final pendingPhotosProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(recipeImageSyncProvider).pendingCount(),
);

/// Uma linha com o estado do sync: "Sincronizado · há 2 min", "Sincronizando…"
/// ou a falha.
String syncSummary(SyncState sync, DateTime now) {
  if (sync.phase == SyncPhase.syncing) return 'Sincronizando…';
  if (sync.phase == SyncPhase.error) {
    return sync.failure ?? 'Não foi possível sincronizar agora.';
  }
  final last = sync.lastSyncAt;
  return last == null
      ? 'Aguardando a primeira sincronização'
      : 'Sincronizado · ${formatSyncAgo(last, now)}';
}

/// Sincronização e fotos na nuvem de quem tem o Plus: o estado de agora, com o
/// botão de sincronizar na hora, e o espaço das fotos.
class SyncSection extends ConsumerWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hasQuota = ref.watch(photoQuotaProvider).valueOrNull != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            'SINCRONIZAÇÃO',
            style: context.texts.labelSmall?.copyWith(color: colors.textMuted),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.paperSoft,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            children: [
              const _SyncStatusRow(),
              if (hasQuota) ...[
                Divider(height: 1, thickness: 1.5, color: colors.paper),
                const _PhotoQuotaRow(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncStatusRow extends ConsumerStatefulWidget {
  const _SyncStatusRow();

  @override
  ConsumerState<_SyncStatusRow> createState() => _SyncStatusRowState();
}

class _SyncStatusRowState extends ConsumerState<_SyncStatusRow> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
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
    final colors = context.colors;
    final text = syncSummary(sync, ref.watch(syncClockProvider)());
    final syncing = sync.phase == SyncPhase.syncing;
    final failed = sync.phase == SyncPhase.error;
    final needsSignIn = failed && sync.problem == SyncProblem.auth;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
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
                          ? (needsSignIn ||
                                  sync.problem == SyncProblem.serverFull
                              ? Icons.error_outline_rounded
                              : Icons.cloud_off_outlined)
                          : Icons.cloud_done_outlined,
                      size: 22,
                      color: failed ? colors.danger : colors.onPaper,
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: context.texts.bodyMedium?.copyWith(
                  color: failed ? colors.danger : colors.onPaper,
                ),
              ),
            ),
            if (sync.enabled)
              TextButton(
                onPressed: syncing
                    ? null
                    : needsSignIn
                        ? () =>
                            ref.read(authControllerProvider.notifier).signIn()
                        : () => ref
                            .read(syncCoordinatorProvider.notifier)
                            .requestFullSync(),
                child: Text(needsSignIn ? 'Entrar de novo' : 'Sincronizar'),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Fotos na nuvem · 12 MB de 30 MB", com uma barra. Perto do teto avisa; no
/// teto explica que as fotos novas ficam só neste aparelho (e quantas esperam).
class _PhotoQuotaRow extends ConsumerWidget {
  const _PhotoQuotaRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quota = ref.watch(photoQuotaProvider).valueOrNull;
    if (quota == null) return const SizedBox.shrink();

    final colors = context.colors;
    final full = quota.blocked;
    final accent = full ? colors.danger : colors.onPaper;
    final detail = full
        ? 'Limite atingido. As fotos novas ficam só neste aparelho'
            '${quota.pending > 0 ? ' (${quota.pending} esperando)' : ''}. '
            'Apague fotos de receitas que não usa mais para liberar espaço.'
        : quota.nearLimit
            ? 'Quase no limite. Apague fotos de receitas que não usa mais '
                'para abrir espaço.'
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
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
                    size: 22, color: full ? colors.danger : colors.onPaper),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Fotos na nuvem',
                    style: context.texts.bodyMedium
                        ?.copyWith(color: colors.onPaper),
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
                backgroundColor: colors.paper,
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

/// O Plus acabou: quando, até onde o sync chegou e o que está esperando neste
/// aparelho. O recado principal é que nada foi perdido.
class EndedCard extends ConsumerWidget {
  const EndedCard({super.key, required this.endedAt});

  final DateTime endedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = ref.watch(syncClockProvider)();
    final last = ref.watch(lastSyncProvider).valueOrNull;
    final photos = ref.watch(pendingPhotosProvider).valueOrNull ?? 0;

    final rows = <(IconData, String)>[
      (Icons.event_busy_outlined, 'Encerrado em ${_date(endedAt)}'),
      if (last != null)
        (
          Icons.cloud_done_outlined,
          'Última sincronização ${formatSyncAgo(last, now)}'
        ),
      if (photos > 0)
        (
          Icons.photo_library_outlined,
          photos == 1
              ? '1 foto esperando para subir'
              : '$photos fotos esperando para subir',
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pause_circle_outline_rounded,
                  size: 30, color: colors.onPaper),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child:
                    Text('Seu Plus acabou', style: AppTextStyles.display(26)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(row.$1, size: 20, color: colors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: context.texts.bodyMedium
                          ?.copyWith(color: colors.onPaper),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          Text(
            'A sincronização, as fotos na nuvem e a casa estão pausadas. Tudo '
            'continua salvo neste aparelho e nada foi apagado. Assine de novo '
            'e o que esperava sobe sozinho.',
            style: context.texts.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime date) {
    final d = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}
