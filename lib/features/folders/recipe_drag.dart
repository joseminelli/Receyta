import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/recipe_card.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// O que está sendo arrastado — uma receita ou uma pasta. Vira o payload do
/// `Draggable` e o que os alvos inspecionam.
sealed class DragItem {
  const DragItem(this.id);
  final String id;
}

class RecipeDragItem extends DragItem {
  const RecipeDragItem(super.id);
}

class FolderDragItem extends DragItem {
  const FolderDragItem(super.id);
}

/// O item sendo arrastado agora, ou nulo. A home escuta isso pra subir a lista
/// até a faixa de pastas, e a tela da pasta pra revelar a barra de "sair".
final draggingItemProvider = StateProvider<DragItem?>((ref) => null);

/// Segura + arrasta um card de receita. O que segue o dedo é o próprio card
/// (versão compacta), que "sai" do lugar de origem e voa até logo abaixo do
/// dedo.
class DraggableRecipe extends ConsumerStatefulWidget {
  const DraggableRecipe({
    super.key,
    required this.recipe,
    required this.child,
    this.motif,
  });

  final Recipe recipe;
  final Widget child;

  /// Módulo do azulejo do card de origem, quando ele não vem do id (o destaque
  /// da home é sempre `arco`). O card fantasma usa isso pra ter a mesma cor e
  /// estampa.
  final TileMotif? motif;

  @override
  ConsumerState<DraggableRecipe> createState() => _DraggableRecipeState();
}

class _DraggableRecipeState extends ConsumerState<DraggableRecipe> {
  final _key = GlobalKey();
  Offset _pointer = Offset.zero;
  Offset _lift = Offset.zero;

  void _clear() =>
      ref.read(draggingItemProvider.notifier).state = null;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _pointer = e.position,
      onPointerMove: (e) => _pointer = e.position,
      child: LongPressDraggable<DragItem>(
        data: RecipeDragItem(widget.recipe.id),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () {
          _lift = _liftFrom(_key, _pointer);
          ref.read(draggingItemProvider.notifier).state =
              RecipeDragItem(widget.recipe.id);
        },
        onDragEnd: (_) => _clear(),
        onDraggableCanceled: (_, __) => _clear(),
        onDragCompleted: _clear,
        feedback: _LiftIn(
          lift: _lift,
          rest: const Offset(-84, 20),
          child: _RecipeGhost(recipe: widget.recipe, motif: widget.motif),
        ),
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: KeyedSubtree(key: _key, child: widget.child),
        ),
        child: KeyedSubtree(key: _key, child: widget.child),
      ),
    );
  }
}

/// Segura + arrasta uma pasta pra dentro de outra (soltando num tile de pasta)
/// ou pra fora (soltando na barra de sair, na tela da pasta).
class DraggableFolder extends ConsumerStatefulWidget {
  const DraggableFolder({
    super.key,
    required this.folder,
    required this.child,
  });

  final Folder folder;
  final Widget child;

  @override
  ConsumerState<DraggableFolder> createState() => _DraggableFolderState();
}

class _DraggableFolderState extends ConsumerState<DraggableFolder> {
  final _key = GlobalKey();
  Offset _pointer = Offset.zero;
  Offset _lift = Offset.zero;

  void _clear() =>
      ref.read(draggingItemProvider.notifier).state = null;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _pointer = e.position,
      onPointerMove: (e) => _pointer = e.position,
      child: LongPressDraggable<DragItem>(
        data: FolderDragItem(widget.folder.id),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () {
          _lift = _liftFrom(_key, _pointer);
          ref.read(draggingItemProvider.notifier).state =
              FolderDragItem(widget.folder.id);
        },
        onDragEnd: (_) => _clear(),
        onDraggableCanceled: (_, __) => _clear(),
        onDragCompleted: _clear,
        feedback: _LiftIn(
          lift: _lift,
          rest: const Offset(-70, 18),
          child: _FolderGhost(name: widget.folder.name),
        ),
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: KeyedSubtree(key: _key, child: widget.child),
        ),
        child: KeyedSubtree(key: _key, child: widget.child),
      ),
    );
  }
}

Offset _liftFrom(GlobalKey key, Offset pointer) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  final origin = box?.localToGlobal(Offset.zero) ?? pointer;
  return origin - pointer;
}

/// Transição do fantasma: parte da posição de origem ([lift]) e desliza até
/// [rest] (relativo ao dedo), crescendo e ganhando opacidade.
class _LiftIn extends StatelessWidget {
  const _LiftIn({required this.lift, required this.rest, required this.child});

  final Offset lift;
  final Offset rest;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset.lerp(lift, rest, t)!,
          child: Transform.scale(
            scale: lerpDouble(0.9, 1, t),
            alignment: Alignment.topCenter,
            child: Opacity(opacity: lerpDouble(0.7, 1, t)!, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class _RecipeGhost extends StatelessWidget {
  const _RecipeGhost({required this.recipe, this.motif});

  final Recipe recipe;
  final TileMotif? motif;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        elevation: 14,
        shadowColor: context.colors.ink.withValues(alpha: 0.5),
        child: RecipeCard(recipe: recipe, motif: motif),
      ),
    );
  }
}

class _FolderGhost extends StatelessWidget {
  const _FolderGhost({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.md),
      elevation: 14,
      shadowColor: colors.ink.withValues(alpha: 0.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: SizedBox(
          width: 148,
          height: 88,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TilePattern(
                motif: TileMotif.meiaLua,
                background: colors.violet,
                patternColor: colors.violetPattern,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 18, color: colors.onSaturated),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelLarge?.copyWith(
                        color: colors.onSaturated,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Envolve um tile de pasta e o torna alvo de soltar. Aceita receita (move pra
/// dentro) e pasta (aninha). Cresce e ganha um anel enquanto algo paira.
class FolderDropZone extends ConsumerWidget {
  const FolderDropZone({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadii.md)),
  });

  final String folderId;
  final String folderName;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return DragTarget<DragItem>(
      onWillAcceptWithDetails: (details) => switch (details.data) {
        RecipeDragItem() => true,
        FolderDragItem(:final id) => id != folderId,
      },
      onAcceptWithDetails: (details) async {
        final repo = ref.read(folderRepositoryProvider);
        final result = switch (details.data) {
          RecipeDragItem(:final id) => await repo.moveRecipe(id, folderId),
          FolderDragItem(:final id) => await repo.move(id, folderId),
        };
        result.when(
          ok: (_) => showRootSnackBar(
            SnackBar(content: Text('Movida para "$folderName"')),
          ),
          err: (f) => showRootSnackBar(SnackBar(content: Text(f.message))),
        );
      },
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return AnimatedScale(
          scale: active ? 1.06 : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: active ? colors.lime : Colors.transparent,
                width: 3,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Barra fixa no rodapé da tela da pasta: só aparece durante um arrasto e, ao
/// soltar nela, tira a receita ou a subpasta da pasta atual — sobe um nível pra
/// [parentId] (nulo = raiz). [parentName] nomeia o destino no aviso.
class FolderExitDropBar extends ConsumerWidget {
  const FolderExitDropBar({
    super.key,
    required this.parentId,
    this.parentName,
  });

  final String? parentId;
  final String? parentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dragging = ref.watch(draggingItemProvider) != null;
    final label =
        parentName == null ? 'Tirar da pasta' : 'Mover para "$parentName"';

    return IgnorePointer(
      ignoring: !dragging,
      child: AnimatedSlide(
        offset: dragging ? Offset.zero : const Offset(0, 1.4),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: dragging ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: DragTarget<DragItem>(
                onWillAcceptWithDetails: (d) => true,
                onAcceptWithDetails: (d) async {
                  final repo = ref.read(folderRepositoryProvider);
                  final result = switch (d.data) {
                    RecipeDragItem(:final id) =>
                      await repo.moveRecipe(id, parentId),
                    FolderDragItem(:final id) => await repo.move(id, parentId),
                  };
                  result.when(
                    ok: (_) => showRootSnackBar(
                      SnackBar(content: Text('$label — feito')),
                    ),
                    err: (f) =>
                        showRootSnackBar(SnackBar(content: Text(f.message))),
                  );
                },
                builder: (context, candidate, rejected) {
                  final active = candidate.isNotEmpty;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: AppSpacing.minTapTarget + 12,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? colors.lime : colors.ink,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_left,
                          size: 20,
                          color: active ? colors.ink : colors.lime,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          label,
                          style: context.texts.labelLarge?.copyWith(
                            color: active ? colors.ink : colors.onSaturated,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
