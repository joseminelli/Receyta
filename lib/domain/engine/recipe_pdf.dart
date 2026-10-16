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
  final doc = pw.Document(title: detail.recipe.name, creator: 'Receyta');
  doc.addPage(_recipePage(detail, banner: banner));
  return doc.save();
}

/// Uma receita do livro: o PDF já pronto de [detail] e a foto dela, se tiver.
typedef RecipeBookEntry = ({
  RecipeDetail detail,
  Uint8List? banner,
  Uint8List? photo,
});

/// O livro de receitas: capa ([cover] é o PNG de `renderRecipeBookCover`),
/// sumário com links e uma ou mais páginas por receita, na ordem de [entries].
Future<Uint8List> buildRecipeBookPdf({
  required String title,
  required List<RecipeBookEntry> entries,
  Uint8List? cover,
}) async {
  final doc = pw.Document(title: title, creator: 'Receyta');

  if (cover != null) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(pw.MemoryImage(cover), fit: pw.BoxFit.cover),
        ),
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageTheme: _pageTheme(),
      footer: (context) => _footer(title, context),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Sumário',
              style: pw.TextStyle(
                fontSize: 30,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const pw.EdgeInsets.only(bottom: 5),
              decoration: pw.BoxDecoration(
                color: _ink,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                '${entries.length} ${entries.length == 1 ? 'receita' : 'receitas'}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _lime,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        for (var i = 0; i < entries.length; i += 2)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _indexCard(i, entries[i].detail),
                pw.SizedBox(width: 10),
                if (i + 1 < entries.length)
                  _indexCard(i + 1, entries[i + 1].detail)
                else
                  pw.SizedBox(width: _indexCardWidth),
              ],
            ),
          ),
      ],
    ),
  );

  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    doc.addPage(
      _recipePage(
        e.detail,
        banner: e.banner,
        photo: e.photo,
        anchor: 'recipe-$i',
        footerLabel: title,
      ),
    );
  }
  return doc.save();
}

final _indexCardWidth = (PdfPageFormat.a4.width - 72 - 10) / 2;

/// Cartão do sumário: faixa na cor da receita, número, nome e os tempos. O
/// cartão inteiro é um link pra página da receita.
pw.Widget _indexCard(int index, RecipeDetail detail) {
  final recipe = detail.recipe;
  final accent = _accentOf(recipe);
  final minutes = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
  final meta = [
    if (minutes > 0) '$minutes min',
    if (recipe.servings != null) '${recipe.servings} porções',
  ].join('  |  ');
  return pw.Link(
    destination: 'recipe-$index',
    child: pw.Container(
      width: _indexCardWidth,
      height: 56,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _paperSoft, width: 1.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            width: 34,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(11),
                bottomLeft: pw.Radius.circular(11),
              ),
            ),
            child: pw.Text(
              '${index + 1}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _onAccent(accent),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(10, 9, 8, 9),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _pdfSafe(recipe.name),
                    maxLines: 2,
                    style: pw.TextStyle(
                      fontSize: 11.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      meta,
                      style: const pw.TextStyle(fontSize: 9, color: _muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Texto escuro sobre cor clara, branco sobre escura.
PdfColor _onAccent(PdfColor c) =>
    (0.299 * c.red + 0.587 * c.green + 0.114 * c.blue) > 0.6
        ? _ink
        : PdfColors.white;

pw.PageTheme _pageTheme() => pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 44),
      buildBackground: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(color: _paper),
      ),
    );

pw.Widget _footer(String? label, pw.Context context) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label == null
                ? 'Receyta  |  Suas receitas, num lugar só'
                : 'Receyta  |  ${_pdfSafe(label)}',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
          pw.Text(
            label == null
                ? '${context.pageNumber}/${context.pagesCount}'
                : '${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );

pw.MultiPage _recipePage(
  RecipeDetail detail, {
  Uint8List? banner,
  Uint8List? photo,
  String? anchor,
  String? footerLabel,
}) {
  final recipe = detail.recipe;
  final accent = _accentOf(recipe);

  return pw.MultiPage(
    pageTheme: _pageTheme(),
    footer: (context) => _footer(footerLabel, context),
    build: (context) => [
      if (anchor != null) pw.Anchor(name: anchor, child: pw.SizedBox()),
      if (banner != null)
        pw.Image(pw.MemoryImage(banner), width: PdfPageFormat.a4.width - 72)
      else
        pw.Text(
          _pdfSafe(recipe.name),
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      if (photo != null) ...[
        pw.SizedBox(height: 14),
        pw.ClipRRect(
          horizontalRadius: 16,
          verticalRadius: 16,
          child: pw.Image(
            pw.MemoryImage(photo),
            width: PdfPageFormat.a4.width - 72,
            height: 230,
            fit: pw.BoxFit.cover,
          ),
        ),
      ],
      pw.SizedBox(height: 14),
      _metricsRow(recipe),
      if ((recipe.about ?? '').isNotEmpty) ...[
        pw.SizedBox(height: 14),
        pw.Text(
          _pdfSafe(recipe.about!),
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
            _pdfSafe(recipe.notes!),
            style: const pw.TextStyle(
              fontSize: 12,
              color: _body,
              lineSpacing: 3,
            ),
          ),
        ),
      ],
    ],
  );
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
      _pdfSafe(label.toUpperCase()),
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
    lines.add(_bulletLine(_pdfSafe(formatIngredientLine(i)), accent));
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
                _pdfSafe(s.text),
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

/// As fontes padrão do PDF só têm Latin-1: troca aspas, travessões e frações
/// curtas pelos equivalentes simples e tira o que não cabe (emoji, símbolos),
/// em vez de sair um quadradinho.
String _pdfSafe(String text) {
  const swaps = {
    '–': '-',
    '—': '-',
    '−': '-',
    '‘': "'",
    '’': "'",
    '“': '"',
    '”': '"',
    '…': '...',
    '•': '-',
    ' ': ' ',
    '⅓': '1/3',
    '⅔': '2/3',
    '⅛': '1/8',
    '⅜': '3/8',
    '⅝': '5/8',
    '⅞': '7/8',
    '⅕': '1/5',
    '⅙': '1/6',
    '⁄': '/',
  };
  final out = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    final swap = swaps[ch];
    if (swap != null) {
      out.write(swap);
    } else if (rune == 0x0A || (rune >= 0x20 && rune <= 0xFF)) {
      out.write(ch);
    }
  }
  return out.toString();
}
