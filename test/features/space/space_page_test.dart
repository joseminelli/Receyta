import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/space/space_remote.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/space/screens/space_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_space_remote.dart';

const _ana = AppUser(id: 'ana', email: 'ana@x.com', name: 'Ana Souza');

void main() {
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureReady();
  });

  tearDown(() => db.close());

  Widget host(FakeSpaceRemote remote, {AppUser? user = _ana}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(FakeAuthService(user: user)),
        spaceRemoteProvider.overrideWithValue(remote),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const SpacePage()),
    );
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 4800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets('sem casa: apresenta o que dá pra dividir e as duas portas',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(host(FakeSpaceRemote()));
    await settle(tester);

    expect(find.text('Cozinhem juntos'), findsOneWidget);
    expect(find.text('Lista de compras'), findsOneWidget);
    expect(find.text('Calendário'), findsOneWidget);
    expect(find.text('Criar uma casa'), findsOneWidget);
    expect(find.text('Tenho um código'), findsOneWidget);
    expect(find.text('Sair da casa'), findsNothing);
  });

  testWidgets('com casa: mostra as pessoas, o que divide e como sair',
      (tester) async {
    phone(tester);
    final remote = FakeSpaceRemote(
      space: const SpaceInfo(
        id: 'casa-1',
        name: 'Casa',
        ownerId: 'ana',
        members: [
          SpaceMember(userId: 'ana', displayName: 'Ana', isOwner: true),
          SpaceMember(userId: 'beto', displayName: 'Beto', isOwner: false),
        ],
      ),
    );
    await tester.pumpWidget(host(remote));
    await settle(tester);

    expect(find.text('Sua casa'), findsOneWidget);
    expect(find.text('2 pessoas'), findsOneWidget);
    expect(find.text('Ana (você)'), findsOneWidget);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('Dono da casa'), findsOneWidget);
    expect(find.text('Convidar alguém'), findsOneWidget);
    expect(find.text('Listas de compras'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Encerrar a casa'), findsOneWidget);
    expect(find.byTooltip('Remover da casa'), findsOneWidget);
  });

  testWidgets('quem não é dono não convida nem remove, e sai da casa',
      (tester) async {
    phone(tester);
    final remote = FakeSpaceRemote(
      userId: 'beto',
      space: const SpaceInfo(
        id: 'casa-1',
        name: 'Casa',
        ownerId: 'ana',
        members: [
          SpaceMember(userId: 'ana', displayName: 'Ana', isOwner: true),
          SpaceMember(userId: 'beto', displayName: 'Beto', isOwner: false),
        ],
      ),
    );
    await tester.pumpWidget(
      host(remote, user: const AppUser(id: 'beto', name: 'Beto')),
    );
    await settle(tester);

    expect(find.text('Convidar alguém'), findsNothing);
    expect(find.byTooltip('Remover da casa'), findsNothing);
    expect(find.text('Sair da casa'), findsOneWidget);
  });

  testWidgets('sem conta, pede pra entrar', (tester) async {
    phone(tester);
    await tester.pumpWidget(host(FakeSpaceRemote(), user: null));
    await settle(tester);

    expect(find.text('Entre na sua conta'), findsOneWidget);
    expect(find.text('Criar uma casa'), findsNothing);
  });
}
