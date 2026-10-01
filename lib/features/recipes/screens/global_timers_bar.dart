import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/services/alarm_driver.dart';
import 'package:receyta/domain/engine/step_duration.dart';
import 'package:receyta/features/recipes/controllers/cooking_alert_settings.dart';
import 'package:receyta/features/recipes/controllers/cooking_timers.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';

/// Faixa de timers do app inteiro (G1): fica fixa no topo de qualquer tela
/// enquanto houver timer de receita rodando ou tocando — você pode sair do
/// modo cozinha, abrir outra receita, olhar a lista de compras, e o relógio
/// continua à vista. Tocar num timer abre o modo cozinha da receita dele.
///
/// Vai no `builder` do `MaterialApp`, por cima do `Navigator`; por isso não
/// usa `Tooltip` nem nada que precise do `Overlay` (ele mora dentro do
/// `Navigator`). Os timers da receita cujo modo cozinha está aberto ficam de
/// fora: ali já existe a faixa grande.
class GlobalTimersBar extends ConsumerWidget {
  const GlobalTimersBar({
    super.key,
    required this.child,
    required this.onOpenRecipe,
  });

  /// O app (o `Navigator`).
  final Widget child;

  /// Abre o modo cozinha da receita.
  final void Function(String recipeId) onOpenRecipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCookingMode = ref.watch(cookingModeRecipeIdProvider);
    final timers = [
      for (final t in ref.watch(cookingTimersProvider))
        if (t.recipeId != inCookingMode) t,
    ];
    final visible = timers.isNotEmpty;
    final media = MediaQuery.of(context);

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: visible
              ? _Bar(timers: timers, onOpenRecipe: onOpenRecipe)
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          // A faixa já ocupou a área da barra de status: pras telas de baixo,
          // o topo seguro é zero enquanto ela está lá. O `MediaQuery` fica
          // sempre na árvore (só muda o valor), então nada perde estado.
          child: MediaQuery(
            data: visible
                ? media.copyWith(
                    padding: media.padding.copyWith(top: 0),
                    viewPadding: media.viewPadding.copyWith(top: 0),
                  )
                : media,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.timers, required this.onOpenRecipe});

  final List<CookingTimer> timers;
  final void Function(String recipeId) onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemBars.onDark,
      child: Material(
        color: colors.ink,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.xs,
              ),
              // O primeiro item são as chaves de aviso (vibrar / som); depois,
              // um por timer.
              itemCount: timers.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) => i == 0
                  ? const TimerAlertToggles()
                  : _TimerPill(
                      timer: timers[i - 1],
                      onOpen: () => onOpenRecipe(timers[i - 1].recipeId),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerPill extends ConsumerWidget {
  const _TimerPill({required this.timer, required this.onOpen});

  final CookingTimer timer;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notifier = ref.read(cookingTimersProvider.notifier);
    final done = timer.isFinished;
    final fg = done ? colors.ink : colors.onSaturated;
    final title = [
      if (timer.recipeName.isNotEmpty) timer.recipeName,
      timer.label,
    ].join(' · ');

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: BoxDecoration(
        color: done ? colors.lime : colors.inkSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Semantics(
              button: true,
              label: 'Abrir modo cozinha: $title',
              excludeSemantics: true,
              child: InkWell(
                onTap: onOpen,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? '$title · Pronto!' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelSmall?.copyWith(
                        color: done ? colors.ink : colors.lime,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      done ? '00:00' : formatTimer(timer.remaining),
                      style: AppTextStyles.display(22).copyWith(
                        color: fg,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (done) ...[
            _PillButton(
              icon: Icons.replay,
              label: 'Repetir',
              color: fg,
              onTap: () => notifier.restart(timer.id),
            ),
            _PillButton(
              icon: Icons.check,
              label: 'Parar',
              color: fg,
              onTap: () => notifier.cancel(timer.id),
            ),
          ] else ...[
            _PillButton(
              icon: timer.isRunning ? Icons.pause : Icons.play_arrow,
              label: timer.isRunning ? 'Pausar' : 'Retomar',
              color: fg,
              onTap: () => notifier.toggle(timer.id),
            ),
            _PillButton(
              icon: Icons.close,
              label: 'Cancelar',
              color: fg.withValues(alpha: 0.7),
              onTap: () => notifier.cancel(timer.id),
            ),
          ],
          const SizedBox(width: AppSpacing.xs / 2),
        ],
      ),
    );
  }
}

/// Botão da pílula (44): ícone sem `Tooltip` — esta faixa vive fora do
/// `Navigator`, sem `Overlay` por perto —, com o rótulo só pra acessibilidade.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}

/// Chaves "vibrar" e "som" do aviso de timer. Ligada, o ícone fica em `lime`;
/// desligada, em vermelho (e com o risco do "off"). Ligar dá uma amostra
/// (vibra / toca); **desligar corta na hora** o que estiver vibrando ou
/// tocando — mutar um alarme que está soando tem que calar o alarme.
///
/// Dois formatos: na faixa global, uma pílula `inkSoft` com as duas chaves; no
/// cartão de um timer do modo cozinha ([embedded]), só os ícones, menores e sem
/// fundo, à direita do relógio. Em cima de um bloco lime ([onAccent], o timer
/// que acabou) o "ligado" vai em `ink`, que lime sobre lime não aparece.
class TimerAlertToggles extends ConsumerWidget {
  const TimerAlertToggles({
    super.key,
    this.embedded = false,
    this.onAccent = false,
  });

  final bool embedded;
  final bool onAccent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(cookingAlertSettingsProvider);
    final notifier = ref.read(cookingAlertSettingsProvider.notifier);
    final driver = ref.read(alarmDriverProvider);
    final onColor = onAccent ? colors.ink : colors.lime;
    final size = embedded ? 40.0 : 44.0;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AlertToggle(
          on: settings.vibrate,
          onIcon: Icons.vibration,
          offIcon: Icons.phone_android,
          label: 'Vibrar ao acabar',
          onColor: onColor,
          offColor: colors.danger,
          size: size,
          onTap: () {
            final next = !settings.vibrate;
            notifier.setVibrate(next);
            if (next) {
              driver.vibrate(preview: true);
            } else {
              driver.stopVibration();
            }
          },
        ),
        _AlertToggle(
          on: settings.sound,
          onIcon: Icons.volume_up,
          offIcon: Icons.volume_off,
          label: 'Tocar som ao acabar',
          onColor: onColor,
          offColor: colors.danger,
          size: size,
          onTap: () {
            final next = !settings.sound;
            notifier.setSound(next);
            if (next) {
              driver.previewSound();
            } else {
              driver.stopSound();
            }
          },
        ),
      ],
    );

    if (embedded) return row;
    return Container(
      decoration: BoxDecoration(
        color: colors.inkSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: row,
    );
  }
}

class _AlertToggle extends StatelessWidget {
  const _AlertToggle({
    required this.on,
    required this.onIcon,
    required this.offIcon,
    required this.label,
    required this.onColor,
    required this.offColor,
    required this.size,
    required this.onTap,
  });

  final bool on;
  final IconData onIcon;
  final IconData offIcon;
  final String label;
  final Color onColor;
  final Color offColor;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = on ? onColor : offColor;
    return Semantics(
      button: true,
      toggled: on,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: size / 2 + 4,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(on ? onIcon : offIcon, size: size * 0.5, color: color),
              // Desligado: um traço cortando o ícone (o "off" que o ícone
              // de vibrar não tem).
              if (!on && onIcon == Icons.vibration)
                Transform.rotate(
                  angle: -0.785,
                  child: Container(
                    width: size * 0.6,
                    height: 2,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
