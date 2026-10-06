import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import 'package:receyta/core/result.dart';
import 'package:receyta/core/tag_name.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';
import 'package:receyta/features/recipes/controllers/recipe_form_view_model.dart';
import 'package:receyta/features/recipes/screens/recipe_photo_flow.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/domain/engine/ingredient_parser.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/domain/engine/fuzzy_match.dart';
import 'package:receyta/domain/engine/ingredient_normalizer.dart';
import 'package:receyta/domain/engine/recipe_import.dart';

/// Formulário de receita (RF-01.2–01.5): nome, sobre, tempos, rendimento,
/// notas, e as listas de ingredientes e passos como texto livre. Cria quando
/// [recipeId] é nulo, edita caso contrário. Superfície sóbria, sem azulejo
/// nem número ilustrativo (§9.1).
class RecipeFormPage extends ConsumerWidget {
  const RecipeFormPage({super.key, this.recipeId, this.draft});

  final String? recipeId;

  /// Rascunho de uma importação por URL (C7) ou foto (C8) — pré-preenche o
  /// formulário de uma receita nova; nada é salvo até o usuário tocar em
  /// salvar, igual à digitação manual.
  final ImportedRecipe? draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = recipeId;
    if (id == null) return _RecipeForm(original: null, draft: draft);

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

/// Uma linha da lista de ingredientes ou passos. Quando [heading], é um
/// separador de seção ("Para a massa") e não vira uma linha própria no banco —
/// vira o `groupLabel` das linhas abaixo dela.
class _Line {
  _Line(String text, {this.heading = false, this.ingredientId})
      : controller = TextEditingController(text: text),
        _appliedText = ingredientId != null ? text : null;
  final TextEditingController controller;
  final FocusNode focusNode = FocusNode();
  final bool heading;
  final key = UniqueKey();

  /// Ingrediente escolhido no autocomplete (C3). Só vale enquanto o texto da
  /// linha não muda depois da escolha (ver [_appliedText]).
  String? ingredientId;
  String? _appliedText;

  bool get hasValidIngredientId =>
      ingredientId != null && controller.text == _appliedText;

  void applyIngredientSuggestion(Ingredient picked, String originalText) {
    final parsed = parseIngredientLine(originalText);
    final newText = parsed.name.isEmpty
        ? picked.displayName
        : _replaceLast(originalText, parsed.name, picked.displayName);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    ingredientId = picked.id;
    _appliedText = newText;
  }

  static String _replaceLast(String text, String target, String replacement) {
    final idx = text.lastIndexOf(target);
    if (idx == -1) return replacement;
    return text.replaceRange(idx, idx + target.length, replacement);
  }
}

/// Linhas de um rascunho importado (C7) pro mesmo formato de
/// `_linesWithHeadings`. Alguns sites embutem o cabeçalho da seção como se
/// fosse mais um item da lista ("Para o arroz de sushi:") — uma linha
/// curta terminando em ":" vira `group` das linhas seguintes, igual ao
/// separador que o usuário cria manualmente, em vez de aparecer como
/// ingrediente/passo comum.
Iterable<({String text, String? group, String? ingredientId})>
    _headingAwareDraftLines(List<String>? lines) sync* {
  String? currentGroup;
  for (final raw in lines ?? const <String>[]) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.endsWith(':') && line.length <= 60) {
      currentGroup = line.substring(0, line.length - 1).trim();
      continue;
    }
    yield (text: line, group: currentGroup, ingredientId: null);
  }
}

/// Reconstrói as linhas do formulário a partir das linhas do banco, inserindo
/// um separador sempre que o `groupLabel` muda pra um rótulo não nulo.
List<_Line> _linesWithHeadings(
  Iterable<({String text, String? group, String? ingredientId})> items,
) {
  final out = <_Line>[];
  String? current;
  for (final it in items) {
    if (it.group != current && it.group != null) {
      out.add(_Line(it.group!, heading: true));
    }
    current = it.group;
    out.add(_Line(it.text, ingredientId: it.ingredientId));
  }
  return out;
}

class _RecipeForm extends ConsumerStatefulWidget {
  const _RecipeForm({required this.original, this.draft});

  final RecipeDetail? original;
  final ImportedRecipe? draft;

  @override
  ConsumerState<_RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends ConsumerState<_RecipeForm>
    with WidgetsBindingObserver {
  late final _recipe = widget.original?.recipe;
  late final _draft = widget.original == null ? widget.draft : null;
  late final _name = TextEditingController(
    text: _recipe?.name ?? _draft?.name ?? '',
  );
  late final _about = TextEditingController(
    text: _recipe?.about ?? _draft?.about ?? '',
  );
  late final _prep = TextEditingController(
    text: (_recipe?.prepMinutes ?? _draft?.prepMinutes)?.toString() ?? '',
  );
  late final _cook = TextEditingController(
    text: (_recipe?.cookMinutes ?? _draft?.cookMinutes)?.toString() ?? '',
  );
  late final _servings = TextEditingController(
    text: (_recipe?.servings ?? _draft?.servings)?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: _recipe?.notes ?? '');

  late final List<_Line> _ingredients = _linesWithHeadings([
    for (final RecipeIngredient i
        in widget.original?.ingredients ?? const <RecipeIngredient>[])
      (text: i.rawText, group: i.groupLabel, ingredientId: i.ingredientId),
    ..._headingAwareDraftLines(_draft?.ingredientLines),
  ]);
  late final List<_Line> _steps = _linesWithHeadings([
    for (final RecipeStep s in widget.original?.steps ?? const <RecipeStep>[])
      (text: s.text, group: s.groupLabel, ingredientId: null),
    ..._headingAwareDraftLines(_draft?.stepLines),
  ]);

  late final _siteTag = siteTagFromUrl(_draft?.sourceUrl);
  late final List<String> _tags = [
    for (final Tag t in widget.original?.tags ?? const <Tag>[]) t.name,
    if (_siteTag != null) _siteTag,
  ];
  final _tagInput = TextEditingController();
  final _tagFocus = FocusNode();
  final _aboutFocus = FocusNode();
  final _cookFocus = FocusNode();
  final _servingsFocus = FocusNode();

  bool _saving = false;

  /// Foto escolhida no formulário. Só vai pro banco no "Salvar"; um arquivo
  /// novo que ficar sem receita é apagado na manutenção do próximo boot.
  late String? _photo = _recipe?.imagePath ?? _draft?.imagePath;

  bool get _isEditing => _recipe != null;

  double get _keyboardInset =>
      WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
  late double _lastKeyboardInset = _keyboardInset;

  /// Onde o campo focado para na área visível (0 = colado no topo): bem
  /// perto do topo, sobra o resto da tela pras sugestões do autocomplete e
  /// pro próximo campo aparecerem inteiros acima do teclado.
  static const _revealAlignment = 0.06;

  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_onFocusChanged);
  }

  @override
  void didChangeMetrics() {
    final inset = _keyboardInset;
    final wasOpen = _lastKeyboardInset > 0;
    if (wasOpen && inset == 0) {
      // Teclado fechou (botão de esconder, arrastar pra baixo, gesto de
      // voltar) — tira o foco do campo pra sumir junto qualquer sugestão de
      // autocomplete (ingrediente/tag) que ainda estivesse flutuando.
      FocusManager.instance.primaryFocus?.unfocus();
    }
    final grew = inset > _lastKeyboardInset;
    _lastKeyboardInset = inset;
    if (wasOpen != (inset > 0)) setState(() {});
    if (grew) _scheduleReveal(keyboardAlreadyOpen: false);
  }

  void _onFocusChanged() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null || ctx.widget is! EditableText) return;
    _scheduleReveal(keyboardAlreadyOpen: _keyboardInset > 0);
  }

  /// Espera o teclado terminar de subir (o timer reinicia a cada passo da
  /// animação dele) e só então rola — rolar antes deixava o campo no meio
  /// da tela e depois escondido atrás do teclado.
  void _scheduleReveal({required bool keyboardAlreadyOpen}) {
    _revealTimer?.cancel();
    _revealTimer = Timer(
      Duration(milliseconds: keyboardAlreadyOpen ? 60 : 320),
      _revealFocused,
    );
  }

  void _revealFocused() {
    if (!mounted) return;
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null || !ctx.mounted || ctx.widget is! EditableText) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: _revealAlignment,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  /// Enter numa linha de ingrediente/passo: vai pra próxima; na última, abre
  /// uma linha nova (a não ser que a atual esteja vazia — aí só fecha).
  void _focusNextLine(List<_Line> list, int index) {
    if (index + 1 < list.length) {
      list[index + 1].focusNode.requestFocus();
      return;
    }
    if (list[index].controller.text.trim().isEmpty) {
      FocusScope.of(context).unfocus();
      return;
    }
    final line = _Line('');
    setState(() => list.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) line.focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    FocusManager.instance.removeListener(_onFocusChanged);
    WidgetsBinding.instance.removeObserver(this);
    for (final c in [_name, _about, _prep, _cook, _servings, _notes]) {
      c.dispose();
    }
    for (final l in [..._ingredients, ..._steps]) {
      l.controller.dispose();
      l.focusNode.dispose();
    }
    _tagInput.dispose();
    _tagFocus.dispose();
    _aboutFocus.dispose();
    _cookFocus.dispose();
    _servingsFocus.dispose();
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

  /// Achata a lista do formulário em (textos, rótulos de grupo). Um separador
  /// vira o rótulo das linhas seguintes; ele mesmo não entra.
  (List<String>, List<String?>, List<String?>) _collect(List<_Line> lines) {
    final texts = <String>[];
    final groups = <String?>[];
    final ids = <String?>[];
    String? current;
    for (final l in lines) {
      final text = l.controller.text;
      if (l.heading) {
        final t = text.trim();
        current = t.isEmpty ? null : t;
        continue;
      }
      texts.add(text);
      groups.add(current);
      ids.add(l.hasValidIngredientId ? l.ingredientId : null);
    }
    return (texts, groups, ids);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final (ingLines, ingGroups, ingIds) = _collect(_ingredients);
    final (stepLines, stepGroups, _) = _collect(_steps);
    final result = await ref.read(recipeFormViewModelProvider).submit(
          original: _recipe,
          name: _name.text,
          about: _about.text,
          prepText: _prep.text,
          cookText: _cook.text,
          servingsText: _servings.text,
          notes: _notes.text,
          ingredientLines: ingLines,
          stepLines: stepLines,
          ingredientGroups: ingGroups,
          stepGroups: stepGroups,
          ingredientIds: ingIds,
          tagNames: [..._tags, _tagInput.text],
          sourceUrl: _draft?.sourceUrl,
        );

    if (result case Ok<Recipe>(:final value)) {
      await _commitPhoto(value.id);
    }

    if (!mounted) return;
    result.when(
      ok: (_) => context.pop(),
      err: (f) {
        setState(() => _saving = false);
        AppSnackBar.show(
          context,
          message: f.message,
          variant: AppSnackBarVariant.error,
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    final change = await choosePhoto(context, ref, hasPhoto: _photo != null);
    if (change == null || !mounted) return;
    final previous = _photo;
    // Foto intermediária (escolhida aqui e já trocada) só some se nenhuma
    // receita a usa — e nunca se for a mesma que acabou de ser escolhida,
    // porque fotos iguais são o mesmo arquivo.
    if (previous != null &&
        previous != _recipe?.imagePath &&
        previous != change.imagePath) {
      final repo = ref.read(recipeRepositoryProvider);
      unawaited(ref
          .read(recipeImageServiceProvider)
          .deleteIfUnused(previous, (n) => repo.isImageInUse(n)));
    }
    setState(() => _photo = change.imagePath);
  }

  Future<void> _commitPhoto(String recipeId) async {
    final original = _recipe?.imagePath;
    if (_photo == original) return;
    final images = ref.read(recipeImageServiceProvider);
    final saved =
        await ref.read(recipeRepositoryProvider).setImage(recipeId, _photo);
    if (saved.isOk) {
      final repo = ref.read(recipeRepositoryProvider);
      await images.deleteIfUnused(
        original,
        (n) => repo.isImageInUse(n, exceptRecipeId: recipeId),
      );
      unawaited(ref.read(recipeImageSyncProvider).syncPending());
    }
  }

  void _reorder(List<_Line> list, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      list.insert(newIndex, list.removeAt(oldIndex));
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasName = _name.text.trim().isNotEmpty;
    final blocked = _isCoverScreenSize(context);
    final ingredientSuggestions =
        ref.watch(allIngredientsProvider).valueOrNull ?? const <Ingredient>[];

    return _Frame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            title: _isEditing ? 'Editar receita' : 'Nova receita',
            onSave: hasName ? _save : null,
            saving: _saving,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                // Com o teclado aberto sobra espaço rolável embaixo pros
                // últimos campos poderem subir até a posição de destaque.
                _keyboardInset > 0
                    ? MediaQuery.sizeOf(context).height * 0.5
                    : AppSpacing.xxl,
              ),
              children: [
                _PhotoField(photo: _photo, onTap: _pickPhoto),
                _Field(
                  label: 'Nome',
                  controller: _name,
                  autofocus: !_isEditing && !blocked,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _aboutFocus.requestFocus(),
                ),
                _Field(
                  label: 'Sobre',
                  controller: _about,
                  maxLines: 3,
                  focusNode: _aboutFocus,
                ),
                _buildTimeFields(),
                _Field(
                  label: 'Rende (porções)',
                  controller: _servings,
                  numeric: true,
                  focusNode: _servingsFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _tagFocus.requestFocus(),
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
                  accentColor: context.colors.coral,
                  addLabel: 'Adicionar ingrediente',
                  hintFor: (i) => 'ex.: 2 xícaras de farinha',
                  lines: _ingredients,
                  suggestions: ingredientSuggestions,
                  onAdd: () => setState(() => _ingredients.add(_Line(''))),
                  onAddHeading: () => setState(
                    () => _ingredients.add(_Line('', heading: true)),
                  ),
                  onRemove: (i) => setState(() {
                    _ingredients.removeAt(i).controller.dispose();
                  }),
                  onReorder: (o, n) => _reorder(_ingredients, o, n),
                  onSubmitLine: (i) => _focusNextLine(_ingredients, i),
                ),
                const SizedBox(height: AppSpacing.lg),
                _LineList(
                  title: 'Passos',
                  accentColor: context.colors.violet,
                  addLabel: 'Adicionar passo',
                  hintFor: (i) => 'Passo ${i + 1}',
                  lines: _steps,
                  onAdd: () => setState(() => _steps.add(_Line(''))),
                  onAddHeading: () =>
                      setState(() => _steps.add(_Line('', heading: true))),
                  onRemove: (i) => setState(() {
                    _steps.removeAt(i).controller.dispose();
                  }),
                  onReorder: (o, n) => _reorder(_steps, o, n),
                  onSubmitLine: (i) => _focusNextLine(_steps, i),
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

  Widget _buildTimeFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Field(
            label: 'Preparo (min)',
            controller: _prep,
            numeric: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _cookFocus.requestFocus(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Field(
            label: 'Cozimento (min)',
            controller: _cook,
            numeric: true,
            focusNode: _cookFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _servingsFocus.requestFocus(),
          ),
        ),
      ],
    );
  }
}

/// Heurística de tela de capa (Z Flip fechado etc.): pequena e quase
/// quadrada, bem diferente de qualquer celular aberto.
bool _isCoverScreenSize(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide < 500 && (size.width / size.height) > 0.75;
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final blocked = _isCoverScreenSize(context);
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            IgnorePointer(ignoring: blocked, child: child),
            if (blocked) const _CoverScreenBlocker(),
          ],
        ),
      ),
    );
  }
}

class _CoverScreenBlocker extends StatefulWidget {
  const _CoverScreenBlocker();

  @override
  State<_CoverScreenBlocker> createState() => _CoverScreenBlockerState();
}

class _CoverScreenBlockerState extends State<_CoverScreenBlocker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: context.colors.paper,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _FoldOpenAnimation(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Abra o celular pra continuar',
                  style: context.texts.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Essa tela precisa de mais espaço.',
                  style: context.texts.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                PillButton(
                  label: 'Voltar',
                  variant: PillButtonVariant.secondary,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dois retângulos com dobradiça no meio: o de cima gira em X, indo de
/// dobrado (sobre o de baixo) até aberto, em loop, sugerindo "abra o celular".
class _FoldOpenAnimation extends StatefulWidget {
  const _FoldOpenAnimation();

  @override
  State<_FoldOpenAnimation> createState() => _FoldOpenAnimationState();
}

class _FoldOpenAnimationState extends State<_FoldOpenAnimation>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true, period: const Duration(milliseconds: 2000));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = Curves.easeInOut.transform(_controller.value);
        final closedAngle = math.pi * 0.94;
        final angle = closedAngle * (1 - progress);
        return SizedBox(
          width: 66,
          height: 114,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.003)
                  ..rotateX(angle),
                child: _PhoneHalf(
                  radius: const BorderRadius.vertical(top: Radius.circular(16)),
                  colors: colors,
                  cameras: const [Alignment.topCenter],
                ),
              ),
              _PhoneHalf(
                radius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                colors: colors,
                cameras: const [
                  Alignment(0.3, 0.75),
                  Alignment(0.9, 0.75),
                ],
                cameraSize: 9,
                camerasOpacity: 1 - progress,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Uma "metade" do corpo do celular dobrável: bloco preto com furos de
/// câmera na cor de fundo, sem indicação de tela.
class _PhoneHalf extends StatelessWidget {
  const _PhoneHalf({
    required this.radius,
    required this.colors,
    required this.cameras,
    this.cameraSize = 6,
    this.camerasOpacity = 1,
  });

  final BorderRadius radius;
  final AppColors colors;
  final List<Alignment> cameras;
  final double cameraSize;
  final double camerasOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.ink, borderRadius: radius),
      child: Opacity(
        opacity: camerasOpacity,
        child: Stack(
          children: [
            for (final alignment in cameras)
              Align(
                alignment: alignment,
                child: Container(
                  width: cameraSize,
                  height: cameraSize,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colors.paper,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onSave,
    this.saving = false,
  });

  final String title;
  final VoidCallback? onSave;
  final bool saving;

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
          PillButton(label: 'Salvar', onPressed: onSave, loading: saving),
        ],
      ),
    );
  }
}

/// Fundo + sombra da lista de sugestões (tags e ingredientes) — `BoxShadow`
/// estático, não `Material.elevation`: reconstrói a cada tecla digitada, e a
/// sombra física recalculada nesse ritmo pesa à toa (mesma correção já
/// aplicada no leque de ações e no fantasma do arrasto).
BoxDecoration _suggestionDecoration(BuildContext context) {
  final colors = context.colors;
  return BoxDecoration(
    color: colors.paper,
    borderRadius: BorderRadius.circular(AppRadii.sm),
    boxShadow: [
      BoxShadow(
        color: colors.ink.withValues(alpha: 0.25),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
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
              return known.map((t) => t.name).where(
                  (n) => n.toLowerCase().contains(q) && !tags.contains(n));
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
            optionsViewBuilder: (context, onSelected, options) =>
                _buildSuggestions(context, onSelected, options.toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(
    BuildContext context,
    AutocompleteOnSelected<String> onSelected,
    List<String> items,
  ) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.topLeft,
      child: DecoratedBox(
        decoration: _suggestionDecoration(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180, maxWidth: 280),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.paperSoft),
                InkWell(
                  onTap: () => onSelected(items[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(items[i], style: context.texts.bodyMedium),
                  ),
                ),
              ],
            ],
          ),
        ),
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

/// Foto da receita no formulário: prévia (ou convite) que abre a folha de
/// escolha — tirar, galeria, remover.
class _PhotoField extends ConsumerWidget {
  const _PhotoField({required this.photo, required this.onTap});

  final String? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final name = photo;
    final dir =
        name == null ? null : ref.watch(recipeImagesDirProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        button: true,
        label: name == null ? 'Adicionar foto' : 'Trocar foto',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Material(
            color: colors.paperSoft,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: 160,
                child: name != null && dir != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(p.join(dir.path, name)),
                            fit: BoxFit.cover,
                            cacheWidth: 900,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                          Positioned(
                            right: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                            child: Icon(Icons.edit_outlined,
                                color: colors.onSaturated),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 32, color: colors.textMuted),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Adicionar foto',
                            style: context.texts.bodyMedium
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
              ),
            ),
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
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool numeric;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

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
            focusNode: focusNode,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
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
    required this.accentColor,
    required this.addLabel,
    required this.hintFor,
    required this.lines,
    required this.onAdd,
    required this.onAddHeading,
    required this.onRemove,
    required this.onReorder,
    required this.onSubmitLine,
    this.suggestions,
  });

  final String title;

  /// Identidade da seção (§9.2) — coral pra Ingredientes, violeta pra Passos.
  /// Só entra em ícone/texto/borda, nunca como fundo de campo (§9.1 segue
  /// chapado em `paperSoft`).
  final Color accentColor;
  final String addLabel;
  final String Function(int index) hintFor;
  final List<_Line> lines;
  final VoidCallback onAdd;
  final VoidCallback onAddHeading;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Enter numa linha: o pai decide (próxima linha, ou cria uma).
  final void Function(int index) onSubmitLine;
  final List<Ingredient>? suggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title, titleColor: accentColor),
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
            itemBuilder: (context, i) => _buildLineTile(context, i),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              PillButton(
                label: addLabel,
                icon: Icons.add,
                variant: PillButtonVariant.secondary,
                onPressed: onAdd,
              ),
              PillButton(
                label: 'Separador',
                icon: Icons.segment,
                variant: PillButtonVariant.secondary,
                onPressed: onAddHeading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineTile(BuildContext context, int i) {
    final colors = context.colors;
    final line = lines[i];
    return Container(
      key: line.key,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: line.heading
          ? BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              border: Border(left: BorderSide(color: accentColor, width: 3)),
            )
          : null,
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: i,
            child: Icon(
              line.heading ? Icons.segment : Icons.drag_indicator,
              color: line.heading
                  ? accentColor
                  : accentColor.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: AppSpacing.xs / 2),
          Expanded(child: _buildLineField(context, line, i)),
          IconButton(
            onPressed: () => onRemove(i),
            icon: const Icon(Icons.close),
            color: colors.textMuted,
            tooltip: 'Remover',
          ),
        ],
      ),
    );
  }

  Widget _buildLineField(BuildContext context, _Line line, int i) {
    if (suggestions != null && !line.heading) {
      return _IngredientAutocompleteField(
        line: line,
        suggestions: suggestions!,
        hintText: hintFor(i),
        onSubmitted: () => onSubmitLine(i),
      );
    }
    return TextField(
      controller: line.controller,
      focusNode: line.focusNode,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => onSubmitLine(i),
      minLines: 1,
      maxLines: line.heading ? 1 : 4,
      style: line.heading
          ? context.texts.labelLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: context.colors.coral,
            )
          : null,
      decoration: InputDecoration(
        hintText:
            line.heading ? 'Nome da seção (ex.: Para a massa)' : hintFor(i),
      ),
    );
  }
}

/// Campo de ingrediente com sugestões do catálogo (C3). Filtra pelo nome já
/// extraído pelo parser (C1) — não pela linha inteira — e, ao escolher, troca
/// só a parte do nome, preservando quantidade/unidade/qualificador digitados.
class _IngredientAutocompleteField extends ConsumerWidget {
  const _IngredientAutocompleteField({
    required this.line,
    required this.suggestions,
    required this.hintText,
    required this.onSubmitted,
  });

  final _Line line;
  final List<Ingredient> suggestions;
  final String hintText;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var pendingPickText = line.controller.text;
    var pendingWasFuzzy = false;
    var isFuzzy = false;

    return RawAutocomplete<Ingredient>(
      textEditingController: line.controller,
      focusNode: line.focusNode,
      displayStringForOption: (i) => i.displayName,
      optionsBuilder: (value) {
        final query = parseIngredientLine(value.text).name.trim().toLowerCase();
        if (query.isEmpty) {
          isFuzzy = false;
          return const Iterable<Ingredient>.empty();
        }

        final exact = suggestions
            .where((s) => s.displayName.toLowerCase().contains(query));
        if (exact.isNotEmpty) {
          isFuzzy = false;
          return exact;
        }

        final key = normalize(query);
        if (key.isEmpty) {
          isFuzzy = false;
          return const Iterable<Ingredient>.empty();
        }

        // Poda barata antes do Levenshtein completo: a distância de edição
        // nunca é menor que a diferença de tamanho das strings, então dá pra
        // descartar sem calcular nada candidatos que não têm como bater nem
        // o limiar de score nem a regra de 1 letra de diferença. Roda em
        // todo o catálogo a cada tecla digitada, então essa poda evita rodar
        // Levenshtein (custo O(n·m)) em quem já está matematicamente fora.
        Ingredient? bestMatch;
        var bestScore = -1.0;
        for (final s in suggestions) {
          final target = s.normalizedKey;
          final diff = (key.length - target.length).abs();
          final maxLen =
              key.length > target.length ? key.length : target.length;
          if (diff > 1 && diff > 0.15 * maxLen) continue;

          final lev = levenshteinDistance(key, target);
          final score = maxLen == 0 ? 1.0 : 1 - (lev / maxLen);
          final shorter =
              key.length < target.length ? key.length : target.length;
          final closeEnough = score >= 0.85 || (shorter >= 4 && lev <= 1);
          if (closeEnough && score > bestScore) {
            bestScore = score;
            bestMatch = s;
          }
        }

        isFuzzy = bestMatch != null;
        return bestMatch == null
            ? const Iterable<Ingredient>.empty()
            : [bestMatch];
      },
      onSelected: (picked) {
        line.applyIngredientSuggestion(picked, pendingPickText);
        if (pendingWasFuzzy) {
          ref.read(ingredientRepositoryProvider).confirmAlias(
                picked.id,
                parseIngredientLine(pendingPickText).name,
              );
        }
        // applyIngredientSuggestion troca o texto de novo depois que o
        // RawAutocomplete já tinha marcado a seleção — sem tirar o foco à
        // força aqui, essa 2ª troca de texto invalida a seleção interna dele
        // e as sugestões reabrem sozinhas na hora, mesmo já tendo escolhido.
        line.focusNode.unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => onSubmitted(),
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(hintText: hintText),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: DecoratedBox(
            decoration: _suggestionDecoration(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 280),
              child: _buildSuggestionsList(
                context,
                options.toList(),
                isFuzzy,
                onSelected,
                () => pendingPickText = line.controller.text,
                () => pendingWasFuzzy = isFuzzy,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList(
    BuildContext context,
    List<Ingredient> items,
    bool isFuzzy,
    AutocompleteOnSelected<Ingredient> onSelected,
    VoidCallback capturePendingText,
    VoidCallback capturePendingFuzzy,
  ) {
    final colors = context.colors;
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        if (isFuzzy)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs / 2,
            ),
            child: Text('Você quis dizer:', style: context.texts.labelSmall),
          ),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Divider(height: 1, color: colors.paperSoft),
          InkWell(
            onTap: () {
              capturePendingText();
              capturePendingFuzzy();
              onSelected(items[i]);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child:
                  Text(items[i].displayName, style: context.texts.bodyMedium),
            ),
          ),
        ],
      ],
    );
  }
}
