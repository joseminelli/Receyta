import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:receyta/domain/engine/achievements.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Cor de acento de uma conquista na paleta do app.
Color achievementAccent(AppColors colors, AchievementTone tone) =>
    switch (tone) {
      AchievementTone.lime => colors.lime,
      AchievementTone.coral => colors.coral,
      AchievementTone.violet => colors.violetMuted,
    };

/// Medalha desenhada à mão: aro metálico em degradê na cor da categoria, face
/// `ink` com um brilho suave e um traço próprio de cada conquista no centro.
/// Bloqueada, vira um aro apagado sobre o papel, com um cadeado miúdo.
class AchievementEmblem extends StatelessWidget {
  const AchievementEmblem({
    super.key,
    required this.id,
    required this.tone,
    required this.unlocked,
    this.size = 72,
  });

  final AchievementId id;
  final AchievementTone tone;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = achievementAccent(colors, tone);
    final lockSize = size * 0.3;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _EmblemPainter(
              id: id,
              unlocked: unlocked,
              accent: accent,
              face: unlocked ? colors.ink : colors.paper,
              muted: colors.textMuted,
            ),
          ),
          if (!unlocked)
            Positioned(
              right: -size * 0.02,
              bottom: -size * 0.02,
              child: Container(
                width: lockSize,
                height: lockSize,
                decoration: BoxDecoration(
                  color: colors.paperSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.paper, width: 2),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: lockSize * 0.55,
                  color: colors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter({
    required this.id,
    required this.unlocked,
    required this.accent,
    required this.face,
    required this.muted,
  });

  final AchievementId id;
  final bool unlocked;
  final Color accent;
  final Color face;
  final Color muted;

  Color _shade(Color c, double lightness) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(s / 2, s / 2);
    final rim = s * 0.085;

    if (unlocked) {
      final hsl = HSLColor.fromColor(accent);
      final light = _shade(accent, hsl.lightness + 0.18);
      final dark = _shade(accent, hsl.lightness - 0.18);
      canvas.drawCircle(
        center,
        s / 2 - rim / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim
          ..shader = SweepGradient(
            colors: [light, accent, dark, accent, light],
            transform: const GradientRotation(-math.pi / 4),
          ).createShader(Offset.zero & size),
      );
    } else {
      canvas.drawCircle(
        center,
        s / 2 - rim / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim * 0.6
          ..color = muted.withValues(alpha: 0.4),
      );
    }

    final faceRadius = s / 2 - rim - s * 0.02;
    canvas.drawCircle(center, faceRadius, Paint()..color = face);
    if (unlocked) {
      canvas.drawCircle(
        center,
        faceRadius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1,
            colors: [
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: faceRadius)),
      );
      canvas.drawCircle(
        center,
        faceRadius * 0.86,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = accent.withValues(alpha: 0.35),
      );
    }

    final box = s * 0.46;
    canvas.save();
    canvas.translate(center.dx - box / 2, center.dy - box / 2);
    canvas.scale(box / 24);
    canvas.drawPath(
      _glyph(id),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = unlocked ? accent : muted.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.id != id ||
      old.unlocked != unlocked ||
      old.accent != accent ||
      old.face != face ||
      old.muted != muted;
}

Path _glyph(AchievementId id) => switch (id) {
      AchievementId.firstRecipe => _book(),
      AchievementId.tenRecipes => _books(),
      AchievementId.twentyFiveRecipes => _bookWithStar(),
      AchievementId.firstFavorite => _heart(),
      AchievementId.firstCooked => _pot(),
      AchievementId.tenCooked => _cutlery(),
      AchievementId.fiftyCooked => _chefHat(),
      AchievementId.firstMeal => _calendarCheck(),
      AchievementId.plannedWeek => _calendarWeek(),
      AchievementId.firstShoppingList => _basket(),
      AchievementId.house => _house(),
    };

Path _book() => Path()
  ..moveTo(12, 7)
  ..cubicTo(9.5, 5.3, 6.5, 5, 3.5, 6)
  ..lineTo(3.5, 18.5)
  ..cubicTo(6.5, 17.5, 9.5, 17.8, 12, 19.5)
  ..cubicTo(14.5, 17.8, 17.5, 17.5, 20.5, 18.5)
  ..lineTo(20.5, 6)
  ..cubicTo(17.5, 5, 14.5, 5.3, 12, 7)
  ..close()
  ..moveTo(12, 7)
  ..lineTo(12, 19.5);

Path _books() => Path()
  ..addRRect(RRect.fromLTRBR(4, 8, 8.5, 19, const Radius.circular(1)))
  ..addRRect(RRect.fromLTRBR(9.75, 5, 14.25, 19, const Radius.circular(1)))
  ..addRRect(RRect.fromLTRBR(15.5, 9.5, 20, 19, const Radius.circular(1)))
  ..moveTo(3, 20.2)
  ..lineTo(21, 20.2);

Path _bookWithStar() {
  final book = _book().transform(
    (Matrix4.identity()
          ..translateByDouble(2.4, 5.2, 0, 1)
          ..scaleByDouble(0.8, 0.8, 1, 1))
        .storage,
  );
  return book..addPath(_star(const Offset(12, 4.2), 2.8), Offset.zero);
}

Path _star(Offset c, double r) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? r : r * 0.45;
    final angle = -math.pi / 2 + i * math.pi / 5;
    final p = Offset(
        c.dx + radius * math.cos(angle), c.dy + radius * math.sin(angle));
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

Path _heart() => Path()
  ..moveTo(12, 20)
  ..cubicTo(5, 14.5, 3, 11, 3, 8.5)
  ..cubicTo(3, 6, 5, 4.5, 7, 4.5)
  ..cubicTo(9, 4.5, 11, 5.7, 12, 7.5)
  ..cubicTo(13, 5.7, 15, 4.5, 17, 4.5)
  ..cubicTo(19, 4.5, 21, 6, 21, 8.5)
  ..cubicTo(21, 11, 19, 14.5, 12, 20)
  ..close();

Path _pot() => Path()
  ..moveTo(5, 11)
  ..lineTo(19, 11)
  ..lineTo(19, 16)
  ..cubicTo(19, 18.2, 17.2, 19.5, 15.5, 19.5)
  ..lineTo(8.5, 19.5)
  ..cubicTo(6.8, 19.5, 5, 18.2, 5, 16)
  ..close()
  ..moveTo(10.5, 9)
  ..lineTo(13.5, 9)
  ..moveTo(5, 13.5)
  ..lineTo(3, 13.5)
  ..moveTo(19, 13.5)
  ..lineTo(21, 13.5)
  ..moveTo(9, 7.5)
  ..cubicTo(8, 6.5, 10, 5.5, 9, 4.2)
  ..moveTo(13, 7.5)
  ..cubicTo(12, 6.5, 14, 5.5, 13, 4.2);

Path _cutlery() => Path()
  ..moveTo(5.5, 4)
  ..lineTo(5.5, 9)
  ..moveTo(8.25, 4)
  ..lineTo(8.25, 9)
  ..moveTo(11, 4)
  ..lineTo(11, 9)
  ..moveTo(5.5, 9)
  ..quadraticBezierTo(5.5, 12, 8.25, 12)
  ..quadraticBezierTo(11, 12, 11, 9)
  ..moveTo(8.25, 12)
  ..lineTo(8.25, 20)
  ..moveTo(16.5, 20)
  ..lineTo(16.5, 4)
  ..cubicTo(19.5, 6, 19.5, 11, 16.5, 13);

Path _chefHat() => Path()
  ..moveTo(7, 18.5)
  ..lineTo(17, 18.5)
  ..lineTo(17, 13.5)
  ..cubicTo(20, 13, 21, 8.5, 17.5, 8)
  ..cubicTo(17, 5, 13.8, 4.2, 12, 6)
  ..cubicTo(10.2, 4.2, 7, 5, 6.5, 8)
  ..cubicTo(3, 8.5, 4, 13, 7, 13.5)
  ..close()
  ..moveTo(7, 16)
  ..lineTo(17, 16);

Path _calendarFrame() => Path()
  ..addRRect(RRect.fromLTRBR(4, 6, 20, 20, const Radius.circular(2.5)))
  ..moveTo(4, 10.5)
  ..lineTo(20, 10.5)
  ..moveTo(8, 4)
  ..lineTo(8, 7.5)
  ..moveTo(16, 4)
  ..lineTo(16, 7.5);

Path _calendarCheck() => _calendarFrame()
  ..moveTo(8.8, 15.2)
  ..lineTo(11, 17.4)
  ..lineTo(15.3, 13);

Path _calendarWeek() {
  final path = _calendarFrame();
  for (final y in [14.0, 17.0]) {
    for (final x in [8.0, 12.0, 16.0]) {
      path.addOval(Rect.fromCircle(center: Offset(x, y), radius: 0.4));
    }
  }
  return path;
}

Path _basket() => Path()
  ..moveTo(3.5, 10)
  ..lineTo(20.5, 10)
  ..moveTo(5, 10)
  ..lineTo(6.5, 19)
  ..lineTo(17.5, 19)
  ..lineTo(19, 10)
  ..moveTo(8, 10)
  ..lineTo(10.5, 5)
  ..moveTo(16, 10)
  ..lineTo(13.5, 5)
  ..moveTo(10, 13)
  ..lineTo(10, 16)
  ..moveTo(14, 13)
  ..lineTo(14, 16);

Path _house() => Path()
  ..moveTo(3.5, 11.5)
  ..lineTo(12, 4.5)
  ..lineTo(20.5, 11.5)
  ..moveTo(5.5, 10)
  ..lineTo(5.5, 19.5)
  ..lineTo(18.5, 19.5)
  ..lineTo(18.5, 10)
  ..moveTo(10, 19.5)
  ..lineTo(10, 14.5)
  ..lineTo(14, 14.5)
  ..lineTo(14, 19.5);
