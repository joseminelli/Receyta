/// O link de convite: `https://receyta.whisklinestudio.com/join/<CÓDIGO>`.
/// Clicável em qualquer app de mensagem; com o app instalado abre direto na
/// tela da casa com o código pronto, senão cai na página do site. O QR leva o
/// mesmo link.
const inviteHost = 'receyta.whisklinestudio.com';

String inviteLink(String code) => 'https://$inviteHost/join/$code';

/// O código dentro de um link de convite (https ou o antigo `receyta://`), ou
/// nulo se [text] não é um.
String? inviteCodeFromLink(String text) {
  final match = RegExp(
    r'(?:https?://' + RegExp.escape(inviteHost) + r'|receyta:/)/join/([0-9A-Za-z]{4,16})',
    caseSensitive: false,
  ).firstMatch(text.trim());
  return match?.group(1)?.toUpperCase();
}
