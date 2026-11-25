import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/routes.dart';
import 'package:flutter_app/services/api_client.dart';
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

/// Types the parent password into the lock dialog.
Future<void> enterPassword(WidgetTester tester, String password) async {
  await tester.enterText(find.byKey(const Key('gate-password')), password);
  await tester.tap(find.byKey(const Key('gate-submit')));
  await tester.pumpAndSettle();
}

Future<void> openParentSettings(WidgetTester tester) async {
  final tile = find.byKey(const Key('parent-settings'));
  await tester.ensureVisible(tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
  await enterPassword(tester, 'secret123');
  expect(find.text('Your kids'), findsOneWidget);
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

    await tester.ensureVisible(find.text('Restore default settings'));
    await tester.tap(find.text('Restore default settings'));
    await tester.pumpAndSettle();
    expect(app.settings.value, const AppSettings());
  });

  testWidgets('a wrong password keeps the parent area locked', (tester) async {
    final app = await openSettings(tester);
    await tester.ensureVisible(find.byKey(const Key('parent-settings')));
    await tester.tap(find.byKey(const Key('parent-settings')));
    await tester.pumpAndSettle();

    await enterPassword(tester, 'let-me-in');
    expect(find.textContaining('isn’t right'), findsOneWidget);
    expect(app.auth.isParentUnlocked, isFalse);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Your kids'), findsNothing);
  });

  testWidgets('leaving parent settings locks them again', (tester) async {
    final app = await openSettings(tester);
    await openParentSettings(tester);
    expect(app.auth.isParentUnlocked, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(app.auth.isParentUnlocked, isFalse);

    // Coming back asks for the password again.
    await tester.tap(find.byKey(const Key('parent-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gate-password')), findsOneWidget);
  });

  testWidgets('parents can rename a child', (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend: backend);
    await openParentSettings(tester);

    await tester.tap(find.byKey(const Key('child-c2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-child-c2')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('child-name')), 'Ella');
    await tester.tap(find.byKey(const Key('save-child')));
    await tester.pumpAndSettle();

    final patch = backend.requests.singleWhere((r) => r.method == 'PATCH');
    expect(patch.url.path, '/api/children/c2');
    expect(patch.headers['Authorization'], 'Bearer $parentToken');
    expect(jsonDecode(patch.body), {'name': 'Ella', 'age': 4});
    expect(find.text('Ella'), findsOneWidget);
  });

  testWidgets('parents can add a child', (tester) async {
    final backend = FakeBackend();
    await openSettings(tester, backend: backend);
    await openParentSettings(tester);

    await tester.ensureVisible(find.byKey(const Key('parent-add-child')));
    await tester.tap(find.byKey(const Key('parent-add-child')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('child-name')), 'Zed');
    await tester.tap(find.byKey(const Key('child-age')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 years old').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-child')));
    await tester.pumpAndSettle();

    expect(backend.children.map((c) => c['name']), ['Tommy', 'Ava', 'Zed']);
    expect(find.text('Zed'), findsOneWidget);
  });

  testWidgets('parents can reset one child’s progress after confirming', (tester) async {
    final backend = FakeBackend(stars: {'seq1': 3, 'loop1': 2});
    backend.progress['c2'] = {'seq1': 1};
    await openSettings(tester, backend: backend);
    await openParentSettings(tester);

    await tester.tap(find.byKey(const Key('child-c1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('reset-all-c1')));
    await tester.tap(find.byKey(const Key('reset-all-c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-reset')));
    await tester.pumpAndSettle();

    expect(backend.stars, isEmpty);
    expect(backend.progress['c2'], {'seq1': 1}); // Ava's stars are untouched
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

  test('parent-only requests fail without unlocking, so kids can’t change the account', () async {
    final app = TestApp();
    final locked = isA<ApiException>().having((e) => e.needsParent, 'needsParent', isTrue);
    await expectLater(app.auth.changePassword('secret123', 'hacked1'), throwsA(locked));
    await expectLater(app.auth.addChild('Sneaky', 5), throwsA(locked));
    await expectLater(app.puzzles.resetProgress(childId: 'c1'), throwsA(locked));
    expect(app.backend.requests, isEmpty); // nothing even reached the server
  });
}
