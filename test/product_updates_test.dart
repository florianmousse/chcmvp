import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:chc_mvp/core/theme/app_theme.dart';
import 'package:chc_mvp/features/home/presentation/home_screen.dart';
import 'package:chc_mvp/features/home/presentation/badges_section.dart';
import 'package:chc_mvp/features/home/domain/badge_model.dart';
import 'package:chc_mvp/features/matches/presentation/matches_screen.dart';
import 'package:chc_mvp/features/profile/presentation/profile_screen.dart';
import 'package:chc_mvp/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:chc_mvp/features/badges/presentation/badges_providers.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/auth/presentation/login_screen.dart';
import 'package:chc_mvp/features/matches/presentation/matches_providers.dart';
import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:chc_mvp/core/theme/theme_provider.dart';
import 'support/dashboard_fixture.dart';

void main() {
  testWidgets(
    'profile removes revoked badges and celebrates server additions',
    (tester) async {
      final badges = StreamController<Map<String, DateTime>>();
      addTearDown(badges.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => Stream.value(demoMember),
            ),
            themeModeProvider.overrideWith(() => DemoTheme()),
            userBadgesProvider.overrideWith((ref, uid) => badges.stream),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      badges.add({'fairPlay': DateTime(2026, 9, 1)});
      await tester.pumpAndSettle();
      expect(find.text('1/12'), findsOneWidget);
      badges.add({});
      await tester.pumpAndSettle();
      expect(find.text('0/12'), findsOneWidget);
      expect(find.text('Nouveau badge débloqué !'), findsNothing);
      badges.add({'buteur': DateTime(2026, 10, 19)});
      await tester.pumpAndSettle();
      expect(find.text('1/12'), findsOneWidget);
      expect(find.text('Nouveau badge débloqué !'), findsOneWidget);
      await tester.tap(find.text('Super ! 🙌'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
    final config = File('.dart_tool/package_config.json');
    final packages =
        (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
    final flutter = packages.firstWhere((p) => p['name'] == 'flutter') as Map;
    final sdk = Directory.fromUri(
      config.absolute.uri.resolve(flutter['rootUri'] as String),
    ).parent.parent;
    final font = File(
      '${sdk.path}/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    );
    await (FontLoader('Roboto')..addFont(
          font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        ))
        .load();
  });
  for (final width in [390.0, 900.0, 1100.0, 1440.0]) {
    for (final page in {
      'home': const HomeScreen(),
      'login': const LoginScreen(),
      'matches': const MatchesScreen(),
      'profile': const ProfileScreen(),
      'admin': const AdminDashboardScreen(),
    }.entries) {
      testWidgets('${page.key} à $width sans débordement', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final capture = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: demoOverrides,
            child: MaterialApp(
              theme: AppTheme.light,
              home: RepaintBoundary(
                key: capture,
                child: Row(
                  children: [
                    if (width >= 840)
                      SizedBox(width: width >= 1200 ? 200 : 100),
                    Expanded(child: page.value),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (page.key == 'home') {
          expect(
            find.byType(PageView),
            width >= 1100 ? findsNothing : findsWidgets,
          );
          if (width >= 1100) {
            final participation = find.text('Ma participation aux votes');
            final ranking = find.text('Mon classement général');
            expect(
              tester.getTopLeft(participation).dy,
              greaterThan(
                tester.getBottomLeft(find.text('Les records de la saison')).dy,
              ),
            );
            final participationCard = find
                .ancestor(of: participation, matching: find.byType(Card))
                .first;
            final rankingCard = find
                .ancestor(of: ranking, matching: find.byType(Card))
                .first;
            expect(
              tester.getRect(participationCard).left,
              tester.getRect(rankingCard).left,
            );
            expect(
              tester.getSize(participationCard).width,
              tester.getSize(rankingCard).width,
            );
          }
        }
        if (width == 1440 || width == 390) {
          await tester.runAsync(() async {
            final image =
                await (capture.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              'build/${page.key}-${width.toInt()}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
          if (page.key == 'home') {
            await tester.ensureVisible(find.text('Ma participation aux votes'));
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              final image =
                  await (capture.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                'build/home-bottom-${width.toInt()}.png',
              ).writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
      });
    }
  }
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'Les filtres restent fixes avec un seul match puis aucun résultat à $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: demoOverrides,
            child: ProviderScope(
              overrides: [
                matchesListProvider.overrideWith(
                  (ref, team) => Stream.value([demoMatches.last]),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.light,
                home: const Scaffold(
                  body: ResponsiveContent(child: MatchesScreen()),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final chips = find.byType(FilterChip);
        final initialPositions = [
          for (final element in chips.evaluate())
            tester.getRect(find.byWidget(element.widget)),
        ];
        expect(initialPositions, hasLength(4));
        await tester.tap(find.widgetWithText(FilterChip, 'Vote ouvert'));
        await tester.pumpAndSettle();
        expect(find.text('Aucun match avec ce filtre.'), findsOneWidget);
        expect([
          for (final element in chips.evaluate())
            tester.getRect(find.byWidget(element.widget)),
        ], initialPositions);
        await tester.tap(find.widgetWithText(FilterChip, 'Tous'));
        await tester.pumpAndSettle();
        expect([
          for (final element in chips.evaluate())
            tester.getRect(find.byWidget(element.widget)),
        ], initialPositions);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Badges obtenus en premier et plus récents en tête, y compris ceux persistés',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgesSection(
              earnedBadges: [Badge.allDefinitions[BadgeType.fairPlay]!],
              earnedDates: {
                'fairPlay': DateTime(2026, 9, 1),
                'buteur': DateTime(2026, 10, 1),
              },
            ),
          ),
        ),
      );
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .where((t) => Badge.allDefinitions.values.any((b) => b.label == t))
          .toList();
      expect(labels.take(2), ['Buteur', 'Fair-play']);
      expect(labels.length, Badge.allDefinitions.length);
    },
  );
}
