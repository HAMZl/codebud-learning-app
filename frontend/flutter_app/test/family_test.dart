import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_backend.dart';

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('a parent can sign up with two kids and lands on "Who’s playing?"', (tester) async {
    useTallScreen(tester);
    final app = TestApp(loggedIn: false);
    await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.signup)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('signup-parent-name')), 'Sam');
    await tester.enterText(find.byKey(const Key('signup-email')), 'sam@example.com');
    await tester.enterText(find.byKey(const Key('signup-kid-name-0')), 'Ava');
    await tester.tap(find.byKey(const Key('signup-kid-age-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 years old').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('signup-add-kid')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signup-kid-name-1')), 'Noah');
    await tester.tap(find.byKey(const Key('signup-kid-age-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8 years old').last);
    await tester.pumpAndSettle();

    // The fake backend only lets "tommy" log in.
    await tester.enterText(find.byKey(const Key('signup-username')), 'tommy');
    await tester.enterText(find.byKey(const Key('signup-password')), 'secret123');
    await tester.enterText(find.byKey(const Key('signup-confirm')), 'secret123');
    await tester.ensureVisible(find.byKey(const Key('signup-submit')));
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pumpAndSettle();

    final signup = jsonDecode(app.backend.requests.firstWhere((r) => r.url.path == '/signup').body);
    expect(signup['children'], [
      {'name': 'Ava', 'age': 5},
      {'name': 'Noah', 'age': 8},
    ]);
    expect(find.text('Who’s playing?'), findsOneWidget);
    expect(find.text('Ava'), findsOneWidget);
    expect(find.text('Noah'), findsOneWidget);
  });

  testWidgets('sign-up checks every child has a name and age', (tester) async {
    useTallScreen(tester);
    final app = TestApp(loggedIn: false);
    await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.signup)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('signup-submit')));
    await tester.tap(find.byKey(const Key('signup-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Pick an age'), findsOneWidget);
    expect(app.backend.requests, isEmpty);
  });

  testWidgets('logging in shows every child, and tapping one opens their home screen', (tester) async {
    useTallScreen(tester);
    final app = TestApp(loggedIn: false);
    await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.login)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login-username')), 'tommy');
    await tester.enterText(find.byKey(const Key('login-password')), 'secret123');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Who’s playing?'), findsOneWidget);
    expect(find.text('with Sparky'), findsOneWidget); // Tommy's robot has a nickname
    expect(find.text('with Bunny'), findsOneWidget); // Ava's hasn't, so it shows the character's name

    await tester.tap(find.byKey(const Key('profile-c2')));
    await tester.pumpAndSettle();
    expect(find.text('Hi, Ava!'), findsOneWidget);

    // Her progress is the one the home screen asks for.
    final progress = app.backend.requests.lastWhere((r) => r.url.path == '/api/progress');
    expect(progress.url.queryParameters['child_id'], 'c2');
  });

  testWidgets('switch player goes back to "Who’s playing?"', (tester) async {
    useTallScreen(tester);
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.home)));
    await tester.pumpAndSettle();
    expect(find.text('Hi, Tommy!'), findsOneWidget);

    await tester.tap(find.byKey(const Key('switch-player')));
    await tester.pumpAndSettle();
    expect(find.text('Who’s playing?'), findsOneWidget);
    expect(app.auth.activeChild, isNull);
  });

  testWidgets('the home screen sends you to "Who’s playing?" if nobody is picked', (tester) async {
    useTallScreen(tester);
    final app = TestApp(playing: null);
    await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.home)));
    await tester.pumpAndSettle();
    expect(find.text('Who’s playing?'), findsOneWidget);
  });

  testWidgets('adding a child from "Who’s playing?" needs the parent password', (tester) async {
    useTallScreen(tester);
    final app = TestApp(playing: null);
    await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.profiles)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-child')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gate-password')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Add a child'), findsOneWidget); // just the tile, no dialog
    expect(app.backend.children, hasLength(2));
  });

  testWidgets('kids can customise their robot', (tester) async {
    useTallScreen(tester);
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.home)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customise-robot')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('character-rocket')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('color-violet')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('nickname')), 'Zoomer');
    await tester.pump();
    expect(find.text('Zoomer'), findsWidgets); // the preview updates as they type

    await tester.ensureVisible(find.byKey(const Key('save-robot')));
    await tester.tap(find.byKey(const Key('save-robot')));
    await tester.pumpAndSettle();

    final patch = app.backend.requests.singleWhere((r) => r.method == 'PATCH');
    expect(patch.url.path, '/api/children/c1');
    expect(patch.headers['Authorization'], 'Bearer token-123'); // no parent token needed
    expect(jsonDecode(patch.body), {
      'robot': {'character': 'rocket', 'color': 'violet', 'nickname': 'Zoomer'}
    });
    expect(find.text('Zoomer is ready to explore.'), findsOneWidget);
    expect(app.auth.activeChild!.robot.character, 'rocket');
  });

  testWidgets('kids settings have no account options without the password', (tester) async {
    useTallScreen(tester);
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.settings)));
    await tester.pumpAndSettle();
    expect(find.text('Change password'), findsNothing);
    expect(find.text('Log out'), findsNothing);
    expect(find.byKey(const Key('my-robot')), findsOneWidget);
    expect(app.auth.isParentUnlocked, isFalse);
  });
}
