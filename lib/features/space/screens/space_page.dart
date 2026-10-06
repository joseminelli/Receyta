import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/data/space/space_remote.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/space/controllers/calendar_share.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/widgets/pill_button.dart';

/// A casa: o espaço onde a pessoa divide listas de compras (e o calendário)
/// com quem mora com ela. Sem casa, oferece criar uma ou entrar com um código;
/// com casa, mostra quem faz parte, convida e deixa sair.
class SpacePage extends ConsumerWidget {
  const SpacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceControllerProvider);
    final user = ref.watch(authUserProvider).valueOrNull;

    return HeaderScaffold(
      title: 'Casa',
      subtitle: 'Divida compras e calendário',
      color: TileColor.violet,
      body: RefreshIndicator(
        onRefresh: () => ref.read(spaceControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          children: [
            if (user == null)
              const _Notice(
                icon: Icons.lock_outline,
                title: 'Entre na sua conta',
                text: 'A casa usa a sua conta Google para saber quem é quem. '
                    'Entre pela aba Conta.',
              )
            else if (space.isLoading && !space.hasValue)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: BrandLoader()),
              )
            else if (space.valueOrNull == null)
              const _NoSpace()
            else
              _InSpace(space: space.requireValue!, myId: user.id),
          ],
        ),
      ),
    );
  }
}

void _report(Failure f) =>
    showAppSnackBar(message: f.message, variant: AppSnackBarVariant.error);

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.ink),
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

class _NoSpace extends ConsumerStatefulWidget {
  const _NoSpace();

  @override
  ConsumerState<_NoSpace> createState() => _NoSpaceState();
}

class _NoSpaceState extends ConsumerState<_NoSpace> {
  bool _creating = false;

  Future<void> _create() async {
    setState(() => _creating = true);
    final result = await ref.read(spaceControllerProvider.notifier).create();
    if (!mounted) return;
    setState(() => _creating = false);
    result.when(
      ok: (_) {
        showAppSnackBar(message: 'Casa criada. Agora convide alguém.');
        showInviteSheet(context, ref);
      },
      err: _report,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Uma lista de compras para todo mundo da casa.',
          style: AppTextStyles.display(28),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Crie uma casa e convide quem divide as compras com você. As listas '
          'que você escolher compartilhar aparecem para todos, e quem marca um '
          'item atualiza na hora para os outros.',
          style: context.texts.bodyLarge?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: 'Criar uma casa',
          icon: Icons.home_outlined,
          loading: _creating,
          onPressed: _creating ? null : _create,
        ),
        const SizedBox(height: AppSpacing.xs),
        PillButton(
          label: 'Tenho um código',
          icon: Icons.key_outlined,
          variant: PillButtonVariant.secondary,
          onPressed: () => showJoinSheet(context, ref),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _Notice(
          icon: Icons.shield_outlined,
          title: 'Você escolhe o que dividir',
          text: 'Só as listas que você compartilha ficam na casa. Receitas, '
              'despensa e o resto continuam só seus.',
        ),
      ],
    );
  }
}

class _InSpace extends ConsumerWidget {
  const _InSpace({required this.space, required this.myId});

  final SpaceInfo space;
  final String myId;

  bool get _iAmOwner => space.ownerId == myId;

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final ok = await AppDialog.confirm(
      context,
      icon: Icons.logout_rounded,
      accent: context.colors.danger,
      title: _iAmOwner ? 'Encerrar a casa?' : 'Sair da casa?',
      message: _iAmOwner
          ? 'A casa acaba para todos. Cada pessoa continua com as listas que '
              'já tem no próprio aparelho, mas elas deixam de ser '
              'compartilhadas.'
          : 'Você deixa de ver as mudanças dos outros. As listas compartilhadas '
              'continuam no seu aparelho, só que agora só suas.',
      confirmLabel: _iAmOwner ? 'Encerrar' : 'Sair',
    );
    if (!ok || !context.mounted) return;
    final result = await ref.read(spaceControllerProvider.notifier).leave();
    result.when(
      ok: (_) => showAppSnackBar(
        message: _iAmOwner ? 'Casa encerrada.' : 'Você saiu da casa.',
      ),
      err: _report,
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    SpaceMember member,
  ) async {
    final name =
        member.displayName.isEmpty ? 'essa pessoa' : member.displayName;
    final ok = await AppDialog.confirm(
      context,
      icon: Icons.person_remove_outlined,
      accent: context.colors.danger,
      title: 'Remover $name?',
      message: 'Ela deixa de ver as listas compartilhadas. O que já está no '
          'aparelho dela continua lá.',
      confirmLabel: 'Remover',
    );
    if (!ok) return;
    final result =
        await ref.read(spaceControllerProvider.notifier).remove(member.userId);
    result.when(ok: (_) {}, err: _report);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('QUEM ESTÁ NA CASA', style: _label(context)),
        const SizedBox(height: AppSpacing.xs),
        if (space.members.isEmpty)
          const _Notice(
            icon: Icons.cloud_off_outlined,
            title: 'Sem conexão',
            text: 'Não deu para ler quem está na casa. Puxe a tela pra baixo '
                'quando a internet voltar.',
          )
        else
          Container(
            decoration: BoxDecoration(
              color: colors.paperSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              children: [
                for (var i = 0; i < space.members.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1.5,
                      indent: 72,
                      color: colors.paper,
                    ),
                  _MemberRow(
                    member: space.members[i],
                    isMe: space.members[i].userId == myId,
                    canRemove: _iAmOwner && space.members[i].userId != myId,
                    onRemove: () => _remove(context, ref, space.members[i]),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (_iAmOwner)
          PillButton(
            label: 'Convidar alguém',
            icon: Icons.person_add_alt_1_outlined,
            onPressed: () => showInviteSheet(context, ref),
          ),
        const SizedBox(height: AppSpacing.lg),
        const _CalendarSwitch(),
        const SizedBox(height: AppSpacing.sm),
        const _Notice(
          icon: Icons.shopping_basket_outlined,
          title: 'Como compartilhar uma lista',
          text: 'Na aba Compras, toque nos três pontinhos da lista e escolha '
              '"Compartilhar com a casa". Ela aparece para todos, e dá para '
              'deixar de compartilhar quando quiser.',
        ),
        const SizedBox(height: AppSpacing.xl),
        PillButton(
          label: _iAmOwner ? 'Encerrar a casa' : 'Sair da casa',
          icon: Icons.logout_rounded,
          variant: PillButtonVariant.danger,
          onPressed: () => _leave(context, ref),
        ),
      ],
    );
  }

  TextStyle? _label(BuildContext context) =>
      context.texts.labelSmall?.copyWith(color: context.colors.textMuted);
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.canRemove,
    required this.onRemove,
  });

  final SpaceMember member;
  final bool isMe;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = member.displayName.isEmpty ? 'Sem nome' : member.displayName;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: colors.ink, shape: BoxShape.circle),
              child: Text(
                name.characters.first.toUpperCase(),
                style: AppTextStyles.display(22).copyWith(color: colors.lime),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMe ? '$name (você)' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    member.isOwner ? 'Dono da casa' : 'Membro',
                    style: context.texts.bodySmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            if (canRemove)
              IconButton(
                tooltip: 'Remover da casa',
                onPressed: onRemove,
                icon: Icon(Icons.person_remove_outlined, color: colors.danger),
              ),
          ],
        ),
      ),
    );
  }
}

/// Gera um código de convite e mostra pra copiar ou mandar.
Future<void> showInviteSheet(BuildContext context, WidgetRef ref) async {
  final result = await ref.read(spaceControllerProvider.notifier).invite();
  if (!context.mounted) return;
  switch (result) {
    case Err(:final failure):
      _report(failure);
    case Ok(:final value):
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _InviteSheet(code: value),
      );
  }
}

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.code});

  final String code;

  String get _message =>
      'Entra na minha casa no Receyta! Abra o app, vá em Conta > Casa > '
      '"Tenho um código" e digite: $code (vale por 48 horas).';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppSheetFrame(
      title: 'Convite',
      subtitle: 'Vale por 48 horas e serve para uma pessoa.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.paperSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Center(
              child: SelectableText(
                code,
                style: AppTextStyles.display(44).copyWith(letterSpacing: 6),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Mandar o convite',
            icon: Icons.ios_share_rounded,
            onPressed: () => Share.share(_message, subject: 'Convite Receyta'),
          ),
          const SizedBox(height: AppSpacing.xs),
          PillButton(
            label: 'Copiar o código',
            icon: Icons.copy_rounded,
            variant: PillButtonVariant.secondary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              showAppSnackBar(message: 'Código copiado.');
            },
          ),
        ],
      ),
    );
  }
}

/// Pede o código de um convite e entra na casa.
Future<void> showJoinSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _JoinSheet(),
  );
}

class _JoinSheet extends ConsumerStatefulWidget {
  const _JoinSheet();

  @override
  ConsumerState<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends ConsumerState<_JoinSheet> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    final result =
        await ref.read(spaceControllerProvider.notifier).join(_controller.text);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      ok: (_) {
        Navigator.of(context).pop();
        showAppSnackBar(message: 'Você entrou na casa.');
      },
      err: _report,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheetFrame(
        title: 'Entrar numa casa',
        subtitle: 'Digite o código que a pessoa te mandou.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [_InviteCodeFormatter()],
              style: AppTextStyles.display(34).copyWith(letterSpacing: 5),
              decoration: const InputDecoration(
                hintText: 'CÓDIGO',
                counterText: '',
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: AppSpacing.sm),
            PillButton(
              label: 'Entrar',
              icon: Icons.login_rounded,
              loading: _busy,
              onPressed: _busy ? null : _join,
            ),
          ],
        ),
      ),
    );
  }
}

/// Liga e desliga a participação no calendário da casa.
class _CalendarSwitch extends ConsumerWidget {
  const _CalendarSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final on = ref.watch(calendarSharedProvider).valueOrNull ?? false;

    Future<void> change(bool value) async {
      final result = await ref.read(calendarSharedProvider.notifier).set(value);
      if (result is Err<void>) _report(result.failure);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, color: colors.ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calendário da casa', style: AppTextStyles.display(22)),
                const SizedBox(height: 2),
                Text(
                  on
                      ? 'Suas refeições de hoje em diante aparecem para todos, '
                          'e as deles aparecem no seu calendário.'
                      : 'Divida o que vai ser cozinhado: você vê as refeições '
                          'da casa e elas veem as suas.',
                  style: context.texts.bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          Switch(value: on, onChanged: change),
        ],
      ),
    );
  }
}

/// Ao colar a mensagem do convite inteira, deixa só o código no campo.
class _InviteCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= 12) return newValue;
    final code = normalizeInviteCode(newValue.text);
    final text = code.length > 12 ? code.substring(0, 12) : code;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
