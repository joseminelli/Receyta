import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:receyta/features/space/controllers/invite_link.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/circle_icon_button.dart';

/// Abre a câmera pra ler o QR de um convite e devolve o código (ou nulo se a
/// pessoa fechar sem ler).
Future<String?> scanInviteCode(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const _InviteScanPage()),
  );
}

class _InviteScanPage extends StatefulWidget {
  const _InviteScanPage();

  @override
  State<_InviteScanPage> createState() => _InviteScanPageState();
}

class _InviteScanPageState extends State<_InviteScanPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final code = inviteCodeFromLink(raw) ?? normalizeInviteCode(raw);
      if (code.length < 4) continue;
      _done = true;
      Navigator.of(context).pop(code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Não foi possível abrir a câmera. Confira a permissão do '
                  'app nas configurações do aparelho.',
                  textAlign: TextAlign.center,
                  style: context.texts.bodyLarge
                      ?.copyWith(color: colors.onSaturated),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: colors.lime, width: 3),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Fechar',
                    background: colors.inkSoft,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(
                    'Aponte para o QR do convite',
                    style: AppTextStyles.display(26)
                        .copyWith(color: colors.onSaturated),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
