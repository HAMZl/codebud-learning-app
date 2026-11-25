import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/screens/puzzle_gameplay.dart';
import 'package:flutter_app/services/settings.dart';
import 'package:flutter_app/services/sound_service.dart';
import 'package:flutter_app/models/command.dart';
import 'package:flutter_app/widgets/success_popup_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_backend.dart';

const fast = Duration(milliseconds: 10);

Future<void> tapPlay(WidgetTester tester) async {
  final play = find.byKey(const Key('play'));
  await tester.ensureVisible(play);
  await tester.pumpAndSettle();
  await tester.tap(play);
  await tester.pumpAndSettle();
}

Future<void> tapBlock(WidgetTester tester, String type, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.bySemanticsLabel(type).first);
    await tester.pump();
  }
}

void main() {
  testWidgets('solving a puzzle saves the program, plays sounds and shows the popup', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const MaterialApp(home: PuzzleScreen(puzzleId: 'seq1', stepDuration: fast))));
    await tester.pumpAndSettle();
    expect(find.text('First Steps'), findsOneWidget);

    await tapBlock(tester, 'Right', times: 3);
    await tapPlay(tester);

    expect(find.byType(SuccessPopup), findsOneWidget);
    expect(app.sounds.played, [
      ...List.filled(3, Sfx.tap), // adding blocks
      ...List.filled(3, Sfx.step), // one per move
      Sfx.success,
      ...List.filled(3, Sfx.star), // one per earned star
    ]);
    final save = app.backend.requests.singleWhere((r) => r.method == 'POST');
    expect(save.headers['Authorization'], 'Bearer token-123');
    expect(jsonDecode(save.body), {
      'puzzle_id': 'seq1',
      'child_id': 'c1', // the child who is playing
      'program': List.filled(3, {'type': 'Right'}),
    });
  });

  testWidgets('the board shows the playing child\'s robot', (tester) async {
    final app = TestApp(playing: 'c2'); // Ava has a pink bunny
    await tester.pumpWidget(app.wrap(const MaterialApp(home: PuzzleScreen(puzzleId: 'seq1', stepDuration: fast))));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cruelty_free), findsOneWidget);
  });

  group('levels where the rocks move', () {
    Future<TestApp> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = TestApp();
      await tester.pumpWidget(app.wrap(const MaterialApp(home: PuzzleScreen(puzzleId: 'cond2', stepDuration: fast))));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('show every board', (tester) async {
      await open(tester);
      expect(find.textContaining('The rocks move!'), findsOneWidget);
      expect(find.byKey(const Key('board-thumb-0')), findsOneWidget);
      expect(find.byKey(const Key('board-thumb-1')), findsOneWidget);
    });

    testWidgets('plain moves that only solve the first board get a hint about If blocks', (tester) async {
      final app = await open(tester);
      // Solves board 1 (Right, Down, Right, Down, Right, Right) but hits a rock on board 2.
      for (final move in ['Right', 'Down', 'Right', 'Down', 'Right', 'Right']) {
        await tapBlock(tester, move);
      }
      await tapPlay(tester);

      expect(find.byType(SuccessPopup), findsNothing);
      expect(find.textContaining('Try an If block'), findsOneWidget);
      expect(app.backend.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('a program with an If block solves every board', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = TestApp();
      // Repeat 4: if there is a rock to the right, go down. Then go right.
      final program = [
        CommandItem(type: BlockType.loop, repeat: 4, body: [
          CommandItem(type: BlockType.ifBlock, body: [CommandItem(type: BlockType.down)]),
          CommandItem(type: BlockType.right),
        ]),
      ];
      await tester.pumpWidget(app.wrap(MaterialApp(
        home: PuzzleScreen(puzzleId: 'cond2', stepDuration: fast, initialProgram: program),
      )));
      await tester.pumpAndSettle();
      await tapPlay(tester);

      expect(find.byType(SuccessPopup), findsOneWidget);
      final save = jsonDecode(app.backend.requests.singleWhere((r) => r.method == 'POST').body);
      expect(save['program'][0]['body'][0], {
        'type': 'If',
        'condition': 'obstacle_right',
        'body': [
          {'type': 'Down'}
        ]
      });
      // A chime after each board that passes, then the win.
      expect(app.sounds.played.where((s) => s == Sfx.star).length, greaterThanOrEqualTo(1));
    });
  });

  testWidgets('hitting a wall shows a hint and plays the bump sound', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const MaterialApp(home: PuzzleScreen(puzzleId: 'seq1', stepDuration: fast))));
    await tester.pumpAndSettle();

    await tapBlock(tester, 'Left');
    await tapPlay(tester);

    expect(find.byType(SuccessPopup), findsNothing);
    expect(find.textContaining('wall'), findsOneWidget);
    expect(app.sounds.played.last, Sfx.bump);
  });

  testWidgets('with hints turned off a miss shows no dialog', (tester) async {
    final app = TestApp(settings: const AppSettings(showHints: false));
    await tester.pumpWidget(app.wrap(const MaterialApp(home: PuzzleScreen(puzzleId: 'seq1', stepDuration: fast))));
    await tester.pumpAndSettle();

    await tapBlock(tester, 'Left');
    await tapPlay(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(app.sounds.played.last, Sfx.bump);
  });

  testWidgets('the mute button turns sound effects off and saves the setting', (tester) async {
    final app = TestApp();
    await tester.pumpWidget(app.wrap(const MaterialApp(home: PuzzleScreen(puzzleId: 'seq1', stepDuration: fast))));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mute')));
    await tester.pump();
    expect(app.settings.value.soundEnabled, isFalse);
    expect(app.settingsStore.values['soundEnabled'], false);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);

    await tapBlock(tester, 'Right');
    expect(app.sounds.played, isEmpty);
  });
}
