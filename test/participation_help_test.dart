import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:chc_mvp/core/widgets/app_version_tile.dart';
import 'package:chc_mvp/core/theme/theme_provider.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/help/presentation/help_screen.dart';
import 'package:chc_mvp/features/matches/presentation/vote_participation.dart';
import 'package:chc_mvp/features/profile/presentation/profile_screen.dart';
import 'package:chc_mvp/features/badges/presentation/badges_providers.dart';
import 'support/dashboard_fixture.dart';

class ParticipationServer extends Fake implements ServerClient {
  int calls = 0;
  bool fail = false;
  Map<String, dynamic> data = {
    'votedCount': 1,
    'totalCount': 3,
    'status': 'voting_open',
    'pending': [
      {'uid': 'b', 'name': 'Benoît Dupont', 'accountStatus': 'no_account'},
      {'uid': 'c', 'name': 'Camille Petit', 'accountStatus': 'active'},
    ],
  };
  @override
  Future<Map<String, dynamic>> get(String path) async {
    calls++;
    expect(path, '/matches/live/participation');
    if (fail) throw ServerException('Indisponible');
    return data;
  }
}

void main() {
  testWidgets('hidden match tab does not poll and resumes on return', (
    tester,
  ) async {
    final server = ParticipationServer();
    var visible = false;
    late StateSetter update;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminProvider.overrideWithValue(true),
          serverClientProvider.overrideWithValue(server),
        ],
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Scaffold(
                body: TickerMode(
                  enabled: visible,
                  child: const VoteParticipation(matchId: 'live'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(server.calls, 0);
    update(() => visible = true);
    await tester.pumpAndSettle();
    expect(server.calls, 1);
    update(() => visible = false);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 31));
    expect(server.calls, 1);
    update(() => visible = true);
    await tester.pumpAndSettle();
    expect(server.calls, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets('admin sees live turnout and pending names at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final server = ParticipationServer();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWithValue(true),
            serverClientProvider.overrideWithValue(server),
          ],
          child: const MaterialApp(
            home: Scaffold(body: VoteParticipation(matchId: 'live')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 ont voté · Voir le suivi'), findsOneWidget);
      await tester.tap(find.textContaining('Voir le suivi'));
      await tester.pumpAndSettle();
      expect(find.text('Benoît Dupont'), findsOneWidget);
      expect(find.textContaining('Sans compte'), findsOneWidget);
      server.data = {
        ...server.data,
        'votedCount': 2,
        'pending': [server.data['pending'][0]],
      };
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3 ont voté'), findsOneWidget);
      expect(find.text('Camille Petit'), findsNothing);
      expect(server.calls, 2);
      await tester.tap(find.text('Actualiser'));
      await tester.pumpAndSettle();
      expect(server.calls, 3);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pump(const Duration(seconds: 31));
      expect(server.calls, 3); // polling stops when leaving the screen
    });
  }
  testWidgets(
    'member cannot load participation and failures do not display zero',
    (tester) async {
      final server = ParticipationServer()..fail = true;
      for (final admin in [false, true]) {
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(admin),
            overrides: [
              isAdminProvider.overrideWithValue(admin),
              serverClientProvider.overrideWithValue(server),
            ],
            child: const MaterialApp(
              home: Scaffold(body: VoteParticipation(matchId: 'live')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(server.calls, admin ? 1 : 0);
        expect(find.textContaining('0 /'), findsNothing);
      }
      server.fail = false;
      await tester.tap(find.text('Suivi indisponible · Réessayer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 / 3'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  testWidgets(
    'profile exposes platform version and opens the Android/web guide',
    (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'CHC MVP',
        packageName: 'fr.test',
        version: '1.1.0',
        buildNumber: '3',
        buildSignature: '',
      );
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => Stream.value(demoMember),
            ),
            themeModeProvider.overrideWith(() => DemoTheme()),
            userBadgesProvider.overrideWith((ref, uid) => Stream.value({})),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(AppVersionTile),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1.1.0 (3)'), findsOneWidget);
      await tester.ensureVisible(find.text('Tutoriel'));
      await tester.tap(find.text('Tutoriel'));
      await tester.pumpAndSettle();
      expect(find.text('Utiliser l’application Android'), findsOneWidget);
      await tester.tap(find.text('Site web'));
      await tester.pumpAndSettle();
      expect(find.text('Utiliser le site web'), findsOneWidget);
      expect(
        find.textContaining('Le site ne reçoit pas de notifications push'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('3 · Résultats, statistiques et badges'),
        250,
      );
      expect(find.text('Admin · Préparer et gérer les matchs'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('admin guide includes turnout and test match instructions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isAdminProvider.overrideWithValue(true)],
        child: const MaterialApp(home: HelpScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final title = find.text('Admin · Préparer et gérer les matchs');
    await tester.scrollUntilVisible(title, 300);
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sur chaque carte de match'), findsOneWidget);
    final tests = find.text('Admin · Essayer sans toucher aux classements');
    await tester.scrollUntilVisible(tests, 300);
    await tester.tap(tests);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('La simulation n’est jamais disponible'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
