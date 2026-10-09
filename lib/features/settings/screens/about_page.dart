import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/app_assets.dart';
import 'package:receyta/data/services/app_info.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Sobre o app: logo e versão, o que o Receyta faz, perguntas frequentes e
/// onde ficam os dados. Aberta pelo painel "Sobre" das configurações.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final version = ref.watch(appVersionProvider).valueOrNull ?? '';

    return Scaffold(
      backgroundColor: colors.paper,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _AboutHeader(version: version, onBack: () => context.pop()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suas receitas, do jeito que você cozinha. O Receyta guarda '
                  'o que você gosta de fazer, ajuda a planejar a semana e '
                  'monta a lista de compras sozinho.',
                  style: context.texts.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle('O que dá pra fazer'),
                for (final f in _features) _FeatureRow(feature: f),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle('Perguntas frequentes'),
                const _Faq(),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle('Sua privacidade'),
                Text(
                  'Tudo fica guardado no seu aparelho. Só se você entrar com '
                  'o Google as receitas, as pastas, as listas e as fotos '
                  'passam a ser copiadas para a sua conta, para aparecerem em '
                  'outros aparelhos. Os preços dos ingredientes ficam só no '
                  'aparelho. Não vendemos nem compartilhamos o que você '
                  'guarda.',
                  style: context.texts.bodyMedium
                      ?.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: PillButton(
                    label: 'Avaliar na loja',
                    icon: Icons.star_outline_rounded,
                    variant: PillButtonVariant.secondary,
                    onPressed: () => ref.read(storeLauncherProvider).open(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    'Feito com carinho para quem ama cozinhar',
                    style: context.texts.bodySmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader({required this.version, required this.onBack});

  final String version;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                  motif: TileMotif.arco,
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
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Voltar',
                      background: colors.inkSoft,
                      onTap: onBack,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      label: 'Receyta',
                      image: true,
                      excludeSemantics: true,
                      child: Image.asset(
                        AppAssets.logoFundoPreto,
                        height: 64,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'SOBRE O APP',
                      style: context.texts.labelSmall
                          ?.copyWith(color: colors.lime),
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      version.isEmpty ? 'Receyta' : 'Versão $version',
                      style: AppTextStyles.display(30)
                          .copyWith(color: colors.onSaturated),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.display(24).copyWith(color: context.colors.ink),
      ),
    );
  }
}

typedef _Feature = (IconData, String, String);

const List<_Feature> _features = [
  (
    Icons.menu_book_outlined,
    'Receitas e pastas',
    'Crie, importe de um link ou de uma foto e organize com pastas e tags.',
  ),
  (
    Icons.timer_outlined,
    'Modo cozinha',
    'Passo a passo em tela cheia, com timers que avisam mesmo minimizado.',
  ),
  (
    Icons.calendar_month_outlined,
    'Agenda de refeições',
    'Planeje a semana e receba um lembrete para não esquecer.',
  ),
  (
    Icons.shopping_basket_outlined,
    'Listas de compras',
    'Junta os ingredientes das receitas planejadas e soma as quantidades.',
  ),
  (
    Icons.kitchen_outlined,
    'Despensa',
    'Marque o que você já tem e veja o que dá pra fazer agora.',
  ),
  (
    Icons.payments_outlined,
    'Custo estimado',
    'Informe o preço dos ingredientes e veja quanto custa cada receita e a '
        'semana.',
  ),
  (
    Icons.auto_graph,
    'Retrospectiva e coleções',
    'Seu mês e seu ano na cozinha, e listas que se montam sozinhas.',
  ),
  (
    Icons.cloud_sync_outlined,
    'Conta e sincronização',
    'Entre com o Google para ter tudo em mais de um aparelho.',
  ),
];

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.paper,
              shape: BoxShape.circle,
              border: Border.all(color: colors.ink, width: 1.5),
            ),
            child: Icon(feature.$1, size: 20, color: colors.ink),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.$2,
                  style: context.texts.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  feature.$3,
                  style: context.texts.bodySmall
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

typedef _Qa = (String, String);

const List<_Qa> _faq = [
  (
    'Preciso de conta para usar o Receyta?',
    'Não. O app funciona inteiro sem conta, com tudo salvo só no seu '
        'aparelho. A conta é opcional e serve para ter os dados em mais de '
        'um aparelho.',
  ),
  (
    'Como trago receitas de outros lugares?',
    'Na aba de receitas, toque no + e escolha importar de um link ou de '
        'uma foto, ou abra um arquivo de backup do Receyta.',
  ),
  (
    'Troquei de celular. Como levo minhas receitas?',
    'Entre com a mesma conta do Google no aparelho novo: receitas, pastas, '
        'listas e fotos voltam sozinhas (os preços dos ingredientes ficam só '
        'no aparelho e precisam ser informados de novo). Sem conta, faça um '
        'backup nos ajustes e abra o arquivo no aparelho novo.',
  ),
  (
    'Apaguei uma receita sem querer. E agora?',
    'Ela vai para a lixeira e fica lá por 30 dias. Dá para restaurar '
        'antes disso.',
  ),
  (
    'Quanto espaço as fotos ocupam?',
    'As fotos são reduzidas para ocupar pouco. Cada conta tem 30 MB para '
        'fotos na nuvem; passou disso, a foto fica só no aparelho. Você vê '
        'o quanto usou na aba Conta.',
  ),
  (
    'Os timers tocam com o app fechado?',
    'Sim, o aviso chega mesmo com o app minimizado. Vibração e som podem '
        'ser ajustados em Configurações > Timers e lembretes.',
  ),
  (
    'Como apago meus dados?',
    'Em Configurações > Zona de risco você limpa o aparelho, apaga também '
        'o que está na nuvem ou exclui a conta.',
  ),
];

/// Perguntas que abrem e fecham, uma por vez.
class _Faq extends StatefulWidget {
  const _Faq();

  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paperSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _faq.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1.5, color: colors.paper),
            _FaqTile(
              question: _faq[i].$1,
              answer: _faq[i].$2,
              open: _open == i,
              onTap: () => setState(() => _open = _open == i ? null : i),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.open,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label: question,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: context.texts.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Text(
                    answer,
                    style: context.texts.bodyMedium
                        ?.copyWith(color: colors.textMuted),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
