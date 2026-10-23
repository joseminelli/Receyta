import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/sync/sync_coordinator.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Pílula discreta com o estado do sync, só quando há o que dizer: sincronizando,
/// sem internet (alterações ficam pendentes) ou falha. Sincronizado e idle não
/// mostram nada. Toque abre os detalhes em `/plus`.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncCoordinatorProvider);
    final status = _statusFor(sync);
    final colors = context.colors;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: anim, child: child),
      ),
      child: status == null
          ? const SizedBox(key: ValueKey('sync-none'))
          : Semantics(
              key: ValueKey(status.label),
              button: true,
              label: status.label,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: [
                    BoxShadow(
                      color: colors.ink.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: colors.ink,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/plus'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (status.busy)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onInk,
                              ),
                            )
                          else
                            Icon(
                              status.icon,
                              size: 16,
                              color:
                                  status.failed ? colors.coral : colors.onInk,
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            status.label,
                            style: context.texts.labelLarge?.copyWith(
                              color: colors.onInk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  _SyncChipStatus? _statusFor(SyncState sync) {
    if (!sync.enabled) return null;
    if (sync.phase == SyncPhase.syncing) {
      return const _SyncChipStatus('Sincronizando…', Icons.sync, busy: true);
    }
    if (sync.phase != SyncPhase.error) return null;
    return switch (sync.problem) {
      SyncProblem.offline => const _SyncChipStatus(
          'Sem internet · alterações pendentes',
          Icons.cloud_off_outlined,
        ),
      SyncProblem.auth => const _SyncChipStatus(
          'Entre de novo para sincronizar',
          Icons.error_outline,
          failed: true,
        ),
      _ => const _SyncChipStatus(
          'Não sincronizou · toque para ver',
          Icons.error_outline,
          failed: true,
        ),
    };
  }
}

class _SyncChipStatus {
  const _SyncChipStatus(
    this.label,
    this.icon, {
    this.busy = false,
    this.failed = false,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final bool failed;
}
