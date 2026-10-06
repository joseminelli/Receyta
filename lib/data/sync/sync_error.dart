import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:receyta/core/result.dart';

/// Transforma o que quebrou numa rodada de sincronização em algo que a pessoa
/// entende e que o coordenador sabe tratar. Sem internet, servidor ruim,
/// espaço da nuvem acabado e sessão vencida pedem reações diferentes — e
/// antes todos viravam "Sem conexão".
///
/// Nunca devolve o texto cru do servidor (em inglês, técnico, às vezes com
/// nome de tabela): ele fica só em `cause`, pra log e relatório de erros.
SyncFailure classifySyncError(Object error) {
  if (_isOffline(error)) {
    return SyncFailure(
      SyncProblem.offline,
      'Sem internet. Tentamos de novo sozinhos.',
      cause: error,
    );
  }

  if (error is sb.AuthException) {
    return SyncFailure(
      SyncProblem.auth,
      'Sua sessão expirou. Entre de novo para voltar a sincronizar.',
      cause: error,
    );
  }

  if (error is sb.PostgrestException) {
    final code = error.code ?? '';
    final text = '${error.message} ${error.details ?? ''}'.toLowerCase();

    // Banco sem espaço (o plano gratuito vira "somente leitura") ou disco cheio.
    if (code == '25006' ||
        text.contains('read-only') ||
        text.contains('read only') ||
        text.contains('no space left') ||
        text.contains('disk full')) {
      return SyncFailure(
        SyncProblem.serverFull,
        'O espaço da nuvem acabou. Seus dados continuam salvos neste aparelho.',
        cause: error,
      );
    }
    if (code == 'PGRST301' || code == 'PGRST303' || text.contains('jwt')) {
      return SyncFailure(
        SyncProblem.auth,
        'Sua sessão expirou. Entre de novo para voltar a sincronizar.',
        cause: error,
      );
    }
    if (_isServerStatus(code) ||
        code == '42P01' || // tabela ainda não criada (SQL não rodado)
        code == 'PGRST205' ||
        code == '23514') {
      // regra de tipos do servidor desatualizada
      return SyncFailure(
        SyncProblem.server,
        'O servidor está com problemas. Tentamos de novo sozinhos.',
        cause: error,
      );
    }
  }

  if (error is sb.StorageException && _isServerStatus(error.statusCode ?? '')) {
    return SyncFailure(
      SyncProblem.server,
      'O servidor está com problemas. Tentamos de novo sozinhos.',
      cause: error,
    );
  }
  if (error is sb.FunctionException && error.status >= 500) {
    return SyncFailure(
      SyncProblem.server,
      'O servidor está com problemas. Tentamos de novo sozinhos.',
      cause: error,
    );
  }

  return SyncFailure(
    SyncProblem.unknown,
    'Não foi possível sincronizar agora. Tentamos de novo sozinhos.',
    cause: error,
  );
}

bool _isServerStatus(String code) =>
    code.length == 3 && code.startsWith('5') && int.tryParse(code) != null;

bool _isOffline(Object error) {
  if (error is SocketException ||
      error is HandshakeException ||
      error is TimeoutException ||
      error is http.ClientException ||
      error is sb.AuthRetryableFetchException) {
    return true;
  }
  // O Supabase às vezes embrulha a falha de rede noutro tipo; o texto entrega.
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection reset') ||
      text.contains('connection closed') ||
      text.contains('connection abort');
}
