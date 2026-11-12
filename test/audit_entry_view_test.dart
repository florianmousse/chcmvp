import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:chc_mvp/features/admin/presentation/audit_entry_view.dart';
import 'package:chc_mvp/core/models/match_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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
    for (final font in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(
            File(
              '${sdk.path}/bin/cache/artifacts/material_fonts/${font.value}',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    }
  });
  final fixture = <String, dynamic>{
    'action': 'update',
    'target': 'matches/synthetic-match',
    'actorName': 'Camille Exemple',
    'source': 'transaction',
    'status': 'success',
    'at': Timestamp.fromDate(DateTime(2026, 11, 10, 10, 30)),
    'before': {
      'status': 'upcoming',
      'scoreHome': null,
      'password': 'NEVER_DISPLAY',
    },
    'after': {
      'status': 'voting_open',
      'scoreHome': 3,
      'password': 'NEVER_DISPLAY',
    },
  };
  test('only business fields are displayed and action names are readable', () {
    final changes = auditChanges(fixture);
    expect(changes.map((c) => c.label), ['État du vote', 'Score domicile']);
    expect(changes.first.after, 'Vote ouvert');
    expect(auditActionLabel(fixture), "Modification d'un match");
  });
  test(
    'civil match dates stay on the selected day and legacy timestamps still decode',
    () {
      final legacy = <String, dynamic>{
        'id': 'fixture',
        'date': '2026-07-10T15:00:00Z',
        'time': '15:00',
        'opponent': 'Fixture',
        'isHome': true,
        'team': 'Démo',
      };
      final match = MatchModel.fromJson({...legacy, 'civilDate': '2026-07-11'});
      expect(
        [match.date.year, match.date.month, match.date.day],
        [2026, 7, 11],
      );
      expect(
        MatchModel.fromJson(legacy).date,
        DateTime.parse('2026-07-10T15:00:00Z'),
      );
    },
  );
  testWidgets(
    'journal expands from the keyboard and explains unknown outcomes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditEntryCard(data: {...fixture, 'status': 'pending'}),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Ce statut ne confirme pas sa réussite.'),
        findsOneWidget,
      );
      expect(find.text('Après : Vote ouvert'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 1100.0]) {
    for (final dark in [false, true]) {
      testWidgets('journal readable at $width dark=$dark with enlarged text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: RepaintBoundary(
                key: boundary,
                child: Scaffold(
                  body: ListView(children: [AuditEntryCard(data: fixture)]),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text("Modification d'un match"));
        await tester.pumpAndSettle();
        expect(find.text('Après : Vote ouvert'), findsOneWidget);
        expect(find.textContaining('NEVER_DISPLAY'), findsNothing);
        expect(tester.takeException(), isNull);
        {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await render.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('build/audit-previews').create(recursive: true);
            await File(
              'build/audit-previews/journal-${width.toInt()}-${dark ? 'sombre' : 'clair'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
}
