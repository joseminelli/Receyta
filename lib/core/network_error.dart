import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Se [error] é falta de internet (sem rota, DNS, conexão caída, timeout). Os
/// pacotes às vezes embrulham a falha noutro tipo; o texto entrega.
bool isOfflineError(Object error) {
  if (error is SocketException ||
      error is HandshakeException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return true;
  }
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('unable to resolve host') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection reset') ||
      text.contains('connection closed') ||
      text.contains('connection abort');
}

/// Mensagem padrão para uma ação que precisa de internet e não achou.
const offlineMessage = 'Sem internet. Conecte-se e tente de novo.';
