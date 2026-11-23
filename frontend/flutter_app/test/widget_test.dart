import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/screens/puzzle_gameplay.dart';
import 'package:flutter_app/services/settings.dart';
import 'package:flutter_app/services/sound_service.dart';
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
      'program': List.filled(3, {'type': 'Right'}),
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
