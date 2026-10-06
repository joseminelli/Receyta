import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';

/// Conteúdo padrão de um modal de baixo (a folha em si — fundo, cantos e alça
/// — vem do `BottomSheetThemeData` do tema). Título grande na fonte de
/// display, um subtítulo opcional e o [child] (normalmente uma lista de
/// [AppSheetOption]). Cuida da área segura e do respiro de baixo.
class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
  });

  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) Text(title!, style: AppTextStyles.display(30)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style:
                    context.texts.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ],
            if (title != null || subtitle != null)
              const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

/// Uma opção de um [AppSheetFrame]: medalhão `ink` com o ícone em `lime` (o
/// mesmo par dos atalhos da aba Conta), título em display e subtítulo
/// opcional. [danger] pinta o medalhão e o título de perigo; [selected] põe um
/// check no fim (escolha atual de uma lista). Linhas separadas por um fio —
/// use [AppSheetOptions] pra empilhar com os fios.
class AppSheetOption extends StatelessWidget {
  const AppSheetOption({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.danger = false,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: danger ? colors.danger : colors.ink,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: danger ? colors.onSaturated : colors.lime,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.display(23).copyWith(
                        color: danger ? colors.danger : colors.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.texts.bodyMedium
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, color: colors.ink)
              else
                Icon(Icons.arrow_forward_rounded, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empilha [AppSheetOption]s com um fio `paperSoft` entre elas.
class AppSheetOptions extends StatelessWidget {
  const AppSheetOptions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(height: 1, thickness: 1.5, color: colors.paperSoft),
          children[i],
        ],
      ],
    );
  }
}
