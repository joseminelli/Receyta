import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/sync/sync_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

void main() {
  SyncProblem problemOf(Object e) => classifySyncError(e).problem;

  group('sem internet', () {
    test('socket, timeout, handshake e falha de cliente HTTP', () {
      expect(problemOf(const SocketException('x')), SyncProblem.offline);
      expect(problemOf(TimeoutException('x')), SyncProblem.offline);
      expect(problemOf(const HandshakeException('x')), SyncProblem.offline);
      expect(problemOf(http.ClientException('x')), SyncProblem.offline);
    });

    test('falha de rede do login do Supabase que pode ser repetida', () {
      expect(problemOf(sb.AuthRetryableFetchException(message: 'x')),
          SyncProblem.offline);
    });

    test('erro embrulhado em outro tipo, só o texto denuncia', () {
      expect(problemOf(Exception('Failed host lookup: kcaq.supabase.co')),
          SyncProblem.offline);
      expect(
          problemOf(Exception('Network is unreachable')), SyncProblem.offline);
      expect(problemOf(Exception('Connection reset by peer')),
          SyncProblem.offline);
    });

    test('a mensagem diz que tenta de novo sozinho', () {
      expect(classifySyncError(const SocketException('x')).message,
          'Sem internet. Tentamos de novo sozinhos.');
    });
  });

  group('espaço da nuvem acabou', () {
    test('banco somente leitura (código 25006 ou texto)', () {
      expect(
        problemOf(sb.PostgrestException(message: 'x', code: '25006')),
        SyncProblem.serverFull,
      );
      expect(
        problemOf(sb.PostgrestException(
          message: 'cannot execute INSERT in a read-only transaction',
        )),
        SyncProblem.serverFull,
      );
    });

    test('disco cheio', () {
      expect(
        problemOf(sb.PostgrestException(message: 'No space left on device')),
        SyncProblem.serverFull,
      );
    });

    test('a mensagem tranquiliza: os dados seguem no aparelho', () {
      final f =
          classifySyncError(sb.PostgrestException(message: 'x', code: '25006'));

      expect(f.message, contains('espaço da nuvem acabou'));
      expect(f.message, contains('neste aparelho'));
    });
  });

  group('sessão vencida', () {
    test('erro de autenticação do Supabase', () {
      expect(
        problemOf(sb.AuthException('Invalid Refresh Token', statusCode: '400')),
        SyncProblem.auth,
      );
      expect(problemOf(sb.AuthSessionMissingException()), SyncProblem.auth);
    });

    test('JWT vencido vindo da API de dados', () {
      expect(
        problemOf(
            sb.PostgrestException(message: 'JWT expired', code: 'PGRST301')),
        SyncProblem.auth,
      );
      expect(
        problemOf(sb.PostgrestException(message: 'invalid JWT: bad signature')),
        SyncProblem.auth,
      );
    });

    test('a mensagem manda entrar de novo', () {
      expect(
        classifySyncError(sb.AuthException('x', statusCode: '401')).message,
        contains('Entre de novo'),
      );
    });
  });

  group('servidor com problemas', () {
    test('status 5xx', () {
      for (final code in ['500', '502', '503', '504']) {
        expect(problemOf(sb.PostgrestException(message: 'x', code: code)),
            SyncProblem.server,
            reason: code);
      }
    });

    test('tabela ou regra do servidor ainda não prontas (SQL não rodado)', () {
      for (final code in ['42P01', 'PGRST205', '23514']) {
        expect(problemOf(sb.PostgrestException(message: 'x', code: code)),
            SyncProblem.server,
            reason: code);
      }
    });

    test('Storage e funções com 5xx', () {
      expect(problemOf(sb.StorageException('x', statusCode: '503')),
          SyncProblem.server);
      expect(problemOf(sb.FunctionException(status: 502)), SyncProblem.server);
    });
  });

  group('o resto', () {
    test('erro desconhecido vira mensagem genérica e guarda a causa', () {
      final cause = StateError('algo estranho');

      final f = classifySyncError(cause);

      expect(f.problem, SyncProblem.unknown);
      expect(f.cause, same(cause));
      expect(f.message, contains('Não foi possível sincronizar'));
    });

    test('4xx comum do banco não é tratado como servidor fora do ar', () {
      expect(problemOf(sb.PostgrestException(message: 'x', code: '23505')),
          SyncProblem.unknown);
    });

    test('NUNCA vaza o texto cru do servidor pra mensagem da tela', () {
      final raw = sb.PostgrestException(
        message: 'relation "public.sync_docs" does not exist',
        code: '42P01',
      );

      final f = classifySyncError(raw);

      expect(f.message, isNot(contains('sync_docs')));
      expect(f.message, isNot(contains('relation')));
      expect(f.cause, same(raw));
    });

    test('é uma Failure normal (serve onde se espera Failure)', () {
      expect(classifySyncError(StateError('x')), isA<Failure>());
    });
  });

  group('falha no login com Google', () {
    test('sem internet, por qualquer caminho', () {
      expect(
          failureForSignIn(const SocketException('x')), isA<NetworkFailure>());
      expect(
        failureForSignIn(PlatformException(code: 'network_error')),
        isA<NetworkFailure>(),
      );
      expect(
        failureForSignIn(Exception('Unable to resolve host "x"')),
        isA<NetworkFailure>(),
      );
      expect(failureForSignIn(const SocketException('x')).message,
          'Sem internet. Conecte-se e tente de novo.');
    });

    test('o Google recusando neste aparelho (configuração)', () {
      final f = failureForSignIn(PlatformException(code: 'sign_in_failed'));

      expect(f, isA<ProcessingFailure>());
      expect(f.message, contains('com o Google neste aparelho'));
    });

    test('erro do Supabase em inglês não vai pra tela', () {
      final f = failureForSignIn(
        sb.AuthException('Unable to validate email address: invalid format'),
      );

      expect(f.message, 'Não foi possível entrar. Tente de novo.');
      expect(f.message, isNot(contains('email')));
      expect(f.cause, isA<sb.AuthException>());
    });
  });
}
