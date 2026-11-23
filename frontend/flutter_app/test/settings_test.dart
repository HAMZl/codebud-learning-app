import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/routes.dart';
import 'package:flutter_app/services/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_backend.dart';

/// Opens Settings from the home screen.
Future<TestApp> openSettings(WidgetTester tester, {FakeBackend? backend}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final app = TestApp(backend: backend);
  await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.home)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open-settings')));
  await tester.pumpAndSettle();
  return app;
}

/// Answers the parental gate. The question is random, so read it off the screen.
Future<void> passGate(WidgetTester tester, {bool correctly = true}) async {
  final question =
      tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').firstWhere((t) => t.contains('×'));
  final m = RegExp(r'(\d+) × (\d+)').firstMatch(question)!;
  final answer = int.parse(m[1]!) * int.parse(m[2]!);
  await tester.enterText(find.byKey(const Key('gate-answer')), '${correctly ? answer : answer + 1}');
  await tester.tap(find.byKey(const Key('gate-submit')));
  await tester.pumpAndSettle();
}

Future<void> openParentSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('parent-settings')));
  await tester.pumpAndSettle();
  await passGate(tester);
  expect(find.text('Parent settings'), findsWidgets);
}

void main() {
  group('AppSettings', () {
    test('round-trips through a map and ignores bad values', () {
      const s = AppSettings(soundEnabled: false, volume: 0.3, robotSpeed: RobotSpeed.fast, showHints: false);
      expect(AppSettings.fromMap(s.toMap()), s);
      expect(AppSettings.fromMap({'volume': 7, 'robotSpeed': 'warp'}), const AppSettings(volume: 1.0));
    });

    test('controller loads saved values and saves changes', () async {
      final store = MemorySettingsStore({'robotSpeed': 'slow'});
      final c = SettingsController(store);
      await c.load();
      expect(c.value.robotSpeed, RobotSpeed.slow);
      await c.update((s) => s.copyWith(volume: 0.5));
      expect(store.values['volume'], 0.5);
    });
  });

  testWidgets('kids can change sound, speed and hints', (tester) async {
    final app = await openSettings(tester);

    await tester.tap(find.byKey(const Key('sound-switch')));
    await tester.pumpAndSettle();
    expect(app.settings.value.soundEnabled, isFalse);

    await tester.tap(find.text('Fast'));
    await tester.pumpAndSettle();
    expect(app.settings.value.robotSpeed, RobotSpeed.fast);

    await tester.tap(find.byKey(const Key('hints-switch')));
    await tester.pumpAndSettle();
    expect(app.settings.value.showHints, isFalse);

    expect(app.settingsStore.values, containsPair('robotSpeed', 'fast'));

    await tester.tap(find.text('Restore default settings'));
    await tester.pumpAndSettle();
    expect(app.settings.value, const AppSettings());
  });

  testWidgets('a wrong answer keeps the parent area locked', (tester) async {
    await openSettings(tester);
    await tester.tap(find.byKey(const Key('parent-settings')));
    await tester.pumpAndSettle();

    await passGate(tester, correctly: false);
    expect(find.text('Not quite, try again'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Parent settings'), findsOneWidget); // only the tile, not a page title
  });

  testWidgets('parents can edit the child profile', (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend: backend);
    await openParentSettings(tester);
    expect(find.text('Tommy'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-profile')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('child-name')), 'Ella');
    await tester.enterText(find.byKey(const Key('child-age')), '5');
    await tester.tap(find.byKey(const Key('save-profile')));
    await tester.pumpAndSettle();

    final patch = backend.requests.singleWhere((r) => r.method == 'PATCH');
    expect(jsonDecode(patch.body), containsPair('child_name', 'Ella'));
    expect(find.text('Ella'), findsOneWidget);
    expect(find.text('Age 5'), findsOneWidget);
  });

  testWidgets('parents can reset progress after confirming', (tester) async {
    final backend = FakeBackend(stars: {'seq1': 3, 'loop1': 2});
    await openSettings(tester, backend: backend);
    await openParentSettings(tester);

    await tester.ensureVisible(find.byKey(const Key('reset-all')));
    await tester.tap(find.byKey(const Key('reset-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-reset')));
    await tester.pumpAndSettle();

    expect(backend.stars, isEmpty);
    expect(backend.requests.where((r) => r.method == 'DELETE'), hasLength(1));
  });

  testWidgets('log out returns to the landing page', (tester) async {
    final app = await openSettings(tester);
    await openParentSettings(tester);

    await tester.ensureVisible(find.byKey(const Key('logout')));
    await tester.tap(find.byKey(const Key('logout')));
    await tester.pumpAndSettle();

    expect(app.tokens.token, isNull);
    expect(find.byKey(const Key('hero-signup')), findsOneWidget);
  });
}
