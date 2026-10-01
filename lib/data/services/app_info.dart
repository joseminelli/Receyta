import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// E-mail que recebe o feedback do app. Vazio = o botão abre o menu de
/// compartilhar do celular com a mensagem pronta, em vez de um e-mail.
const kFeedbackEmail = '';

/// "1.0.0 (3)": versão e build instalados. Vazio se a leitura falhar.
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  } catch (e) {
    debugPrint('appVersionProvider: $e');
    return '';
  }
});

/// Texto do feedback: categoria, a mensagem da pessoa e a versão do app.
String composeFeedback({
  required String message,
  String category = '',
  String version = '',
}) {
  final buffer = StringBuffer();
  if (category.isNotEmpty) buffer.writeln('[$category]\n');
  buffer.write(message.trim());
  buffer.write('\n\n—\nReceyta');
  if (version.isNotEmpty) buffer.write(' $version');
  return buffer.toString();
}

/// Envia o feedback. Com [kFeedbackEmail] abre o app de e-mail já preenchido;
/// sem ele, o menu de compartilhar com o texto pronto.
class FeedbackService {
  Future<void> send({
    required String message,
    String category = '',
    String version = '',
  }) async {
    const subject = 'Feedback do Receyta';
    final text = composeFeedback(
      message: message,
      category: category,
      version: version,
    );
    if (kFeedbackEmail.isEmpty) {
      await Share.share(text, subject: subject);
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: kFeedbackEmail,
      queryParameters: {'subject': subject, 'body': text},
    );
    await launchUrl(uri);
  }
}

final feedbackServiceProvider = Provider<FeedbackService>(
  (ref) => FeedbackService(),
);
