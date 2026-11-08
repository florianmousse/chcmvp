import 'package:chc_mvp/core/models/match_model.dart';
import 'package:chc_mvp/core/services/messaging_service.dart';
import 'package:chc_mvp/features/ceremonies/youtube_video.dart';
import 'package:chc_mvp/features/ceremonies/youtube_embed_request.dart';
import 'package:chc_mvp/features/home/presentation/home_screen.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/features/matches/presentation/matches_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'support/dashboard_fixture.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));
  test(
    'legacy match defaults to championship; all types survive serialization',
    () {
      Map<String, dynamic> jsonOf(MatchModel match) => {
        ...match.toJson(),
        'pointsScale': match.pointsScale.toJson(),
      };
      final json = jsonOf(demoMatches.first)..remove('matchType');
      expect(MatchModel.fromJson(json).matchType, MatchType.championship);
      for (final type in MatchType.values) {
        final match = demoMatches.first.copyWith(matchType: type);
        expect(MatchModel.fromJson(jsonOf(match)).matchType, type);
        expect(
          match.countsForStats,
          type != MatchType.friendly && type != MatchType.tournament,
        );
      }
      expect(
        demoMatches.first.copyWith(id: 'test:example').countsForStats,
        false,
      );
    },
  );
  test('match details round trip and competition labels', () {
    final match = demoMatches.first.copyWith(
      matchDay: 1,
      matchNumber: 2,
      city: 'Rennes',
      eventName: 'Coupe du club',
    );
    final decoded = MatchModel.fromJson({
      ...match.toJson(),
      'pointsScale': match.pointsScale.toJson(),
    });
    expect(decoded.city, 'Rennes');
    expect(decoded.competitionLabel, 'J1 - M2');
    expect(decoded.copyWith(matchNumber: 1).competitionLabel, 'J1 - M1');
    for (final type in [MatchType.friendly, MatchType.tournament]) {
      expect(
        decoded.copyWith(matchType: type).competitionLabel,
        'Coupe du club',
      );
      expect(
        decoded.copyWith(matchType: type, eventName: '  ').competitionLabel,
        type.label,
      );
      expect(decoded.copyWith(matchType: type).countsForStats, false);
    }
  });
  test(
    'YouTube identifies the native application independently from its embed host',
    () {
      const params = ClubYoutubeParams();
      expect(params.origin, 'https://www.youtube.com');
      expect(params.toMap()['origin'], clubYoutubeAppOrigin);
      expect(params.toMap()['widget_referrer'], clubYoutubeAppOrigin);
    },
  );
  test('push targets preserve both match and ceremony routes', () {
    expect(notificationTarget({'ceremonyId': 'award'}), 'ceremony:award');
    expect(notificationTarget({'matchId': 'test:match'}), 'test:match');
    expect(notificationTarget({}), null);
  });
  test(
    'Android uses the official HTTPS embed and explicit application Referer',
    () {
      final uri = youtubeEmbedUri('IPQMJo0x8G8');
      expect(uri.host, 'www.youtube.com');
      expect(uri.scheme, 'https');
      expect(uri.path, '/embed/IPQMJo0x8G8');
      expect(uri.queryParameters['autoplay'], '0');
      expect(youtubeEmbedHeaders['Referer'], '$clubYoutubeAppOrigin/');
      expect(() => youtubeEmbedUri('../invalid'), throwsArgumentError);
    },
  );
  for (final type in [MatchType.friendly, MatchType.tournament]) {
    testWidgets(
      '${type.name} offers a ballot and displays its podium and turnout, but stays absent from home',
      (tester) async {
        var match = demoMatches.first.copyWith(
          id: 'friendly',
          opponent: 'Amical Rennes',
          matchType: type,
          eventName: "Rencontre du club",
          city: "Rennes",
          status: MatchStatus.votingOpen,
        );
        Future<void> mount(Widget page) async {
          await tester.pumpWidget(
            ProviderScope(
              key: UniqueKey(),
              overrides: [
                ...demoOverrides,
                matchesListProvider.overrideWith(
                  (ref, team) => Stream.value([match]),
                ),
              ],
              child: MaterialApp(home: page),
            ),
          );
          await tester.pumpAndSettle();
        }

        await mount(const MatchesScreen());
        expect(find.text('Rencontre du club'), findsOneWidget);
        expect(find.text('Ville : Rennes'), findsOneWidget);
        expect(find.text('CHC vs Amical Rennes'), findsOneWidget);
        expect(find.text('Voter pour les 3 meilleurs joueurs'), findsOneWidget);
        match = match.copyWith(status: MatchStatus.votingClosed);
        await mount(const MatchesScreen());
        expect(find.textContaining('🥇 Camille'), findsOneWidget);
        expect(find.textContaining('(3/4)'), findsOneWidget);
        await mount(const HomeScreen());
        expect(find.textContaining('Amical Rennes'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
