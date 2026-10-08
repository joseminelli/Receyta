import 'package:flutter/material.dart';

/// A partir daqui a tela comporta duas colunas: tablet em pé ou deitado e
/// celular deitado. Por largura, não por tipo de aparelho.
const kWideBreakpoint = 720.0;

/// Largura máxima de um cartão da grade de receitas/pastas: em celular em pé
/// dá 2 colunas, em tablet ou deitado, 3 ou mais.
const kGridTileMaxExtent = 240.0;

bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWideBreakpoint;

/// Largura da coluna lateral (ingredientes, capa) no layout largo.
double sidePaneWidth(BuildContext context) =>
    (MediaQuery.sizeOf(context).width * 0.4).clamp(320.0, 460.0);
