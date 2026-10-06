import 'dart:io';

import 'package:crypto/crypto.dart';
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
/// e o nome continua valendo. O nome vem do hash do conteúdo: fotos iguais
/// (a mesma escolhida duas vezes, receita duplicada, backup restaurado) são
/// UM arquivo, aqui e na nuvem. Como o nome muda quando o conteúdo muda, o
/// cache de imagem do Flutter também se invalida sozinho.
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
  Future<Result<String?>> pick(ImageSource source) async {
    File? picked;
    try {
      final xfile = await _picker.pickImage(source: source);
      if (xfile == null) return const Ok(null);
      picked = File(xfile.path);
      return Ok(await store(picked));
    } catch (e) {
      return Err(
          ProcessingFailure('Não foi possível salvar a foto.', cause: e));
    } finally {
      await _deleteQuietly(picked);
    }
  }

  /// Comprime [source] e guarda na pasta do app, abaixo de
  /// [kRecipeImageMaxBytes] quando der. Devolve o nome do arquivo, que é
  /// derivado do CONTEÚDO: a mesma foto sempre vira o mesmo arquivo.
  Future<String> store(File source) async {
    final temp = await _tempFile();
    try {
      var side = kRecipeImageMaxSide;
      var quality = kRecipeImageQuality;
      while (true) {
        final out = await _compress(
          source.path,
          temp.path,
          maxSide: side,
          quality: quality,
        );
        if (out == null) {
          throw const FileSystemException('A compressão não gerou arquivo.');
        }
        if (out.path != temp.path) await out.copy(temp.path);

        if (await temp.length() <= kRecipeImageMaxBytes) break;
        if (quality > _minQuality) {
          quality = (quality - 10).clamp(_minQuality, kRecipeImageQuality);
        } else if (side > _minSide) {
          side = (side * 0.8).round().clamp(_minSide, kRecipeImageMaxSide);
          quality = kRecipeImageQuality - 20;
        } else {
          break;
        }
      }
      return await _adopt(temp);
    } finally {
      await _deleteQuietly(temp);
    }
  }

  /// Guarda [bytes] como foto de receita.
  ///
  /// Com [compress] (padrão) passa pela mesma compressão de [store] — pro que
  /// vem da internet. Sem ele grava como está — pro que já foi comprimido
  /// (restauração de backup); aí, se [name] for um nome válido, o arquivo
  /// mantém esse nome (é o que deixa o app reconhecer que a foto já está na
  /// nuvem) e, se já existir aqui, não é regravado.
  Future<String> storeBytes(
    Uint8List bytes, {
    String? name,
    bool compress = true,
  }) async {
    if (!compress && isValidRecipeImageName(name)) {
      final file = await fileFor(name!);
      if (!await file.exists()) await file.writeAsBytes(bytes, flush: true);
      return name;
    }
    final temp = await _tempFile();
    try {
      await temp.writeAsBytes(bytes, flush: true);
      return compress ? await store(temp) : await _adopt(temp);
    } finally {
      await _deleteQuietly(temp);
    }
  }

  /// Nomeia [temp] pelo hash do conteúdo e põe na pasta. Foto igual a uma que
  /// já existe reaproveita o arquivo — nada de cópia repetida.
  Future<String> _adopt(File temp) async {
    final digest = sha256.convert(await temp.readAsBytes()).toString();
    final name = '${digest.substring(0, 40)}.jpg';
    final target = await fileFor(name);
    if (!await target.exists()) await temp.rename(target.path);
    return name;
  }

  Future<File> _tempFile() async => File(p.join(
        (await directory()).path,
        '.tmp_${DateTime.now().microsecondsSinceEpoch}.jpg',
      ));

  Future<void> delete(String? name) async {
    if (name == null) return;
    await _deleteQuietly(await fileFor(name));
  }

  /// Apaga a foto só se [isUsed] disser que nenhuma receita ainda a usa. Como
  /// fotos iguais viram o mesmo arquivo, vários registros podem apontar pra
  /// ele — apagar sem conferir quebraria as outras receitas.
  Future<void> deleteIfUnused(
    String? name,
    Future<bool> Function(String name) isUsed,
  ) async {
    if (name == null) return;
    if (await isUsed(name)) return;
    await delete(name);
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

final _validName = RegExp(r'^[A-Za-z0-9_-]{1,80}\.jpg$');

/// Nome seguro de arquivo de foto: só letras, números, `_` e `-`, terminado em
/// `.jpg`. Vindo de um backup é dado de fora — nunca vira caminho sem passar
/// por aqui (barra e `..` não passam).
bool isValidRecipeImageName(String? name) =>
    name != null && _validName.hasMatch(name);

final recipeImageServiceProvider =
    Provider<RecipeImageService>((ref) => RecipeImageService());

/// Pasta das fotos — os widgets juntam o nome do arquivo a ela.
final recipeImagesDirProvider = FutureProvider<Directory>(
  (ref) => ref.watch(recipeImageServiceProvider).directory(),
);
