import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chc_mvp/features/ceremonies/ceremony_model.dart';
import 'package:chc_mvp/features/ceremonies/ceremonies_providers.dart';
import 'package:chc_mvp/features/ceremonies/ceremonies_screen.dart';
import 'package:chc_mvp/features/ceremonies/ceremony_form.dart';
import 'package:chc_mvp/features/ceremonies/reveal_screen.dart';
import 'package:chc_mvp/features/ceremonies/youtube_video.dart';
import 'package:chc_mvp/features/ceremonies/android_youtube_player.dart';
import 'package:chc_mvp/features/ceremonies/award_widgets.dart';
import 'package:chc_mvp/features/home/domain/badge_model.dart';
import 'package:chc_mvp/features/home/presentation/badges_section.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_screen.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_providers.dart';
import 'package:chc_mvp/features/badges/presentation/badges_providers.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/core/services/server_client.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'support/dashboard_fixture.dart';

Ceremony event({
  String status = 'closed',
  bool tie = false,
  bool duplicatePlayer = false,
}) => Ceremony.fromMap('award', {
  'title': 'Ballon d\'or 2026',
  'category': 'ballon_or',
  'status': status,
  'topSize': 5,
  'voteCount': status == 'closed' ? 1 : 0,
  'voterIds': ['camille'],
  'allowSelfVote': true,
  'nominees': [
    if (duplicatePlayer)
      {
        'id': 'n7',
        'uid': 'guest',
        'name': 'Joueur 1',
        'label': 'Autre action',
        'videoId': null,
      },
    for (var i = 1; i <= 6; i++)
      {
        'id': 'n$i',
        'uid': i == 1 ? 'guest' : 'p$i',
        'name': 'Joueur $i',
        'label': 'Action $i',
        'videoId': null,
      },
  ],
  'results': status == 'closed'
      ? [
          for (var i = 1; i <= 5; i++)
            {
              'id': 'n$i',
              'uid': i == 1 ? 'guest' : 'p$i',
              'name': 'Joueur $i',
              'label': 'Action $i',
              'rank': tie && i == 2 ? 1 : i,
              'points': 6 - i,
            },
        ]
      : [],
});

class RecordingServer extends ServerClient {
  Map<String, dynamic>? ballot;
  String? path;
  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    this.path = path;
    ballot = Map.of(body);
    return {'success': true};
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));
  test('badge tier keeps a single category with the highest reached tier', () {
    expect(Badge.forEarned(BadgeType.buteur, ['buteur']).tier, 'Bronze');
    expect(
      Badge.forEarned(BadgeType.buteur, ['buteur', 'buteurArgent']).tier,
      'Argent',
    );
    expect(
      Badge.forEarned(BadgeType.buteur, [
        'buteur',
        'buteurArgent',
        'buteurOr',
      ]).tier,
      'Or',
    );
    expect(
      Badge.forEarned(BadgeType.passeurDor, [
        'passeurDor',
        'passeurOr',
      ]).earnedKey,
      'passeurOr',
    );
    expect(Badge.forEarned(BadgeType.buteur, ['buteur']).tier, 'Bronze');
    expect(event().winners, {'guest'});
    expect(event(status: 'open').winners, isEmpty);
    expect(event(tie: true).winners, {'guest', 'p2'});
    expect(
      Badge.forEarned(BadgeType.capDes50, ['capDes50']).label,
      'Cap des 50',
    );
    expect(
      Badge.allDefinitions[BadgeType.capDes50]!.description,
      contains('l\'ensemble des saisons'),
    );
    final swiss = Badge.forEarned(BadgeType.couteauSuisse, [
      'couteauSuisse',
      'couteauSuisseArgent',
      'couteauSuisseOr',
    ]);
    expect(swiss.earnedKey, 'couteauSuisseOr');
    expect(swiss.label, 'Couteau suisse · Or');
    expect(swiss.description, contains('15 buts ET'));
    expect(
      Badge.forEarned(BadgeType.buteur, ['buteur', 'buteurArgent']).description,
      contains('15 buts'),
    );
  });
  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    Ceremony? ceremony,
    RecordingServer? server,
    bool admin = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: demoOverrides,
        child: ProviderScope(
          overrides: [
            isAdminProvider.overrideWithValue(admin),
            ceremoniesProvider.overrideWith(
              (ref) => Stream.value([ceremony ?? event()]),
            ),
            myCeremonyVoteProvider.overrideWith(
              (ref, id) => Stream.value(null),
            ),
            if (server != null) serverClientProvider.overrideWithValue(server),
          ],
          child: MaterialApp(home: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reveal goes from fifth to first and can be replayed', (
    tester,
  ) async {
    await mount(tester, RevealScreen(ceremony: event()));
    await tester.tap(find.text('Lancer la révélation'));
    await tester.pumpAndSettle();
    expect(find.text('5ᵉ place'), findsOneWidget);
    expect(find.text('Joueur 1'), findsNothing);
    for (var i = 4; i >= 1; i--) {
      await tester.tap(find.text('Révéler la place suivante'));
      await tester.pumpAndSettle();
      expect(find.text('Joueur $i'), findsOneWidget);
    }
    await tester.tap(find.text('Rejouer la cérémonie'));
    await tester.pumpAndSettle();
    expect(find.text('Prêts pour la révélation ?'), findsOneWidget);
  });
  testWidgets('vote sends the ordered top only after confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final server = RecordingServer();
    await mount(
      tester,
      const CeremonyDetailScreen(id: 'award'),
      ceremony: event(status: 'open'),
      server: server,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Valider mon vote'),
          )
          .onPressed,
      isNull,
    );
    for (var i = 1; i <= 5; i++) {
      final dropdown = find.byType(DropdownButtonFormField<String>).at(i - 1);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Joueur $i · Action $i').last);
      await tester.pumpAndSettle();
    }
    // A fully filled top can still be corrected without introducing duplicates.
    final first = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(first);
    await tester.tap(first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 2 · Action 2').last);
    await tester.pumpAndSettle();
    // The used player stays disabled; close the menu and clear both positions.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    for (final place in [1, 2]) {
      await tester.ensureVisible(find.byTooltip('Effacer la place $place'));
      await tester.tap(find.byTooltip('Effacer la place $place'));
      await tester.pumpAndSettle();
    }
    for (final slot in [0, 1]) {
      final dropdown = find.byType(DropdownButtonFormField<String>).at(slot);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      final player = slot == 0 ? 2 : 1;
      await tester.tap(find.text('Joueur $player · Action $player').last);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Valider mon vote'));
    await tester.tap(find.text('Valider mon vote'));
    await tester.pumpAndSettle();
    expect(server.ballot, isNull);
    await tester.tap(find.text('Confirmer').last);
    await tester.pumpAndSettle();
    expect(server.ballot?['choices'], ['n2', 'n1', 'n3', 'n4', 'n5']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('YouTube is never instantiated before consent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: YoutubeVideo(videoId: 'abcdefghijk')),
      ),
    );
    expect(find.byType(YoutubePlayer), findsNothing);
    expect(find.byType(AndroidYoutubePlayer), findsNothing);
    expect(find.text('Autoriser YouTube pour cette vidéo'), findsOneWidget);
  });
  testWidgets('two nominations by one player cannot fill two dropdowns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
      tester,
      const CeremonyDetailScreen(id: 'award'),
      ceremony: event(status: 'open', duplicatePlayer: true),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 1 · Action 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 1 · Autre action').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('choice-0-n1')), findsOneWidget);
    expect(find.byKey(const ValueKey('choice-1-null')), findsOneWidget);
    final second = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).at(1),
    );
    // Disabled items remain legible in the menu, but cannot be selected.
    expect(second, isNotNull);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Valider mon vote'),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets(
    'admin reopening requires confirmation and posts the correct action',
    (tester) async {
      final server = RecordingServer();
      await mount(
        tester,
        const CeremonyDetailScreen(id: 'award'),
        server: server,
        admin: true,
      );
      expect(find.text('Modifier'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);
      await tester.tap(find.text('Rouvrir le vote'));
      await tester.pumpAndSettle();
      expect(server.path, isNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
      await tester.pumpAndSettle();
      expect(server.path, '/ceremonies/award/reopen');
    },
  );
  testWidgets('editing is prefilled and reset must be explicitly confirmed', (
    tester,
  ) async {
    final server = RecordingServer();
    await mount(
      tester,
      const Scaffold(body: Text('Retour')),
      server: server,
      admin: true,
    );
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute(builder: (_) => CeremonyForm(ceremony: event())),
        );
    await tester.pumpAndSettle();
    expect(find.text('Ballon d\'or 2026'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Enregistrer les modifications'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Enregistrer les modifications'));
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();
    expect(server.path, isNull);
    await tester.tap(find.text('Modifier et remettre à zéro'));
    await tester.pumpAndSettle();
    expect(server.path, '/ceremonies/award/update');
    expect(server.ballot?['resetVotes'], true);
    expect(server.ballot?['expectedRevision'], 0);
    expect(server.ballot?['nominees'], hasLength(6));
    expect(find.text('Retour'), findsOneWidget);
  });
  testWidgets(
    'zero-point decorated player is present and trophies stay distinct from badges',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: demoOverrides,
          child: ProviderScope(
            overrides: [
              ceremoniesProvider.overrideWith((ref) => Stream.value([event()])),
              rankingProvider.overrideWith((ref, scope) => Stream.value([])),
              allBadgesProvider.overrideWith(
                (ref) => Stream.value({
                  'camille': {
                    'buteur': DateTime(2026),
                    'buteurOr': DateTime(2026),
                  },
                }),
              ),
            ],
            child: const MaterialApp(home: RankingScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alex Martin'), findsOneWidget);
      expect(find.text('Camille Martin'), findsOneWidget);
      expect(find.text('0 pts'), findsNWidgets(2));
      expect(find.byTooltip('Trophée : Ballon d\'or 2026'), findsOneWidget);
      expect(find.byTooltip('Badge : Buteur · Or'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [390.0, 1440.0]) {
    testWidgets('ceremonies, form, trophies and tiered badges fit at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final screen in <Widget>[
        const CeremoniesScreen(),
        const CeremonyDetailScreen(id: 'award'),
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const TrophiesSection(uid: 'guest'),
                BadgesSection(
                  earnedBadges: const [],
                  earnedDates: {
                    'buteur': DateTime(2026),
                    'buteurArgent': DateTime(2026),
                    'buteurOr': DateTime(2026),
                  },
                ),
              ],
            ),
          ),
        ),
      ]) {
        await mount(tester, screen);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        ProviderScope(
          overrides: demoOverrides,
          child: ProviderScope(
            overrides: [isAdminProvider.overrideWithValue(true)],
            child: const MaterialApp(home: CeremonyForm()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
