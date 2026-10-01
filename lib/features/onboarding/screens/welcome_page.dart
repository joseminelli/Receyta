import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/features/onboarding/controllers/onboarding_seen.dart';
import 'package:receyta/features/onboarding/controllers/tutorial.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Introdução de primeiro uso: três telas curtas (receitas, semana, compras)
/// no mesmo desenho do app — bloco com a cor e a textura da seção em cima e,
/// por cima dele, um cartão claro com um exemplo de verdade do recurso. Aparece
/// uma vez só; "Pular" e "Começar" levam à home.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _controller = PageController();
  int _page = 0;

  static const _last = 2;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboardingSeen();
    await markTutorialPending();
    if (mounted) context.go('/');
  }

  void _next() {
    if (_page >= _last) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final slides = [
      _SlideData(
        color: TileColor.coral,
        motif: TileMotif.arco,
        title: 'Suas receitas, num lugar só',
        body: 'Digite, importe de um link, de uma foto ou de um arquivo. '
            'Tudo fica guardado no seu aparelho.',
        mock: const _RecipeMock(),
      ),
      _SlideData(
        color: TileColor.violet,
        motif: TileMotif.meiaLua,
        title: 'Planeje a semana',
        body: 'Escolha o que cozinhar em cada dia e veja o mês de relance. '
            'Sem decidir tudo na hora da fome.',
        mock: const _WeekMock(),
      ),
      _SlideData(
        color: TileColor.ink,
        motif: TileMotif.ponto,
        title: 'Compras sem conta de cabeça',
        body: 'A lista sai das receitas, com as quantidades já somadas. No '
            'modo cozinha, os timers ficam à vista até com o app minimizado.',
        mock: const _ShoppingMock(),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [for (final s in slides) _Slide(data: s)],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _page ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? colors.ink : colors.paperSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (_page != _last)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Pular'),
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  PillButton(
                    label: _page == _last ? 'Começar' : 'Próximo',
                    icon: _page == _last ? null : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.color,
    required this.motif,
    required this.title,
    required this.body,
    required this.mock,
  });

  final TileColor color;
  final TileMotif motif;
  final String title;
  final String body;
  final Widget mock;
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data});

  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = resolveTileAppearance(
      colors,
      color: data.color,
      motif: data.motif,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 11,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadii.lg + 10),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                TilePattern(
                  motif: tile.motif,
                  background: tile.background,
                  patternColor: tile.patternColor,
                  patternColorAlt: tile.patternColorAlt,
                  tile: 72,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xxl,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: Material(
                      color: colors.paperSoft,
                      elevation: 6,
                      shadowColor: Colors.black54,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: data.mock,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: AppTextStyles.display(36)),
                const SizedBox(height: AppSpacing.sm),
                Text(data.body, style: context.texts.bodyLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Exemplo de card de receita.
class _RecipeMock extends StatelessWidget {
  const _RecipeMock();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FRANGO AO CURRY',
          style: context.texts.labelSmall?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Frango ao curry', style: AppTextStyles.display(30)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text('15', style: AppTextStyles.display(34)),
            Text(' m preparo', style: context.texts.bodyMedium),
            const SizedBox(width: AppSpacing.md),
            Text('25', style: AppTextStyles.display(34)),
            Text(' m fogão', style: context.texts.bodyMedium),
          ],
        ),
      ],
    );
  }
}

/// Exemplo da semana: dia + prato.
class _WeekMock extends StatelessWidget {
  const _WeekMock();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget row(String day, String dish) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  day,
                  style: context.texts.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ),
              Expanded(
                child: Text(dish, style: AppTextStyles.display(20)),
              ),
            ],
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row('SEG', 'Homus com pão sírio'),
        Divider(height: 1, color: colors.paper),
        row('QUA', 'Frango ao curry'),
        Divider(height: 1, color: colors.paper),
        row('SEX', 'Sopa de abóbora'),
      ],
    );
  }
}

/// Exemplo de lista de compras com itens marcados.
class _ShoppingMock extends StatelessWidget {
  const _ShoppingMock();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget row(String text, {bool done = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: done ? colors.ink : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.ink, width: 1.6),
                ),
                child: done
                    ? Icon(Icons.check, size: 14, color: colors.lime)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                text,
                style: AppTextStyles.display(20).copyWith(
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? colors.textMuted : colors.ink,
                ),
              ),
            ],
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('1,3 kg de farinha', done: true),
        row('3 ovos'),
        row('400 g de tomate'),
      ],
    );
  }
}
