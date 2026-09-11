import 'package:flutter/material.dart';

/// Medalhão de ícone pros estados vazio/sem-resultado/erro/"em breve" — o
/// mesmo par "ícone dentro de bloco de cor saturada" do chip do
/// `AppSnackBar` e do medalhão da `PillNavBar`, grande o bastante pra
/// segurar a tela sozinho em vez do texto solto que o Material dá por
/// padrão.
class StateBadge extends StatelessWidget {
  const StateBadge({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 88,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.43, color: foreground),
    );
  }
}
