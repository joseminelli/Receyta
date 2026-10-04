/// Gera o PDF de uma receita (D6, RF-06.6). Dart puro (`pdf` só monta bytes,
/// sem plugin nativo) — abrir o share sheet com o resultado é o
/// `RecipeExportService`, mesma separação do `recipe_export.dart` (D1/D2).
/// Documento próprio (A4) na linguagem do app: fundo papel, cabeçalho com a
/// cor e a textura da receita, ingredientes num cartão e passos numerados.
/// Não é uma captura de tela — texto de verdade, legível impresso.
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:receyta/domain/engine/ingredient_format.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/tile_appearance.dart';

const _ink = PdfColor.fromInt(0xFF16150F);
const _paper = PdfColor.fromInt(0xFFF5F2EA);
const _paperSoft = PdfColor.fromInt(0xFFE9E5D8);
const _lime = PdfColor.fromInt(0xFFD6F45A);
const _muted = PdfColor.fromInt(0xFF8A8674);
const _body = PdfColor.fromInt(0xFF3D3B30);

/// [banner] é o PNG do cabeçalho (`renderRecipePdfBanner`); sem ele o título
/// sai em texto simples, o que mantém a função pura e testável.
Future<Uint8List> buildRecipePdf(
  RecipeDetail detail, {
  Uint8List? banner,
}) async {
  final recipe = detail.recipe;
  final doc = pw.Document(title: recipe.name, creator: 'Receyta');
  final accent = _accentOf(recipe);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 44),
        buildBackground: (_) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: _paper),
        ),
      ),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Receyta  |  Suas receitas, num lugar só',
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
            pw.Text(
              '${context.pageNumber}/${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
        ),
      ),
      build: (context) => [
        if (banner != null)
          pw.Image(pw.MemoryImage(banner), width: PdfPageFormat.a4.width - 72)
        else
          pw.Text(
            recipe.name,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        pw.SizedBox(height: 14),
        _metricsRow(recipe),
        if ((recipe.about ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text(
            recipe.about!,
            style: const pw.TextStyle(
              fontSize: 12,
              color: _body,
              lineSpacing: 3,
            ),
          ),
        ],
        pw.SizedBox(height: 22),
        if (detail.ingredients.isNotEmpty) ...[
          _sectionTitle('Ingredientes', accent),
          pw.SizedBox(height: 10),
          _ingredientCard(detail.ingredients, accent),
          pw.SizedBox(height: 22),
        ],
        if (detail.steps.isNotEmpty) ...[
          _sectionTitle('Preparo', accent),
          pw.SizedBox(height: 10),
          ..._stepBlocks(detail.steps),
        ],
        if ((recipe.notes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 22),
          _sectionTitle('Notas', accent),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _paperSoft,
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Text(
              recipe.notes!,
              style: const pw.TextStyle(
                fontSize: 12,
                color: _body,
                lineSpacing: 3,
              ),
            ),
          ),
        ],
      ],
    ),
  );

  return doc.save();
}

/// A cor de destaque do PDF: a do azulejo da receita.
PdfColor _accentOf(Recipe recipe) {
  final tile = resolveTileAppearance(
    AppColors.light,
    color: recipe.tileColor,
    motif: recipe.tileMotif,
    seedId: recipe.id,
  );
  final c = tile.background;
  return PdfColor(c.r, c.g, c.b);
}

/// Título de seção: um bloco da cor da receita ao lado do nome.
pw.Widget _sectionTitle(String text, PdfColor accent) => pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 20,
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: pw.BorderRadius.circular(4),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 17,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    );

/// Métricas em pílulas escuras com texto lima, como os chips do app.
pw.Widget _metricsRow(Recipe recipe) {
  final parts = [
    if (recipe.prepMinutes != null) '${recipe.prepMinutes} min de preparo',
    if (recipe.cookMinutes != null) '${recipe.cookMinutes} min no fogão',
    if (recipe.servings != null) '${recipe.servings} porções',
  ];
  if (parts.isEmpty) return pw.SizedBox();
  return pw.Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final p in parts)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _ink,
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Text(
            p,
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: _lime,
            ),
          ),
        ),
    ],
  );
}

pw.Widget? _groupHeader(String? label, String? prevLabel) {
  if (label == null || label.isEmpty || label == prevLabel) return null;
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 8, bottom: 6),
    child: pw.Text(
      label.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: _muted,
        letterSpacing: 1.2,
      ),
    ),
  );
}

/// Ingredientes num cartão claro, marcador na cor da receita.
pw.Widget _ingredientCard(List<RecipeIngredient> items, PdfColor accent) {
  final lines = <pw.Widget>[];
  String? prevGroup;
  for (final i in items) {
    final header = _groupHeader(i.groupLabel, prevGroup);
    if (header != null) lines.add(header);
    prevGroup = i.groupLabel;
    lines.add(_bulletLine(formatIngredientLine(i), accent));
  }
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 6),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(16),
      border: pw.Border.all(color: _paperSoft, width: 1.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines,
    ),
  );
}

/// Marcador desenhado (círculo), não o caractere "•": a fonte Base14 padrão
/// do pacote `pdf` não tem o glyph U+2022.
pw.Widget _bulletLine(String text, PdfColor accent) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 7),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 6,
          height: 6,
          margin: const pw.EdgeInsets.only(top: 4, right: 10),
          decoration:
              pw.BoxDecoration(color: accent, shape: pw.BoxShape.circle),
        ),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(fontSize: 12, color: _ink),
          ),
        ),
      ],
    ),
  );
}

/// Passos com o número num círculo escuro, texto lima, como no modo cozinha.
List<pw.Widget> _stepBlocks(List<RecipeStep> steps) {
  final widgets = <pw.Widget>[];
  String? prevGroup;
  for (var idx = 0; idx < steps.length; idx++) {
    final s = steps[idx];
    final header = _groupHeader(s.groupLabel, prevGroup);
    if (header != null) widgets.add(header);
    prevGroup = s.groupLabel;
    widgets.add(pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 22,
            height: 22,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              color: _ink,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              '${idx + 1}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _lime,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                s.text,
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: _ink,
                  lineSpacing: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
  return widgets;
}
