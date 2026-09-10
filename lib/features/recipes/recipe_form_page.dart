import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tag_name.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/section_header.dart';

/// Formulário de receita (RF-01.2–01.5): nome, sobre, tempos, rendimento,
/// notas, e as listas de ingredientes e passos como texto livre. Cria quando
/// [recipeId] é nulo, edita caso contrário. Superfície sóbria, sem azulejo
/// nem número ilustrativo (§9.1).
class RecipeFormPage extends ConsumerWidget {
  const RecipeFormPage({super.key, this.recipeId});

  final String? recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = recipeId;
    if (id == null) return const _RecipeForm(original: null);

    return ref.watch(recipeDetailFutureProvider(id)).when(
          loading: () => const _Frame(child: SizedBox.shrink()),
          error: (_, __) => _Frame(
            child: Center(
              child: Text(
                'Receita não encontrada',
                style: context.texts.bodyMedium,
              ),
            ),
          ),
          data: (detail) => _RecipeForm(original: detail),
        );
  }
}

class _Line {
  _Line(String text) : controller = TextEditingController(text: text);
  final TextEditingController controller;
  final key = UniqueKey();
}

class _RecipeForm extends ConsumerStatefulWidget {
  const _RecipeForm({required this.original});

  final RecipeDetail? original;

  @override
  ConsumerState<_RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends ConsumerState<_RecipeForm> {
  late final _recipe = widget.original?.recipe;
  late final _name = TextEditingController(text: _recipe?.name ?? '');
  late final _about = TextEditingController(text: _recipe?.about ?? '');
  late final _prep = TextEditingController(
    text: _recipe?.prepMinutes?.toString() ?? '',
  );
  late final _cook = TextEditingController(
    text: _recipe?.cookMinutes?.toString() ?? '',
  );
  late final _servings = TextEditingController(
    text: _recipe?.servings?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: _recipe?.notes ?? '');

  late final List<_Line> _ingredients = [
    for (final RecipeIngredient i
        in widget.original?.ingredients ?? const <RecipeIngredient>[])
      _Line(i.rawText),
  ];
  late final List<_Line> _steps = [
    for (final RecipeStep s
        in widget.original?.steps ?? const <RecipeStep>[])
      _Line(s.text),
  ];

  late final List<String> _tags = [
    for (final Tag t in widget.original?.tags ?? const <Tag>[]) t.name,
  ];
  final _tagInput = TextEditingController();
  final _tagFocus = FocusNode();

  bool _saving = false;

  bool get _isEditing => _recipe != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _about, _prep, _cook, _servings, _notes]) {
      c.dispose();
    }
    for (final l in [..._ingredients, ..._steps]) {
      l.controller.dispose();
    }
    _tagInput.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    _tagInput.clear();
    final names = [
      for (final part in raw.split(',')) canonicalTagName(part),
    ].where((n) => n.isNotEmpty && !_tags.contains(n)).toList();
    if (names.isEmpty) return;
    setState(() => _tags.addAll(names));
  }

  void _removeTag(String name) => setState(() => _tags.remove(name));

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref.read(recipeFormViewModelProvider).submit(
          original: _recipe,
          name: _name.text,
          about: _about.text,
          prepText: _prep.text,
          cookText: _cook.text,
          servingsText: _servings.text,
          notes: _notes.text,
          ingredientLines: [for (final l in _ingredients) l.controller.text],
          stepLines: [for (final l in _steps) l.controller.text],
          tagNames: [..._tags, _tagInput.text],
        );
    if (!mounted) return;
    result.when(
      ok: (_) => context.pop(),
      err: (f) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message)));
      },
    );
  }

  void _reorder(List<_Line> list, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      list.insert(newIndex, list.removeAt(oldIndex));
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _name.text.trim().isNotEmpty && !_saving;

    return _Frame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            title: _isEditing ? 'Editar receita' : 'Nova receita',
            onSave: canSave ? _save : null,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                AppSpacing.xxl,
              ),
              children: [
                _Field(
                  label: 'Nome',
                  controller: _name,
                  autofocus: !_isEditing,
                ),
                _Field(label: 'Sobre', controller: _about, maxLines: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Preparo (min)',
                        controller: _prep,
                        numeric: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Field(
                        label: 'Cozimento (min)',
                        controller: _cook,
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                _Field(
                  label: 'Rende (porções)',
                  controller: _servings,
                  numeric: true,
                ),
                _TagsField(
                  tags: _tags,
                  controller: _tagInput,
                  focusNode: _tagFocus,
                  onAdd: _addTag,
                  onRemove: _removeTag,
                ),
                const SizedBox(height: AppSpacing.md),
                _LineList(
                  title: 'Ingredientes',
                  addLabel: 'Adicionar ingrediente',
                  hintFor: (i) => 'ex.: 2 xícaras de farinha',
                  lines: _ingredients,
                  onAdd: () => setState(() => _ingredients.add(_Line(''))),
                  onRemove: (i) => setState(() {
                    _ingredients.removeAt(i).controller.dispose();
                  }),
                  onReorder: (o, n) => _reorder(_ingredients, o, n),
                ),
                const SizedBox(height: AppSpacing.lg),
                _LineList(
                  title: 'Passos',
                  addLabel: 'Adicionar passo',
                  hintFor: (i) => 'Passo ${i + 1}',
                  lines: _steps,
                  onAdd: () => setState(() => _steps.add(_Line(''))),
                  onRemove: (i) => setState(() {
                    _steps.removeAt(i).controller.dispose();
                  }),
                  onReorder: (o, n) => _reorder(_steps, o, n),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Field(label: 'Notas', controller: _notes, maxLines: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: SafeArea(child: child),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onSave});

  final String title;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.arrow_back),
            color: context.colors.ink,
          ),
          Expanded(child: Text(title, style: context.texts.displaySmall)),
          PillButton(label: 'Salvar', onPressed: onSave),
        ],
      ),
    );
  }
}

/// Campo de tags (§RF-01.10): pills removíveis + entrada com autocomplete das
/// tags já existentes. Enter ou tocar numa sugestão adiciona; a normalização
/// (minúsculas, dedupe) é do [RecipeFormViewModel].
class _TagsField extends ConsumerWidget {
  const _TagsField({
    required this.tags,
    required this.controller,
    required this.focusNode,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> tags;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = ref.watch(allTagsProvider).valueOrNull ?? const <Tag>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TAGS', style: context.texts.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final t in tags)
                    _RemovableChip(label: t, onRemove: () => onRemove(t)),
                ],
              ),
            ),
          RawAutocomplete<String>(
            textEditingController: controller,
            focusNode: focusNode,
            optionsBuilder: (value) {
              final q = value.text.trim().toLowerCase();
              if (q.isEmpty) return const Iterable<String>.empty();
              return known
                  .map((t) => t.name)
                  .where((n) => n.toLowerCase().contains(q) && !tags.contains(n));
            },
            onSelected: onAdd,
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'rápido, frango, sobremesa — enter separa',
                ),
                onSubmitted: (value) {
                  onAdd(value);
                  focusNode.requestFocus();
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: context.colors.paperSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 180,
                      maxWidth: 280,
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        for (final option in options)
                          InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                option,
                                style: context.texts.bodyMedium,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paperSoft,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.texts.labelLarge?.copyWith(color: colors.ink),
              ),
              const SizedBox(width: AppSpacing.xs / 2),
              Icon(Icons.close, size: 16, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.numeric = false,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool numeric;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: context.texts.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: controller,
            autofocus: autofocus,
            maxLines: maxLines,
            keyboardType: numeric
                ? TextInputType.number
                : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
            textCapitalization: numeric
                ? TextCapitalization.none
                : TextCapitalization.sentences,
            inputFormatters:
                numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          ),
        ],
      ),
    );
  }
}

class _LineList extends StatelessWidget {
  const _LineList({
    required this.title,
    required this.addLabel,
    required this.hintFor,
    required this.lines,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  final String title;
  final String addLabel;
  final String Function(int index) hintFor;
  final List<_Line> lines;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.sm),
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Nada ainda.',
              style: context.texts.bodyMedium,
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: lines.length,
            onReorder: onReorder,
            itemBuilder: (context, i) {
              final line = lines[i];
              return Padding(
                key: line.key,
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: Icon(
                        Icons.drag_indicator,
                        color: context.colors.textMuted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs / 2),
                    Expanded(
                      child: TextField(
                        controller: line.controller,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(hintText: hintFor(i)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemove(i),
                      icon: const Icon(Icons.close),
                      color: context.colors.textMuted,
                      tooltip: 'Remover',
                    ),
                  ],
                ),
              );
            },
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: PillButton(
            label: addLabel,
            icon: Icons.add,
            variant: PillButtonVariant.secondary,
            onPressed: onAdd,
          ),
        ),
      ],
    );
  }
}
