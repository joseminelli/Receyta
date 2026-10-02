/// Escalar porções (RF-01.12): só aritmética, sem tocar em banco nem em tela.
/// A escala não grava nada — a receita salva continua com o que foi escrito.
library;

import 'dart:math' as math;

/// Limites do seletor de porções.
const kMinServings = 1;
const kMaxServings = 99;

/// Quanto multiplicar as quantidades pra render [chosen] porções numa receita
/// que rende [base]. Sem rendimento na receita (ou sem escolha), não escala.
double servingFactor({required int? base, required int? chosen}) {
  if (base == null || base <= 0 || chosen == null) return 1;
  return chosen / base;
}

/// Porções escolhidas dentro dos limites; igual ao rendimento original vira
/// `null` ("sem escala"), pra a tela voltar a mostrar o texto digitado.
int? clampServings(int value, {required int? base}) {
  final v = value.clamp(kMinServings, kMaxServings);
  return v == base ? null : v;
}

/// Quantidade escalada, arredondada pro que se mede na cozinha em vez de uma
/// dízima: de 100 pra cima, de 5 em 5; de 10 a 100, inteira; abaixo de 10, em
/// quartos (0,25 · 0,5 · 0,75…), nunca menos que um quarto.
double niceQuantity(double q) {
  if (q <= 0) return q;
  if (q >= 100) return (q / 5).round() * 5;
  if (q >= 10) return q.roundToDouble();
  return math.max(0.25, (q * 4).round() / 4);
}

/// Quantidade escalada pra lista de compras: sempre pra cima, pra não faltar
/// nem aparecer "1,5 ovo". Kg e litro sobem de meio em meio (2 kg a mais por
/// causa de 1,1 kg seria demais); o resto sobe pro inteiro.
double roundUpForShopping(double q, {String? unitId}) {
  if (q <= 0) return q;
  const eps = 1e-9;
  if (unitId == 'kg' || unitId == 'l') {
    return math.max(0.5, ((q - eps) * 2).ceil() / 2);
  }
  return math.max(1, (q - eps).ceilToDouble());
}
