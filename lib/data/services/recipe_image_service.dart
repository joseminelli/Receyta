import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:receyta/core/result.dart';

/// Lado maior da foto guardada: o bastante pro hero em tela cheia, sem
/// carregar os 12 MP da câmera.
const kRecipeImageMaxSide = 1600;
const kRecipeImageQuality = 82;

/// Teto de peso por foto. O plano gratuito do Supabase Storage tem 1 GB;
/// com 400 KB cabem ~2.500 fotos. A compressão baixa qualidade e depois
/// dimensão até caber (ver [RecipeImageService.store]).
const kRecipeImageMaxBytes = 400 * 1024;

/// Piso de qualidade/dimensão: abaixo disso a foto vira borrão, então a
/// busca pelo teto para aqui (nesse ponto já passa de longe abaixo de 1 MB).
const _minQuality = 40;
const _minSide = 800;

/// Comprime [src] em [dst] (JPEG) com o lado maior e a qualidade dados.
/// Devolve o arquivo gerado, ou `null` se falhar. Injetável pra o teste não
/// depender do plugin nativo.
typedef ImageCompressor = Future<File?> Function(
  String src,
  String dst, {
  required int maxSide,
  required int quality,
});

Future<File?> _nativeCompress(
  String src,
  String dst, {
  required int maxSide,
  required int quality,
}) async {
  final out = await FlutterImageCompress.compressAndGetFile(
    src,
    dst,
    minWidth: maxSide,
    minHeight: maxSide,
    quality: quality,
    format: CompressFormat.jpeg,
  );
  return out == null ? null : File(out.path);
}

/// Foto da receita (H0): tira/escolhe, comprime e guarda numa pasta do app.
///
/// No banco (`recipes.image_path`) vai só o NOME do arquivo, nunca o caminho
/// absoluto — o diretório do app pode mudar (restauração, atualização do SO)
/// e o nome continua valendo. Cada foto nova ganha nome novo, o que também
/// derruba o cache de imagem do Flutter sem truque nenhum.
class RecipeImageService {
  RecipeImageService({
    ImagePicker? picker,
    Future<Directory> Function()? baseDir,
    ImageCompressor? compress,
  })  : _picker = picker ?? ImagePicker(),
        _baseDir = baseDir ?? _defaultBaseDir,
        _compress = compress ?? _nativeCompress;

  final ImagePicker _picker;
  final Future<Directory> Function() _baseDir;
  final ImageCompressor _compress;

  static Future<Directory> _defaultBaseDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'recipe_images'));
  }

  Future<Directory> directory() async {
    final dir = await _baseDir();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> fileFor(String name) async =>
      File(p.join((await directory()).path, name));

  /// `Ok(nome)` = foto guardada; `Ok(null)` = a pessoa cancelou.
  Future<Result<String?>> pick(
    ImageSource source, {
    required String recipeId,
  }) async {
    File? picked;
    try {
      final xfile = await _picker.pickImage(source: source);
      if (xfile == null) return const Ok(null);
      picked = File(xfile.path);
      return Ok(await store(picked, recipeId: recipeId));
    } catch (e) {
      return Err(
          ProcessingFailure('Não foi possível salvar a foto.', cause: e));
    } finally {
      await _deleteQuietly(picked);
    }
  }

  /// Comprime [source] e guarda na pasta do app, abaixo de
  /// [kRecipeImageMaxBytes] quando der. Devolve o nome do arquivo.
  Future<String> store(File source, {required String recipeId}) async {
    final name = '${recipeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final target = await fileFor(name);

    var side = kRecipeImageMaxSide;
    var quality = kRecipeImageQuality;
    while (true) {
      final out = await _compress(
        source.path,
        target.path,
        maxSide: side,
        quality: quality,
      );
      if (out == null) {
        throw const FileSystemException('A compressão não gerou arquivo.');
      }
      if (out.path != target.path) await out.copy(target.path);

      if (await target.length() <= kRecipeImageMaxBytes) return name;
      if (quality > _minQuality) {
        quality = (quality - 10).clamp(_minQuality, kRecipeImageQuality);
      } else if (side > _minSide) {
        side = (side * 0.8).round().clamp(_minSide, kRecipeImageMaxSide);
        quality = kRecipeImageQuality - 20;
      } else {
        return name;
      }
    }
  }

  /// Guarda [bytes] como foto da receita. Com [compress] (padrão) passa pela
  /// mesma compressão de [store] — pro que vem da internet; sem ele grava
  /// como está — pro que já foi comprimido (restauração de backup).
  Future<String> storeBytes(
    Uint8List bytes, {
    required String recipeId,
    bool compress = true,
  }) async {
    if (!compress) {
      final name = '${recipeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await (await fileFor(name)).writeAsBytes(bytes, flush: true);
      return name;
    }
    final temp = File(p.join(
      (await directory()).path,
      '.tmp_${DateTime.now().microsecondsSinceEpoch}',
    ));
    try {
      await temp.writeAsBytes(bytes, flush: true);
      return await store(temp, recipeId: recipeId);
    } finally {
      await _deleteQuietly(temp);
    }
  }

  Future<void> delete(String? name) async {
    if (name == null) return;
    await _deleteQuietly(await fileFor(name));
  }

  /// Apaga da pasta toda foto que nenhuma receita referencia mais (receita
  /// apagada de vez, foto trocada). Devolve quantas apagou. Nunca lança.
  Future<int> deleteOrphans(Set<String> referenced) async {
    var removed = 0;
    try {
      final dir = await directory();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        if (referenced.contains(p.basename(entity.path))) continue;
        await _deleteQuietly(entity);
        removed++;
      }
    } catch (e) {
      debugPrint('deleteOrphans: $e');
    }
    return removed;
  }

  Future<void> _deleteQuietly(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

final recipeImageServiceProvider =
    Provider<RecipeImageService>((ref) => RecipeImageService());

/// Pasta das fotos — os widgets juntam o nome do arquivo a ela.
final recipeImagesDirProvider = FutureProvider<Directory>(
  (ref) => ref.watch(recipeImageServiceProvider).directory(),
);
