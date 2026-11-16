import 'dart:async';

import 'package:chc_mvp/core/services/app_update_service.dart';
import 'package:chc_mvp/core/services/web_app_version.dart';
import 'package:chc_mvp/core/widgets/app_update_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestUpdates extends AppUpdateService {
  AvailableAppUpdate? update = const AvailableAppUpdate(id: '18', isWeb: false);
  bool failCheck = false;
  bool failOpen = false;
  int opens = 0;
  Completer<AvailableAppUpdate?>? pending;

  @override
  Future<AvailableAppUpdate?> check() async {
    if (failCheck) throw StateError('offline');
    return pending?.future ?? update;
  }

  @override
  Future<void> openUpdate(AvailableAppUpdate update) async {
    opens++;
    if (failOpen) throw StateError('store unavailable');
  }
}

Widget app(TestUpdates service, {double textScale = 1}) => ProviderScope(
  overrides: [appUpdateServiceProvider.overrideWithValue(service)],
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const AppUpdatePrompt(child: Scaffold(body: Text('Accueil'))),
  ),
);

void main() {
  test('web compares numeric versions and rejects invalid responses', () {
    Object version(String value, String build) => {
      'version': value,
      'build_number': build,
    };
    expect(newerWebVersion('1.5.5+17', version('1.5.5', '17')), isNull);
    expect(newerWebVersion('1.5.5+17', version('1.5.5', '18')), '1.5.5+18');
    expect(newerWebVersion('1.9.0+17', version('1.10.0', '18')), '1.10.0+18');
    expect(newerWebVersion('1.5.5+17', version('1.5.4', '16')), isNull);
    expect(() => newerWebVersion('1.5.5+17', '<html>'), throwsFormatException);
    expect(
      () => newerWebVersion('1.5.5+17', version('invalid', '18')),
      throwsFormatException,
    );
  });

  testWidgets('later dismisses without opening store or repeating on resume', (
    tester,
  ) async {
    final service = TestUpdates();
    await tester.pumpWidget(app(service));
    await tester.pumpAndSettle();
    expect(find.text('Mise à jour disponible'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Mise à jour disponible'), findsNothing);
    expect(service.opens, 0);
  });

  testWidgets('update opens store and reports launch errors with retry', (
    tester,
  ) async {
    final service = TestUpdates()..failOpen = true;
    await tester.pumpWidget(app(service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mettre à jour'));
    await tester.pumpAndSettle();
    expect(
      find.text("Impossible d'ouvrir la mise à jour. Réessaie plus tard."),
      findsOneWidget,
    );
    service.failOpen = false;
    await tester.tap(find.text('Mettre à jour'));
    await tester.pumpAndSettle();
    expect(service.opens, 2);
    expect(find.byType(AlertDialog), findsNothing);
  });

  for (final offline in [false, true]) {
    testWidgets('no popup when current or offline: $offline', (tester) async {
      final service = TestUpdates()
        ..update = null
        ..failCheck = offline;
      await tester.pumpWidget(app(service));
      await tester.pumpAndSettle();
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completion after disposal does not open dialog', (tester) async {
    final pending = Completer<AvailableAppUpdate?>();
    final service = TestUpdates()..pending = pending;
    await tester.pumpWidget(app(service));
    await tester.pumpWidget(const SizedBox());
    pending.complete(service.update);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'web prompt at $width with enlarged text and keyboard dismissal',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = TestUpdates()
          ..update = const AvailableAppUpdate(id: '1.5.6+18', isWeb: true);
        await tester.pumpWidget(app(service, textScale: 2));
        await tester.pumpAndSettle();
        expect(find.text('Recharger'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  }
}
