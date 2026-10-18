import 'dart:io';
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
import 'support/dashboard_fixture.dart';

void main() {
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
            expect(
              tester.getTopLeft(find.text('Mon classement général')).dx,
              lessThan(
                tester.getTopLeft(find.text('Ma participation aux votes')).dx,
              ),
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
        }
      });
    }
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
