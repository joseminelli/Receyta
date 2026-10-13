import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/features/mascot/painters/mascot_painter.dart';
import 'package:receyta/features/mascot/painters/mascot_pose.dart';
import 'package:receyta/theme/tokens.dart';

import 'clean_mascots.dart';
import 'clean_pote.dart';
import 'render_utils.dart';

/// Gera os PNGs de marketing em `marketing/mascots/`: fundo transparente, sem
/// sombra, alta resolução, desenhados pelos painters limpos de `tool/marketing`
/// (independentes dos modelos do app). Não faz parte da suíte:
/// `flutter test tool/marketing/render_test.dart`.
const _outDir = 'marketing/mascots';

/// Pixels por unidade de projeto: o mascote sai com 200 × escala de largura.
const _scale = 14.0;
const _duoScale = 9.0;

MascotPainter _painter(String who, MascotPose pose) {
  final seconds = ValueNotifier<double>(0);
  final MascotPainter painter = who == 'clo'
      ? CleanClochePainter(
          colors: AppColors.light,
          seconds: seconds,
          poseAt: (_) => pose,
        )
      : CleanPotePainter(
          colors: AppColors.light,
          seconds: seconds,
          poseAt: (_) => pose,
        );
  return painter..paintsShadow = false;
}

ui.Size _sizeOf(String who, double k) => ui.Size(
      MascotPainter.designWidth * k,
      (who == 'clo'
              ? CleanClochePainter.designHeight
              : CleanPotePainter.designHeight) *
          k,
    );

MascotPose _mirrored(MascotPose p) => MascotPose(
      dx: p.dx,
      dy: p.dy,
      scaleX: p.scaleX,
      scaleY: p.scaleY,
      armLeft: p.armRight,
      armRight: p.armLeft,
      handLeft: p.handRight,
      handRight: p.handLeft,
      wristLeft: -p.wristRight,
      wristRight: -p.wristLeft,
      legLeft: p.legRight,
      legRight: p.legLeft,
      blink: p.blink,
      tilt: -p.tilt,
      mouth: p.mouth,
      burst: p.burst,
      lid: p.lid,
      sad: p.sad,
      look: ui.Offset(-p.look.dx, p.look.dy),
    );

void main() {
  testWidgets('renderiza os mascotes de marketing', (tester) async {
    await tester.runAsync(() async {
      final poses = <String, MascotPose>{
        'parado': idlePose(1.6).copyWith(look: const ui.Offset(0.25, -0.12)),
        'aceno': wavingPose(1.0),
        'apresentando': presentingPose(1.0),
        'comemorando': celebratePose(0.6),
        'pensando': thinkingPose(2.0).copyWith(
          armRight: 0.6,
          handRight: 1,
          wristRight: 0.1,
          legRight: 0,
        ),
        'triste': sadPose(1.0),
      };
      for (final who in ['clo', 'tito']) {
        for (final entry in poses.entries) {
          final image = await composeItems([
            RenderItem(_painter(who, entry.value), _sizeOf(who, _scale), 0, 0),
          ]);
          await savePng(image, '$_outDir/${who}_${entry.key}.png', margin: 140);
        }
      }

      final cloSize = _sizeOf('clo', _duoScale);
      final titoSize = _sizeOf('tito', _duoScale);
      const groundClo = 207.0, groundTito = 288.0;
      final duos = <String, (MascotPose, MascotPose, double)>{
        'aceno': (_mirrored(wavingPose(1.0)), wavingPose(1.0), 100),
        'comemorando': (celebratePose(0.6), celebratePose(0.6), 760),
      };
      for (final entry in duos.entries) {
        final image = await composeItems([
          RenderItem(
            _painter('clo', entry.value.$1),
            cloSize,
            0,
            (groundTito - groundClo) * _duoScale,
          ),
          RenderItem(
            _painter('tito', entry.value.$2),
            titoSize,
            cloSize.width + entry.value.$3,
            0,
          ),
        ]);
        await savePng(image, '$_outDir/clo_e_tito_${entry.key}.png',
            margin: 140);
      }
    });
  });
}
