/// O link de convite: `receyta://join/<CÓDIGO>`. Abre o app direto na tela da
/// casa com o código pronto, quando o aplicativo onde ele aparece deixa tocar
/// nele (e também no QR do convite).
String inviteLink(String code) => 'receyta://join/$code';

/// O código dentro de um link de convite, ou nulo se [text] não é um.
String? inviteCodeFromLink(String text) {
  final match = RegExp(
    r'receyta://join/([0-9A-Za-z]{4,16})',
    caseSensitive: false,
  ).firstMatch(text.trim());
  return match?.group(1)?.toUpperCase();
}
