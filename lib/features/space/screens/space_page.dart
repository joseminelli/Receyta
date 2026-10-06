import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/space/space_remote.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';
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
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// A casa: o espaço onde a pessoa divide listas de compras e calendário com
/// quem mora com ela. Sem casa, apresenta o que dá pra dividir e oferece criar
/// uma ou entrar com um código; com casa, mostra quem faz parte, o que está
/// dividido, convida e deixa sair.
class SpacePage extends ConsumerWidget {
  const SpacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final space = ref.watch(spaceControllerProvider);
    final user = ref.watch(authUserProvider).valueOrNull;
    final info = space.valueOrNull;

    final Widget body;
    if (user == null) {
      body = const _Notice(
        icon: Icons.lock_outline,
        title: 'Entre na sua conta',
        text: 'A casa usa a sua conta Google para saber quem é quem. '
            'Entre pela aba Conta.',
      );
    } else if (space.isLoading && !space.hasValue) {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: BrandLoader()),
      );
    } else if (info == null) {
      body = const _NoSpace();
    } else {
      body = _InSpace(space: info, myId: user.id);
    }

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () => ref.read(spaceControllerProvider.notifier).refresh(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _SpaceHeader(info: info, myId: user?.id),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                AppSpacing.xl,
              ),
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}

void _report(Failure f) =>
    showAppSnackBar(message: f.message, variant: AppSnackBarVariant.error);

/// Cabeçalho escuro com a textura do app. Sem casa, o convite a criar uma; com
/// casa, as pessoas dela (avatares e a contagem).
class _SpaceHeader extends StatelessWidget {
  const _SpaceHeader({required this.info, required this.myId});

  final SpaceInfo? info;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final members = info?.members ?? const <SpaceMember>[];
    final people = members.length;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.lg),
      ),
      child: Container(
        color: colors.ink,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: SizedBox(
                width: 240,
                height: 240,
                child: TilePattern(
                  motif: TileMotif.ponto,
                  background: colors.ink,
                  patternColor: colors.inkPattern,
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
                  AppSpacing.lg,
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
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'CASA',
                      style: context.texts.labelSmall
                          ?.copyWith(color: colors.lime),
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      info == null ? 'Cozinhem juntos' : 'Sua casa',
                      style: AppTextStyles.display(38)
                          .copyWith(color: colors.onSaturated),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (info == null)
                      Text(
                        'Divida a lista de compras e o calendário com quem '
                        'mora com você.',
                        style: context.texts.bodyMedium?.copyWith(
                          color: colors.onSaturated.withValues(alpha: 0.75),
                        ),
                      )
                    else if (people > 0)
                      Row(
                        children: [
                          _AvatarStack(members: members, myId: myId),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            people == 1
                                ? 'Só você, por enquanto'
                                : '$people pessoas',
                            style: context.texts.bodyMedium?.copyWith(
                              color: colors.onSaturated.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
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

/// Avatares sobrepostos (iniciais), com anel `lime` em quem é o próprio usuário.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members, required this.myId});

  final List<SpaceMember> members;
  final String? myId;

  static const _size = 34.0;
  static const _step = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = members.take(5).toList();
    return SizedBox(
      width: _size + _step * (shown.length - 1),
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _step,
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.inkSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: shown[i].userId == myId ? colors.lime : colors.ink,
                    width: 2,
                  ),
                ),
                child: Text(
                  _initial(shown[i].displayName),
                  style: AppTextStyles.display(16)
                      .copyWith(color: colors.onSaturated),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _initial(String name) =>
    name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

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

/// Uma linha de cartão: medalhão `ink` com o ícone, título, descrição e, no
/// fim, o que a linha pedir ([trailing]).
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.text,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 76),
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
              decoration:
                  BoxDecoration(color: colors.ink, shape: BoxShape.circle),
              child: Icon(icon, size: 22, color: colors.lime),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.display(21)),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: context.texts.bodySmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Cartão `paperSoft` que empilha linhas com um fio entre elas.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

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
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1, thickness: 1.5, indent: 72, color: colors.paper),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _Card(children: [_InfoRow(icon: icon, title: title, text: text)]);
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
        const _SectionLabel('O QUE DÁ PRA DIVIDIR'),
        const _Card(
          children: [
            _InfoRow(
              icon: Icons.shopping_basket_outlined,
              title: 'Lista de compras',
              text: 'Uma lista só: quem está no mercado marca, e todos veem '
                  'na hora.',
            ),
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              title: 'Calendário',
              text: 'Veja o que cada um vai cozinhar e guarde a receita se '
                  'gostar.',
            ),
            _InfoRow(
              icon: Icons.shield_outlined,
              title: 'Você escolhe',
              text: 'Só o que você compartilha entra na casa. Receitas e '
                  'despensa continuam só suas.',
            ),
          ],
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
        const SizedBox(height: AppSpacing.md),
        Text(
          'Até 6 pessoas por casa. Você entra com o código de um convite.',
          textAlign: TextAlign.center,
          style: context.texts.bodySmall?.copyWith(color: colors.textMuted),
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
    final lists = ref.watch(shoppingListsProvider).valueOrNull ?? const [];
    final sharedLists = lists.where((s) => s.list.spaceId != null).length;
    final calendarOn = ref.watch(calendarSharedProvider).valueOrNull ?? false;

    Future<void> setCalendar(bool value) async {
      final result = await ref.read(calendarSharedProvider.notifier).set(value);
      if (result is Err<void>) _report(result.failure);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('QUEM ESTÁ NA CASA'),
        if (space.members.isEmpty)
          const _Notice(
            icon: Icons.cloud_off_outlined,
            title: 'Sem conexão',
            text: 'Não deu para ler quem está na casa. Puxe a tela pra baixo '
                'quando a internet voltar.',
          )
        else
          _Card(
            children: [
              for (final m in space.members)
                _MemberRow(
                  member: m,
                  isMe: m.userId == myId,
                  canRemove: _iAmOwner && m.userId != myId,
                  onRemove: () => _remove(context, ref, m),
                ),
            ],
          ),
        if (_iAmOwner) ...[
          const SizedBox(height: AppSpacing.sm),
          PillButton(
            label: 'Convidar alguém',
            icon: Icons.person_add_alt_1_outlined,
            onPressed: () => showInviteSheet(context, ref),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'O convite é um código que vale por 48 horas e serve para uma '
            'pessoa.',
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const _SectionLabel('O QUE A CASA DIVIDE'),
        _Card(
          children: [
            _InfoRow(
              icon: Icons.shopping_basket_outlined,
              title: 'Listas de compras',
              text: sharedLists == 0
                  ? 'Nenhuma ainda. No menu ⋯ de uma lista, escolha '
                      '"Compartilhar com a casa".'
                  : sharedLists == 1
                      ? '1 lista compartilhada'
                      : '$sharedLists listas compartilhadas',
            ),
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              title: 'Calendário',
              text: calendarOn
                  ? 'Suas refeições de hoje em diante aparecem para todos, e '
                      'as deles no seu calendário.'
                  : 'Desligado. Ligue para ver o que a casa vai cozinhar.',
              trailing: Switch(value: calendarOn, onChanged: setCalendar),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: TextButton.icon(
            onPressed: () => _leave(context, ref),
            icon: Icon(Icons.logout_rounded, color: colors.danger, size: 20),
            label: Text(
              _iAmOwner ? 'Encerrar a casa' : 'Sair da casa',
              style: context.texts.labelLarge?.copyWith(color: colors.danger),
            ),
          ),
        ),
      ],
    );
  }
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
              decoration: BoxDecoration(
                color: colors.ink,
                shape: BoxShape.circle,
                border: isMe ? Border.all(color: colors.lime, width: 2) : null,
              ),
              child: Text(
                _initial(name),
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
