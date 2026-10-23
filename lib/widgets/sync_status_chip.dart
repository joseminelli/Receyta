import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/sync/sync_coordinator.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

enum _SyncTone { busy, done, offline, failed }

class _SyncChipStatus {
  const _SyncChipStatus(this.tone, this.label);

  final _SyncTone tone;
  final String label;
}

/// Pílula do estado do sync, na linguagem do `AppToast`: um chip redondo
/// colorido + título, que entra com mola e muda no lugar (chip, texto e
/// largura) conforme o estado. Só aparece quando há o que dizer: sincronizando,
/// "Sincronizado" por instantes ao terminar, sem internet ou falha. Toque abre
/// os detalhes em `/plus`.
class SyncStatusChip extends ConsumerStatefulWidget {
  const SyncStatusChip({super.key});

  @override
  ConsumerState<SyncStatusChip> createState() => _SyncStatusChipState();
}

class _SyncStatusChipState extends ConsumerState<SyncStatusChip> {
  static const _doneFor = Duration(milliseconds: 2400);

  bool _showDone = false;
  Timer? _doneTimer;

  @override
  void dispose() {
    _doneTimer?.cancel();
    super.dispose();
  }

  void _onSyncChanged(SyncState? previous, SyncState next) {
    final finished = previous?.phase == SyncPhase.syncing &&
        next.phase == SyncPhase.idle &&
        next.enabled;
    if (!finished) {
      if (next.phase != SyncPhase.idle && _showDone) {
        _doneTimer?.cancel();
        setState(() => _showDone = false);
      }
      return;
    }
    _doneTimer?.cancel();
    setState(() => _showDone = true);
    _doneTimer = Timer(_doneFor, () {
      if (mounted) setState(() => _showDone = false);
    });
  }

  _SyncChipStatus? _statusFor(SyncState sync) {
    if (!sync.enabled) return null;
    switch (sync.phase) {
      case SyncPhase.syncing:
        return const _SyncChipStatus(_SyncTone.busy, 'Sincronizando…');
      case SyncPhase.error:
        return switch (sync.problem) {
          SyncProblem.offline => const _SyncChipStatus(
              _SyncTone.offline,
              'Sem internet · alterações pendentes',
            ),
          SyncProblem.auth => const _SyncChipStatus(
              _SyncTone.failed,
              'Entre de novo para sincronizar',
            ),
          _ => const _SyncChipStatus(
              _SyncTone.failed,
              'Não sincronizou · toque para ver',
            ),
        };
      case SyncPhase.idle:
        return _showDone
            ? const _SyncChipStatus(_SyncTone.done, 'Sincronizado')
            : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SyncState>(syncCoordinatorProvider, _onSyncChanged);
    final status = _statusFor(ref.watch(syncCoordinatorProvider));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.bottomCenter,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: CurvedAnimation(
          parent: anim,
          curve: const Interval(0, 0.6, curve: Curves.easeOut),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.4, end: 1).animate(anim),
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: status == null
          ? const SizedBox(key: ValueKey('sync-none'))
          : _SyncPill(key: const ValueKey('sync-pill'), status: status),
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({super.key, required this.status});

  final _SyncChipStatus status;

  Color _chipColor(AppColors colors) => switch (status.tone) {
        _SyncTone.busy => colors.inkSoft,
        _SyncTone.done => colors.lime,
        _SyncTone.offline => colors.violet,
        _SyncTone.failed => colors.danger,
      };

  Color _onChip(AppColors colors) => switch (status.tone) {
        _SyncTone.busy => colors.onInk,
        _SyncTone.done => colors.ink,
        _SyncTone.offline || _SyncTone.failed => colors.onSaturated,
      };

  IconData get _icon => switch (status.tone) {
        _SyncTone.busy => Icons.sync,
        _SyncTone.done => Icons.check_rounded,
        _SyncTone.offline => Icons.cloud_off_rounded,
        _SyncTone.failed => Icons.priority_high_rounded,
      };

  Widget _chip(AppColors colors) {
    final onChip = _onChip(colors);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
      child: Container(
        key: ValueKey(status.tone),
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _chipColor(colors),
          shape: BoxShape.circle,
        ),
        child: status.tone == _SyncTone.busy
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: onChip,
                ),
              )
            : Icon(_icon, size: 16, color: onChip),
      ),
    );
  }

  Widget _label(BuildContext context, AppColors colors) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      child: Text(
        status.label,
        key: ValueKey(status.label),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.labelLarge?.copyWith(
          color: colors.onInk,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      liveRegion: true,
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
            child: AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _chip(colors),
                    const SizedBox(width: AppSpacing.sm),
                    _label(context, colors),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
