/// Gera o PDF de uma receita (D6, RF-06.6). Dart puro (`pdf` só monta bytes,
/// sem plugin nativo) — abrir o share sheet com o resultado é o
/// `RecipeExportService`, mesma separação do `recipe_export.dart` (D1/D2).
/// Documento próprio (preto sobre branco, A4), não uma captura de tela do
/// app — é o que garante ficar legível impresso.
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:receyta/domain/engine/ingredient_format.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';

Future<Uint8List> buildRecipePdf(RecipeDetail detail) async {
  final recipe = detail.recipe;
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        pw.Text(
          recipe.name,
          style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
        ),
        if ((recipe.about ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(recipe.about!, style: const pw.TextStyle(fontSize: 12)),
        ],
        pw.SizedBox(height: 12),
        _metricsLine(recipe),
        pw.SizedBox(height: 20),
        if (detail.ingredients.isNotEmpty) ...[
          _sectionTitle('Ingredientes'),
          pw.SizedBox(height: 8),
          ..._ingredientBlocks(detail.ingredients),
          pw.SizedBox(height: 20),
        ],
        if (detail.steps.isNotEmpty) ...[
          _sectionTitle('Preparo'),
          pw.SizedBox(height: 8),
          ..._stepBlocks(detail.steps),
        ],
        if ((recipe.notes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 20),
          _sectionTitle('Notas'),
          pw.SizedBox(height: 8),
          pw.Text(recipe.notes!, style: const pw.TextStyle(fontSize: 12)),
        ],
      ],
    ),
  );

  return doc.save();
}

pw.Widget _sectionTitle(String text) => pw.Text(
      text,
      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
    );

/// Separador ASCII puro entre as métricas — a fonte Base14 padrão do
/// pacote `pdf` não tem o glyph "•" (U+2022), sai vazio no lugar.
pw.Widget _metricsLine(Recipe recipe) {
  final parts = [
    if (recipe.prepMinutes != null) '${recipe.prepMinutes} min de preparo',
    if (recipe.cookMinutes != null) '${recipe.cookMinutes} min no fogão',
    if (recipe.servings != null) '${recipe.servings} porções',
  ];
  if (parts.isEmpty) return pw.SizedBox();
  return pw.Text(
    parts.join('   |   '),
    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
  );
}

/// Cabeçalho de grupo quando `groupLabel` muda em relação ao item anterior —
/// mesmo comportamento de `_groupedItem` na tela de detalhe.
pw.Widget? _groupHeader(String? label, String? prevLabel) {
  if (label == null || label.isEmpty || label == prevLabel) return null;
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
    child: pw.Text(
      label,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    ),
  );
}

List<pw.Widget> _ingredientBlocks(List<RecipeIngredient> items) {
  final widgets = <pw.Widget>[];
  String? prevGroup;
  for (final i in items) {
    final header = _groupHeader(i.groupLabel, prevGroup);
    if (header != null) widgets.add(header);
    prevGroup = i.groupLabel;
    widgets.add(_bulletLine(formatIngredientLine(i)));
  }
  return widgets;
}

/// Marcador desenhado como um círculo (`pw.Container`), não um caractere "•"
/// — a fonte Base14 padrão do pacote `pdf` não tem o glyph de bullet
/// (U+2022), então `pw.Bullet` saía sem o marcador na página.
pw.Widget _bulletLine(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 4,
          height: 4,
          margin: const pw.EdgeInsets.only(top: 5, right: 8),
          decoration: const pw.BoxDecoration(
            color: PdfColors.black,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.Expanded(
          child: pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );
}

List<pw.Widget> _stepBlocks(List<RecipeStep> steps) {
  final widgets = <pw.Widget>[];
  String? prevGroup;
  for (var idx = 0; idx < steps.length; idx++) {
    final s = steps[idx];
    final header = _groupHeader(s.groupLabel, prevGroup);
    if (header != null) widgets.add(header);
    prevGroup = s.groupLabel;
    widgets.add(pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 24,
            child: pw.Text(
              '${idx + 1}.',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(s.text, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    ));
  }
  return widgets;
}
