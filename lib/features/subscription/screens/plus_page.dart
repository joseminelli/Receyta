import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/billing_service.dart';
import 'package:receyta/data/subscription/cloud_access_remote.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/subscription/controllers/cloud_access_controller.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';

final _plansProvider = FutureProvider.autoDispose<List<PlanOption>>(
  (ref) => ref.watch(billingServiceProvider).plans(),
);

/// "Receyta Plus": a assinatura que liga a parte online (sincronização entre
/// aparelhos, fotos na nuvem e a casa). Sem ela o app inteiro continua
/// funcionando no aparelho; nada é apagado quando a assinatura acaba.
class PlusPage extends ConsumerStatefulWidget {
  const PlusPage({super.key});

  @override
  ConsumerState<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends ConsumerState<PlusPage> {
  PlanPeriod _selected = PlanPeriod.annual;
  bool _busy = false;
  bool _activating = false;

  void _error(String message) => AppSnackBar.show(
        context,
        message: message,
        variant: AppSnackBarVariant.error,
      );

  Future<void> _buy(PlanOption plan) async {
    setState(() => _busy = true);
    final result = await ref.read(cloudAccessProvider.notifier).purchase(plan);
    if (!mounted) return;
    switch (result) {
      case Ok(value: true):
        await _activate('Receyta Plus ativado. Obrigado!');
      case Ok():
        setState(() => _busy = false);
      case Err(:final failure):
        setState(() => _busy = false);
        _error(failure.message);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final result = await ref.read(cloudAccessProvider.notifier).restore();
    if (!mounted) return;
    switch (result) {
      case Ok(value: true):
        await _activate('Assinatura restaurada.');
      case Ok():
        setState(() => _busy = false);
        _error('Não encontramos uma assinatura nesta conta Google Play.');
      case Err(:final failure):
        setState(() => _busy = false);
        _error(failure.message);
    }
  }

  /// A loja já confirmou: mostra o "ativando" na hora e liga o acesso no
  /// servidor.
  Future<void> _activate(String successMessage) async {
    setState(() => _activating = true);
    final ok = await ref.read(cloudAccessProvider.notifier).activate();
    if (!mounted) return;
    setState(() {
      _activating = false;
      _busy = false;
    });
    if (ok) {
      AppSnackBar.show(context, message: successMessage);
    } else {
      _error(
        'Compra confirmada, mas a ativação está demorando. Pode fechar e '
        'abrir o app em instantes: o Plus liga sozinho.',
      );
    }
  }

  Future<void> _signIn() async {
    final failure = await ref.read(authControllerProvider.notifier).signIn();
    if (failure == null || !mounted) return;
    _error(failure.message);
  }

  Future<void> _manage() => launchUrl(
        Uri.parse('https://play.google.com/store/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(authUserProvider).valueOrNull;
    final access = ref.watch(cloudAccessProvider);
    final active = ref.watch(hasCloudAccessProvider);

    final Widget action;
    if (user == null) {
      action = _SignInPrompt(onSignIn: _signIn);
    } else if (_activating) {
      action = const _Activating();
    } else if (access.isLoading && !access.hasValue) {
      action = const Center(child: BrandLoader());
    } else if (active) {
      action = _ActiveBox(
        access: access.valueOrNull ?? CloudAccess.none,
        onManage: _manage,
      );
    } else {
      action = _Plans(
        selected: _selected,
        busy: _busy,
        onSelect: (p) => setState(() => _selected = p),
        onBuy: _buy,
        onRestore: _restore,
      );
    }

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: CircleIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Voltar',
                onTap: () => context.pop(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Receyta Plus', style: AppTextStyles.display(52)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'A parte online do seu livro de receitas.',
              style: context.texts.bodyLarge?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _Perk(
              icon: Icons.sync_rounded,
              title: 'Sincronização',
              text: 'Receitas, listas e calendário iguais em todos os seus '
                  'aparelhos.',
            ),
            const _Perk(
              icon: Icons.photo_library_outlined,
              title: 'Fotos na nuvem',
              text: 'As fotos das receitas guardadas e de volta se você '
                  'trocar de celular.',
            ),
            const _Perk(
              icon: Icons.home_outlined,
              title: 'Casa para até 6 pessoas',
              text: 'Só o dono assina. Quem entra na casa usa de graça '
                  'enquanto o plano do dono estiver ativo.',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sem o Plus o app continua completo no aparelho. Se a '
              'assinatura acabar, nada é apagado: só a sincronização pausa e '
              'volta quando você assinar de novo.',
              style: context.texts.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            action,
          ],
        ),
      ),
    );
  }
}

/// Entre a compra confirmada e o acesso ligado no servidor (poucos segundos).
class _Activating extends StatelessWidget {
  const _Activating();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      label: 'Ativando o seu Plus',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.paperSoft,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ativando o seu Plus…',
                      style: AppTextStyles.display(24)),
                  const SizedBox(height: 2),
                  Text(
                    'Pagamento confirmado. Leva só alguns segundos.',
                    style: context.texts.bodyMedium
                        ?.copyWith(color: colors.textMuted),
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

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: colors.ink, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: colors.lime),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.display(22)),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: context.texts.bodyMedium
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'A assinatura fica ligada à sua conta Google, para valer em todos '
          'os seus aparelhos.',
          style: context.texts.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: 'Entrar com Google',
          icon: Icons.login_rounded,
          onPressed: onSignIn,
        ),
      ],
    );
  }
}

class _Plans extends ConsumerWidget {
  const _Plans({
    required this.selected,
    required this.busy,
    required this.onSelect,
    required this.onBuy,
    required this.onRestore,
  });

  final PlanPeriod selected;
  final bool busy;
  final ValueChanged<PlanPeriod> onSelect;
  final ValueChanged<PlanOption> onBuy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final plans = ref.watch(_plansProvider);
    void retry() => ref.invalidate(_plansProvider);

    return plans.when(
      loading: () => const Center(child: BrandLoader()),
      error: (_, __) => _Unavailable(onRetry: retry),
      data: (list) {
        if (list.isEmpty) return _Unavailable(onRetry: retry);
        final current = list.firstWhere(
          (p) => p.period == selected,
          orElse: () => list.first,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final plan in list) ...[
              _PlanTile(
                plan: plan,
                selected: plan.period == current.period,
                onTap: busy ? null : () => onSelect(plan.period),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: 'Assinar',
              icon: Icons.workspace_premium_outlined,
              loading: busy,
              onPressed: busy ? null : () => onBuy(current),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: 'Restaurar compra',
              variant: PillButtonVariant.secondary,
              onPressed: busy ? null : onRestore,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Renova sozinha até você cancelar, quando quiser, em Google '
              'Play → Pagamentos e assinaturas.',
              textAlign: TextAlign.center,
              style: context.texts.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
        );
      },
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PlanOption plan;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final annual = plan.period == PlanPeriod.annual;
    return Semantics(
      button: true,
      selected: selected,
      label: '${annual ? 'Plano anual' : 'Plano mensal'}, ${plan.priceText}',
      child: Material(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: selected ? colors.ink : colors.paperSoft,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: colors.ink,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    annual ? 'Anual' : 'Mensal',
                    style: AppTextStyles.display(24),
                  ),
                ),
                Text(
                  '${plan.priceText} ${annual ? '/ ano' : '/ mês'}',
                  style: context.texts.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Não conseguimos carregar os planos agora. Confira a internet e '
          'tente de novo.',
          style: context.texts.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: 'Tentar de novo',
          variant: PillButtonVariant.secondary,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _ActiveBox extends StatelessWidget {
  const _ActiveBox({required this.access, required this.onManage});

  final CloudAccess access;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = access.until == null ? null : formatAccessDate(access.until!);

    final title = switch (access.source) {
      AccessSource.house => 'Plus da casa',
      AccessSource.grant => 'Acesso liberado',
      _ => 'Plus ativo',
    };
    final detail = switch (access.source) {
      AccessSource.house => 'Você usa a parte online pela assinatura do dono '
          'da casa${date == null ? '' : ', válida até $date'}.',
      AccessSource.grant => date == null
          ? 'Sua conta tem acesso à parte online, sem prazo.'
          : 'Sua conta tem acesso à parte online até $date.',
      _ => date == null
          ? 'Sua assinatura está ativa.'
          : 'Sua assinatura está ativa até $date.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.paperSoft,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: colors.onPaper),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.display(24)),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: context.texts.bodyMedium
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (access.source == AccessSource.own) ...[
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Gerenciar na Google Play',
            variant: PillButtonVariant.secondary,
            onPressed: onManage,
          ),
        ],
      ],
    );
  }
}

/// "dd/mm/aaaa" no fuso do aparelho.
String formatAccessDate(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}
