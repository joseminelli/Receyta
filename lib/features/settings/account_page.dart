import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/state_badge.dart';

/// 4ª aba da `PillNavBar` (§9.2) — a única com `paper`/`diagonal`: as outras
/// três (coral/violet/lime) pintam o miolo do pill, mas a barra em si já é
/// `ink` (§9.8), então um item `ink` ficaria invisível quando selecionado.
/// `paper` inverte (pill claro no fundo escuro) e ainda fecha o quarteto de
/// cores do §9.2.
///
/// Formato já pensado pro login/sincronização do bloco H: cabeçalho com o
/// botão de engrenagem (leva pra `/settings`, onde moram Backup e Limpar
/// dados) + bloco de perfil no corpo — hoje só um placeholder de "sem
/// login", depois vira avatar/nome/e-mail de verdade sem precisar redesenhar
/// a aba.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.screen,
              AppSpacing.screen,
              0,
            ),
            child: Row(
              children: [
                Text('Conta', style: context.texts.displaySmall),
                const Spacer(),
                CircleIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: 'Configurações',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StateBadge(
                      icon: Icons.person_outline,
                      background: colors.violetMuted,
                      foreground: colors.ink,
                      size: 72,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Sem login por enquanto', style: context.texts.displaySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Seus dados ficam só neste aparelho. Login e '
                      'sincronização entre dispositivos chegam mais pra '
                      'frente.',
                      style: context.texts.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
