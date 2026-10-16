import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/billing_service.dart';
import 'package:receyta/data/subscription/cloud_access_remote.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/subscription/controllers/cloud_access_controller.dart';
import 'package:receyta/features/subscription/screens/sync_details.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/tile_pattern.dart';

final _plansProvider = FutureProvider.autoDispose<List<PlanOption>>(
  (ref) => ref.watch(billingServiceProvider).plans(),
);

/// "Receyta Plus": a assinatura que liga a parte online (sincronização entre
/// aparelhos, fotos na nuvem e a casa). Sem ela o app inteiro continua
/// funcionando no aparelho; nada é apagado quando a assinatura acaba.
///
/// Cabeçalho escuro com a textura do app, os benefícios num cartão e, pra quem
/// ainda não assina, os planos com o botão de assinar fixo embaixo da tela.
class PlusPage extends ConsumerStatefulWidget {
  const PlusPage({super.key});

  @override
  ConsumerState<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends ConsumerState<PlusPage> {
  PlanPeriod _selected = PlanPeriod.annual;
  bool _busy = false;
  bool _activating = false;
  bool _restoring = false;

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
        await _activate('Assinatura restaurada.', restoring: true);
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
  Future<void> _activate(String successMessage,
      {bool restoring = false}) async {
    setState(() {
      _activating = true;
      _restoring = restoring;
    });
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
        restoring
            ? 'Encontramos a assinatura, mas ela não está ativa agora. Se '
                'venceu, assine de novo.'
            : 'Compra confirmada, mas a ativação está demorando. Pode fechar '
                'e abrir o app em instantes: o Plus liga sozinho.',
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
    final selling = user != null &&
        !_activating &&
        !active &&
        !(access.isLoading && !access.hasValue);
    final plans = selling ? ref.watch(_plansProvider) : null;
    final options = plans?.valueOrNull ?? const <PlanOption>[];

    final Widget action;
    if (user == null) {
      action = _SignInPrompt(onSignIn: _signIn);
    } else if (_activating) {
      action = _Activating(restoring: _restoring);
    } else if (access.isLoading && !access.hasValue) {
      action = const Center(child: BrandLoader());
    } else if (active) {
      action = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ManageBox(
            access: access.valueOrNull ?? CloudAccess.none,
            onManage: _manage,
          ),
          const SyncSection(),
        ],
      );
    } else {
      final Widget picker;
      if (plans == null || plans.isLoading) {
        picker = const Center(child: BrandLoader());
      } else if (options.isEmpty) {
        picker = _Unavailable(onRetry: () => ref.invalidate(_plansProvider));
      } else {
        picker = _PlanPicker(
          options: options,
          selected: _selected,
          busy: _busy,
          onSelect: (p) => setState(() => _selected = p),
        );
      }
      final endedAt =
          access.valueOrNull?.ended == true ? access.valueOrNull!.until : null;
      action = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (endedAt != null) ...[
            EndedCard(endedAt: endedAt),
            const SizedBox(height: AppSpacing.lg),
          ],
          picker,
        ],
      );
    }

    final current = options.isEmpty
        ? null
        : options.firstWhere(
            (p) => p.period == _selected,
            orElse: () => options.first,
          );

    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Hero(
                  access:
                      active ? (access.valueOrNull ?? CloudAccess.none) : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.lg,
                    AppSpacing.screen,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      action,
                      if (!active) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const _SectionLabel('O QUE VEM NO PLUS'),
                        const _Perks(),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      const _Reassurance(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (selling && current != null)
            _BuyBar(
              plan: current,
              busy: _busy,
              onBuy: () => _buy(current),
              onRestore: _restore,
            ),
        ],
      ),
    );
  }
}

/// Bloco escuro do alto, com a textura do app. Sem o Plus: o selo, o nome e a
/// promessa. Com o Plus ativo vira o cartão de membro: textura em dois tons,
/// fio `lime` na base, o que está liberado e até quando vale.
class _Hero extends StatelessWidget {
  const _Hero({this.access});

  /// Não nulo = a pessoa tem o Plus.
  final CloudAccess? access;

  static const _included = ['Sincronização', 'Fotos na nuvem', 'Casa'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final member = access != null;
    final info = member ? _activeInfo(access!) : null;

    return Container(
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.lg + 10),
        ),
        border: member
            ? Border(bottom: BorderSide(color: colors.lime, width: 3))
            : null,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.lg + 10),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: SizedBox(
                width: 280,
                height: 280,
                child: TilePattern(
                  motif: member ? TileMotif.diagonal : TileMotif.ponto,
                  background: colors.ink,
                  patternColor: colors.inkPattern,
                  patternColorAlt: colors.inkPatternAlt,
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
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Voltar',
                      background: colors.inkSoft,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 22,
                          color: colors.lime,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          member ? 'MEMBRO RECEYTA PLUS' : 'RECEYTA PLUS',
                          style: context.texts.labelSmall
                              ?.copyWith(color: colors.lime),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      member
                          ? info!.title
                          : 'Seu livro de receitas, em todo lugar',
                      style: AppTextStyles.display(member ? 54 : 48)
                          .copyWith(color: colors.onSaturated),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      member
                          ? info!.detail
                          : 'Sincronize entre aparelhos, guarde as fotos na '
                              'nuvem e cozinhem juntos em casa.',
                      style: context.texts.bodyLarge?.copyWith(
                        color: colors.onSaturated.withValues(alpha: 0.8),
                      ),
                    ),
                    if (member) ...[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final label in _included) _IncludedChip(label),
                        ],
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

/// "Sincronização ✓": o que o Plus liberou, em pílula só de borda `lime`.
class _IncludedChip extends StatelessWidget {
  const _IncludedChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.lime, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 16, color: colors.lime),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.texts.labelMedium?.copyWith(
              color: colors.onSaturated,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Título e frase do cartão de membro, conforme de onde vem o acesso.
({String title, String detail}) _activeInfo(CloudAccess access) {
  final date = access.until == null ? null : formatAccessDate(access.until!);
  return switch (access.source) {
    AccessSource.house => (
        title: 'Plus da casa',
        detail: 'Você usa a parte online pela assinatura do dono da casa'
            '${date == null ? '' : ', válida até $date'}.',
      ),
    AccessSource.grant => (
        title: 'Acesso liberado',
        detail: date == null
            ? 'Sua conta tem acesso à parte online, sem prazo.'
            : 'Sua conta tem acesso à parte online até $date.',
      ),
    _ => (
        title: 'Você é Plus',
        detail: date == null
            ? 'Sua assinatura está ativa.'
            : 'Sua assinatura está ativa até $date.',
      ),
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style:
            context.texts.labelSmall?.copyWith(color: context.colors.textMuted),
      ),
    );
  }
}

/// Os três benefícios num cartão só, separados por um fio.
class _Perks extends StatelessWidget {
  const _Perks();

  static const _items = [
    (
      Icons.sync_rounded,
      'Sincronização',
      'Receitas, listas e calendário iguais em todos os seus aparelhos.',
    ),
    (
      Icons.photo_library_outlined,
      'Fotos na nuvem',
      'As fotos das receitas guardadas, e de volta se você trocar de celular.',
    ),
    (
      Icons.home_outlined,
      'Casa para até 6 pessoas',
      'Só o dono assina. Quem entra usa de graça enquanto o plano do dono '
          'estiver ativo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1.5,
                indent: 72,
                color: colors.paper,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_items[i].$1, size: 22, color: colors.lime),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_items[i].$2, style: AppTextStyles.display(22)),
                        const SizedBox(height: 2),
                        Text(
                          _items[i].$3,
                          style: context.texts.bodyMedium
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// O que acontece se a assinatura acabar: o medo número um de quem assina.
class _Reassurance extends StatelessWidget {
  const _Reassurance();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, size: 20, color: colors.onPaper),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Sem o Plus o app continua completo no aparelho. Se a assinatura '
            'acabar, nada é apagado: só a sincronização pausa e volta quando '
            'você assinar de novo.',
            style: context.texts.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Quanto o plano anual economiza sobre 12 meses do mensal, em %; nulo se a
/// diferença for pequena demais pra valer o destaque.
int? _savingPercent(List<PlanOption> options) {
  PlanOption? monthly;
  PlanOption? annual;
  for (final p in options) {
    if (p.period == PlanPeriod.monthly) monthly = p;
    if (p.period == PlanPeriod.annual) annual = p;
  }
  if (monthly == null || annual == null || monthly.price <= 0) return null;
  final pct = ((1 - annual.price / (monthly.price * 12)) * 100).round();
  return pct >= 5 ? pct : null;
}

class _PlanPicker extends StatelessWidget {
  const _PlanPicker({
    required this.options,
    required this.selected,
    required this.busy,
    required this.onSelect,
  });

  final List<PlanOption> options;
  final PlanPeriod selected;
  final bool busy;
  final ValueChanged<PlanPeriod> onSelect;

  @override
  Widget build(BuildContext context) {
    final saving = _savingPercent(options);
    final current = options.any((p) => p.period == selected)
        ? selected
        : options.first.period;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('ESCOLHA SEU PLANO'),
        for (final plan in options) ...[
          _PlanTile(
            plan: plan,
            selected: plan.period == current,
            savingPercent: plan.period == PlanPeriod.annual ? saving : null,
            onTap: busy ? null : () => onSelect(plan.period),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.savingPercent,
    required this.onTap,
  });

  final PlanOption plan;
  final bool selected;
  final int? savingPercent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final annual = plan.period == PlanPeriod.annual;
    final perMonth = annual && plan.perMonthText != null
        ? 'equivale a ${plan.perMonthText}/mês'
        : null;
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: selected ? colors.onPaper : colors.paperSoft,
                width: selected ? 2.5 : 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: colors.onPaper,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            annual ? 'Anual' : 'Mensal',
                            style: AppTextStyles.display(26),
                          ),
                          if (savingPercent != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _SavingBadge(percent: savingPercent!),
                          ],
                        ],
                      ),
                      if (perMonth != null)
                        Text(
                          perMonth,
                          style: context.texts.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.priceText,
                      style: AppTextStyles.display(26),
                    ),
                    Text(
                      annual ? 'por ano' : 'por mês',
                      style: context.texts.bodySmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Selo "-17%": bloco `ink` com texto `lime` (a forma de usar lime sobre paper).
class _SavingBadge extends StatelessWidget {
  const _SavingBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        '-$percent%',
        style: context.texts.labelSmall?.copyWith(
          color: colors.lime,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Fixa embaixo da tela: o botão de assinar sempre à mão, com o plano e o
/// preço escolhidos nele, e o resto do que a loja exige dizer.
class _BuyBar extends StatelessWidget {
  const _BuyBar({
    required this.plan,
    required this.busy,
    required this.onBuy,
    required this.onRestore,
  });

  final PlanOption plan;
  final bool busy;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final annual = plan.period == PlanPeriod.annual;
    return Container(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(
          top: BorderSide(color: colors.paperSoft, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PillButton(
                label: 'Assinar · ${plan.priceText} '
                    '${annual ? 'por ano' : 'por mês'}',
                icon: Icons.workspace_premium_outlined,
                loading: busy,
                onPressed: busy ? null : onBuy,
              ),
              const SizedBox(height: 2),
              TextButton(
                onPressed: busy ? null : onRestore,
                child: const Text('Restaurar compra'),
              ),
              Text(
                'Renova sozinha até você cancelar, quando quiser, em Google '
                'Play → Pagamentos e assinaturas.',
                textAlign: TextAlign.center,
                style:
                    context.texts.bodySmall?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entre a compra confirmada e o acesso ligado no servidor (poucos segundos).
class _Activating extends StatelessWidget {
  const _Activating({required this.restoring});

  /// Restaurando uma compra antiga: ainda não há "pagamento confirmado".
  final bool restoring;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      label: restoring ? 'Verificando sua assinatura' : 'Ativando o seu Plus',
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
                  Text(
                    restoring
                        ? 'Verificando sua assinatura…'
                        : 'Ativando o seu Plus…',
                    style: AppTextStyles.display(24),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restoring
                        ? 'Leva só alguns segundos.'
                        : 'Pagamento confirmado. Leva só alguns segundos.',
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

/// Com o Plus ativo, o resto da tela fica por conta do cabeçalho; aqui só o
/// atalho de gerenciar a assinatura (quando ela é da própria pessoa).
class _ManageBox extends StatelessWidget {
  const _ManageBox({required this.access, required this.onManage});

  final CloudAccess access;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    if (access.source != AccessSource.own) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: PillButton(
        label: 'Gerenciar na Google Play',
        variant: PillButtonVariant.secondary,
        onPressed: onManage,
      ),
    );
  }
}

/// "dd/mm/aaaa" no fuso do aparelho.
String formatAccessDate(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}
