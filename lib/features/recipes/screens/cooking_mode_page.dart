import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:receyta/domain/engine/step_duration.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/features/recipes/controllers/cooking_timers.dart';
import 'package:receyta/features/recipes/screens/global_timers_bar.dart'
    show TimerAlertToggles;
import 'package:receyta/features/recipes/controllers/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/sweep_strike_text.dart';

/// Modo cozinha mínimo (RF-01.11 / G1 parcial): superfície escura reaproveitada
/// de Compras, tela que não apaga (wakelock), passos numa lista de corpo grande
/// que você rola com a mão suja, ingredientes num toque no topo e timers (G1):
/// um do tempo de cozimento da receita e um botão em cada tempo que o texto do
/// passo menciona ("20 minutos"). Os timers rodando ficam numa faixa no
/// rodapé. Escala de porção é o G2.
class CookingModePage extends ConsumerStatefulWidget {
  const CookingModePage({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<CookingModePage> createState() => _CookingModePageState();
}

class _CookingModePageState extends ConsumerState<CookingModePage> {
  final _ingredientsOpen = ValueNotifier<bool>(true);
  final _doneNotifiers = <int, ValueNotifier<bool>>{};

  /// Tempos achados em cada texto de passo — procurar é regex, então guarda
  /// (a lista de passos reconstrói ao rolar).
  final _durationsByText = <String, List<StepDuration>>{};

  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _setWakelock(true);
    // A faixa global de timers esconde os desta receita enquanto o modo
    // cozinha dela está aberto (aqui já tem a faixa grande). Mexer num
    // provider durante o build não pode: vai pro fim do quadro.
    _container = ProviderScope.containerOf(context, listen: false);
    Future.microtask(
      () => _container.read(cookingModeRecipeIdProvider.notifier).state =
          widget.recipeId,
    );
  }

  @override
  void dispose() {
    final container = _container;
    Future.microtask(() {
      try {
        final notifier = container.read(cookingModeRecipeIdProvider.notifier);
        if (notifier.state == widget.recipeId) notifier.state = null;
      } catch (_) {
        // Container já descartado (fim do app/teste): nada a limpar.
      }
    });
    _setWakelock(false);
    _ingredientsOpen.dispose();
    for (final n in _doneNotifiers.values) {
      n.dispose();
    }
    super.dispose();
  }

  /// O plugin não existe em teste nem na web — falha silenciosa é aceitável,
  /// manter a tela ligada é conveniência, não correção.
  Future<void> _setWakelock(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (_) {}
  }

  /// Um `ValueNotifier` por passo: tocar um cartão só reconstrói aquele
  /// cartão (via `ValueListenableBuilder`), não a página inteira.
  ValueNotifier<bool> _doneNotifierFor(int index) =>
      _doneNotifiers.putIfAbsent(index, () => ValueNotifier(false));

  /// Passo em cartão + subtítulo de grupo (§RF-01.4) quando muda em relação
  /// ao passo anterior. Chamado sob demanda pelo `SliverChildBuilderDelegate`
  /// — só os passos visíveis (+ cache) chegam a ser construídos.
  Widget _stepItem(List<RecipeStep> steps, int i, String recipeName) {
    final g = steps[i].groupLabel;
    final prevGroup = i > 0 ? steps[i - 1].groupLabel : null;
    final showGroupLabel = g != prevGroup && g != null && g.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showGroupLabel)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: _GroupLabel(g),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _StepCard(
            recipeId: widget.recipeId,
            recipeName: recipeName,
            index: i,
            text: steps[i].text,
            durations: _durationsByText.putIfAbsent(
              steps[i].text,
              () => findStepDurations(steps[i].text),
            ),
            doneListenable: _doneNotifierFor(i),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemBars.onDark,
      child: Scaffold(
        backgroundColor: context.colors.ink,
        body: ref.watch(recipeDetailProvider(widget.recipeId)).when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const _Message(text: 'Receita não encontrada'),
              data: (detail) => detail == null
                  ? const _Message(text: 'Receita não encontrada')
                  : _buildBody(context, detail),
            ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RecipeDetail detail) {
    return SafeArea(
      child: Column(
        children: [
          _TopBar(name: detail.recipe.name),
          const _WakeTip(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildIntroSliver(context, detail),
                if (detail.steps.isNotEmpty) _buildStepsSliver(detail),
              ],
            ),
          ),
          _TimersDock(recipeId: widget.recipeId),
        ],
      ),
    );
  }

  Widget _buildIntroSliver(BuildContext context, RecipeDetail detail) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((detail.recipe.cookMinutes ?? 0) > 0) ...[
              _CookTimerCard(
                recipeId: widget.recipeId,
                recipeName: detail.recipe.name,
                minutes: detail.recipe.cookMinutes!,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _IngredientsCard(
              ingredients: detail.ingredients,
              openListenable: _ingredientsOpen,
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel('Preparo'),
            const SizedBox(height: AppSpacing.md),
            if (detail.steps.isEmpty)
              Text(
                'Esta receita não tem passos.',
                style: context.texts.bodyLarge
                    ?.copyWith(color: context.colors.textBody),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSliver(RecipeDetail detail) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _stepItem(detail.steps, i, detail.recipe.name),
          childCount: detail.steps.length,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
            color: colors.onSaturated,
            tooltip: 'Sair',
          ),
          Expanded(
            child: Text(
              name,
              style: context.texts.titleMedium
                  ?.copyWith(color: colors.onSaturated),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso visível de que a tela não vai apagar durante o preparo (RF-01.11).
class _WakeTip extends StatelessWidget {
  const _WakeTip();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline,
              size: 14, color: colors.lime.withValues(alpha: 0.8)),
          const SizedBox(width: AppSpacing.xs / 2),
          Text(
            'A tela fica acesa enquanto você cozinha',
            style: context.texts.labelSmall?.copyWith(
              color: colors.onSaturated.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ingredientes no topo, recolhíveis: abertos por padrão, um toque some com
/// eles quando você já separou tudo.
class _IngredientsCard extends StatelessWidget {
  const _IngredientsCard({
    required this.ingredients,
    required this.openListenable,
  });

  final List<RecipeIngredient> ingredients;
  final ValueNotifier<bool> openListenable;

  /// Linhas + subtítulos de grupo (§RF-01.4), no tom escuro do modo cozinha.
  List<Widget> _rows(BuildContext context) {
    final colors = context.colors;
    final out = <Widget>[];
    String? last;
    for (final i in ingredients) {
      final g = i.groupLabel;
      if (g != last && g != null && g.isNotEmpty) {
        out.add(Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.xs / 2,
          ),
          child: _GroupLabel(g),
        ));
      }
      last = g;
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          i.rawText,
          style: context.texts.bodyLarge?.copyWith(
            color: colors.onSaturated,
            height: 1.35,
          ),
        ),
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<bool>(
      valueListenable: openListenable,
      builder: (context, open, _) => Container(
        decoration: BoxDecoration(
          color: colors.inkSoft,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => openListenable.value = !open,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Text(
                      'INGREDIENTES',
                      style: context.texts.labelSmall
                          ?.copyWith(color: colors.lime),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${ingredients.length}',
                      style: context.texts.labelSmall?.copyWith(
                        color: colors.onSaturated.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: colors.onSaturated.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ingredients.isEmpty)
                      Text(
                        'Nenhum ingrediente cadastrado.',
                        style: context.texts.bodyMedium
                            ?.copyWith(color: colors.textBody),
                      )
                    else
                      ..._rows(context),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.texts.labelSmall?.copyWith(color: context.colors.lime),
    );
  }
}

/// Subtítulo de grupo (§RF-01.4) dentro de ingredientes ou passos: fonte
/// display em `lime` (acento do modo cozinha) com traço embaixo, grande pra ler
/// de longe no fogão.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.lime, width: 3)),
        ),
        child: Text(
          text,
          style: AppTextStyles.display(21).copyWith(color: colors.lime),
        ),
      ),
    );
  }
}

/// Passo em cartão largo, número em escala grande. Toque marca como feito —
/// o cartão recua e o texto risca, pra achar onde parou de relance. Cada tempo
/// que o texto menciona vira um botão de timer embaixo do texto.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.recipeId,
    required this.recipeName,
    required this.index,
    required this.text,
    required this.durations,
    required this.doneListenable,
  });

  final String recipeId;
  final String recipeName;
  final int index;
  final String text;
  final List<StepDuration> durations;
  final ValueNotifier<bool> doneListenable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final number = index + 1;
    return ValueListenableBuilder<bool>(
      valueListenable: doneListenable,
      builder: (context, done, _) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: () => doneListenable.value = !done,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: done ? colors.ink : colors.inkSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: AppTextStyles.display(40).copyWith(
                      color: done
                          ? colors.onSaturated.withValues(alpha: 0.25)
                          : colors.lime,
                    ),
                    child: Text('$number'.padLeft(2, '0')),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                        child: SweepStrikeText(
                          text: text,
                          done: done,
                          style: context.texts.bodyLarge?.copyWith(
                            color: done
                                ? colors.onSaturated.withValues(alpha: 0.4)
                                : colors.onSaturated,
                            fontSize: 20,
                            height: 1.4,
                          ),
                          lineColor: colors.onSaturated.withValues(alpha: 0.4),
                        ),
                      ),
                      if (durations.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (var k = 0; k < durations.length; k++)
                              _DurationChip(
                                recipeId: recipeId,
                                recipeName: recipeName,
                                timerKey: 'step-$index-$k',
                                label: 'Passo $number',
                                duration: durations[k],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão de timer de um tempo achado no passo: "⏱ 20 min". Sem timer ainda,
/// toque inicia; com timer, vira o relógio ao vivo e o toque pausa/retoma (ou
/// reinicia, se já acabou). Grande o bastante pra acertar de mão suja.
class _DurationChip extends ConsumerWidget {
  const _DurationChip({
    required this.recipeId,
    required this.recipeName,
    required this.timerKey,
    required this.label,
    required this.duration,
  });

  final String recipeId;
  final String recipeName;
  final String timerKey;
  final String label;
  final StepDuration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final timer = ref
        .watch(cookingTimersProvider)
        .where((t) => t.recipeId == recipeId && t.key == timerKey)
        .firstOrNull;
    final notifier = ref.read(cookingTimersProvider.notifier);

    final IconData icon;
    final String text;
    if (timer == null) {
      icon = Icons.timer_outlined;
      text = duration.label;
    } else if (timer.isFinished) {
      icon = Icons.alarm_on;
      text = 'Pronto';
    } else if (timer.isRunning) {
      icon = Icons.pause;
      text = formatTimer(timer.remaining);
    } else {
      icon = Icons.play_arrow;
      text = formatTimer(timer.remaining);
    }
    final active = timer != null;

    return Material(
      color: active ? colors.lime : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: colors.lime, width: 1.5),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          if (timer == null) {
            notifier.start(
              recipeId: recipeId,
              recipeName: recipeName,
              label: label,
              duration: duration.duration,
              key: timerKey,
            );
          } else if (timer.isFinished) {
            notifier.restart(timer.id);
          } else {
            notifier.toggle(timer.id);
          }
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active ? colors.ink : colors.lime,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  text,
                  style: context.texts.titleMedium?.copyWith(
                    color: active ? colors.ink : colors.lime,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão do tempo de cozimento da receita (`cookMinutes`) no topo: um toque
/// inicia o timer. Com o timer rodando, o controle fica na faixa do rodapé e
/// aqui só aparece que está em andamento.
class _CookTimerCard extends ConsumerWidget {
  const _CookTimerCard({
    required this.recipeId,
    required this.recipeName,
    required this.minutes,
  });

  final String recipeId;
  final String recipeName;
  final int minutes;

  static const _key = 'cook';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final timer = ref
        .watch(cookingTimersProvider)
        .where((t) => t.recipeId == recipeId && t.key == _key)
        .firstOrNull;
    final running = timer != null;
    final total = Duration(minutes: minutes);

    return Material(
      color: colors.inkSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: running
            ? null
            : () => ref.read(cookingTimersProvider.notifier).start(
                  recipeId: recipeId,
                  recipeName: recipeName,
                  label: 'Cozimento',
                  duration: total,
                  key: _key,
                ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                running ? Icons.hourglass_top : Icons.local_fire_department,
                color: colors.lime,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COZIMENTO',
                      style: context.texts.labelSmall
                          ?.copyWith(color: colors.lime),
                    ),
                    Text(
                      running
                          ? 'Timer em andamento'
                          : '${formatTimer(total)} · toque pra iniciar',
                      style: context.texts.bodyLarge?.copyWith(
                        color: colors.onSaturated,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!running)
                Icon(Icons.play_circle_fill, color: colors.lime, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa fixa no rodapé com os timers desta receita (vários ao mesmo tempo).
/// Cada linha: de onde veio, o relógio grande, pausar/retomar e cancelar; o
/// que acabou vira um bloco lime ("Pronto!") com "Parar" e "+ Repetir".
class _TimersDock extends ConsumerWidget {
  const _TimersDock({required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timers = [
      for (final t in ref.watch(cookingTimersProvider))
        if (t.recipeId == recipeId) t,
    ];
    if (timers.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;

    return Container(
      constraints: const BoxConstraints(maxHeight: 210),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.ink,
        border: Border(
          top: BorderSide(
            color: colors.onSaturated.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: timers.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, i) => _TimerRow(timer: timers[i]),
      ),
    );
  }
}

class _TimerRow extends ConsumerWidget {
  const _TimerRow({required this.timer});

  final CookingTimer timer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notifier = ref.read(cookingTimersProvider.notifier);
    final done = timer.isFinished;
    final fg = done ? colors.ink : colors.onSaturated;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: done ? colors.lime : colors.inkSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          // À esquerda, as chaves de vibrar / som; à direita, pausar e
          // cancelar — cada grupo de um lado do relógio, no mesmo cartão.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? '${timer.label} · Pronto!' : timer.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelMedium?.copyWith(
                    color: done ? colors.ink : colors.lime,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  done ? '00:00' : formatTimer(timer.remaining),
                  style: AppTextStyles.display(34).copyWith(
                    color: fg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          TimerAlertToggles(embedded: true, onAccent: done),
          const SizedBox(width: AppSpacing.xs),
          if (done) ...[
            _DockButton(
              icon: Icons.replay,
              tooltip: 'Repetir',
              color: fg,
              onTap: () => notifier.restart(timer.id),
            ),
            _DockButton(
              icon: Icons.check,
              tooltip: 'Parar',
              color: fg,
              onTap: () => notifier.cancel(timer.id),
            ),
          ] else ...[
            _DockButton(
              icon: timer.isRunning ? Icons.pause : Icons.play_arrow,
              tooltip: timer.isRunning ? 'Pausar' : 'Retomar',
              color: fg,
              onTap: () => notifier.toggle(timer.id),
            ),
            _DockButton(
              icon: Icons.close,
              tooltip: 'Cancelar',
              color: fg.withValues(alpha: 0.7),
              onTap: () => notifier.cancel(timer.id),
            ),
          ],
        ],
      ),
    );
  }
}

/// Botão redondo e grande (48) da faixa de timers.
class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      iconSize: 28,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Icon(icon, color: color),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: context.texts.bodyLarge
              ?.copyWith(color: context.colors.onSaturated),
        ),
      ),
    );
  }
}
