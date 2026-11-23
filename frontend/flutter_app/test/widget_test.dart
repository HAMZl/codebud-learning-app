import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/screens/puzzle_gameplay.dart';
import 'package:flutter_app/services/api_client.dart';
import 'package:flutter_app/services/app_scope.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/puzzle_service.dart';
import 'package:flutter_app/services/sound_service.dart';
import 'package:flutter_app/services/token_storage.dart';
import 'package:flutter_app/widgets/success_popup_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const seq1 = {
  'id': 'seq1',
  'category': 'sequence',
  'title': 'First Steps',
  'gridSize': 4,
  'start': [1, 0],
  'goal': [1, 3],
  'obstacles': [],
  'par': 3,
  'next': {'id': 'seq2', 'title': 'Going Down'},
};

AppScope scope({required Widget child, required MockClient http, TokenStorage? tokens, SoundService? sounds}) {
  final api = ApiClient(httpClient: http, tokens: tokens ?? MemoryTokenStorage(), baseUrl: 'http://test');
  return AppScope(
    auth: AuthService(api),
    puzzles: PuzzleService(api),
    sounds: sounds ?? RecordingSoundService(),
    child: child,
  );
}

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Future<void> tapPlay(WidgetTester tester) async {
  final play = find.byKey(const Key('play'));
  await tester.ensureVisible(play);
  await tester.pumpAndSettle();
  await tester.tap(play);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('launch page shows log in and sign up when logged out', (tester) async {
    await tester.pumpWidget(scope(http: MockClient((_) async => json({})), child: const CodeBudApp()));
    await tester.pumpAndSettle();

    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });

  testWidgets('solving a puzzle saves the program and shows the success popup', (tester) async {
    Map<String, dynamic>? savedBody;
    final client = MockClient((req) async {
      if (req.url.path == '/api/puzzle/seq1') return json(seq1);
      if (req.url.path == '/api/progress') {
        savedBody = jsonDecode(req.body) as Map<String, dynamic>;
        expect(req.headers['Authorization'], 'Bearer token-123');
        return json({'success': true, 'stars': 3, 'best_stars': 3}, 201);
      }
      return json({'message': 'not found'}, 404);
    });

    final sounds = RecordingSoundService();
    await tester.pumpWidget(scope(
      http: client,
      sounds: sounds,
      tokens: MemoryTokenStorage(token: 'token-123'),
      child: const MaterialApp(home: PuzzleScreen(puzzleId: 'seq1', stepDuration: Duration(milliseconds: 10))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('First Steps'), findsOneWidget);

    // Tap the Right block in the palette three times to add it to the program.
    final rightBlock = find.bySemanticsLabel('Right').first;
    for (var i = 0; i < 3; i++) {
      await tester.tap(rightBlock);
      await tester.pump();
    }

    await tapPlay(tester);

    expect(find.byType(SuccessPopup), findsOneWidget);
    expect(sounds.played, [
      ...List.filled(3, Sfx.tap), // adding blocks
      ...List.filled(3, Sfx.step), // one per move
      Sfx.success,
      ...List.filled(3, Sfx.star), // one per earned star
    ]);
    expect(savedBody, {
      'puzzle_id': 'seq1',
      'program': [
        {'type': 'Right'},
        {'type': 'Right'},
        {'type': 'Right'},
      ],
    });
  });

  testWidgets('hitting a wall shows a hint instead of the success popup', (tester) async {
    final client = MockClient((req) async => json(seq1));
    final sounds = RecordingSoundService();
    await tester.pumpWidget(scope(
      http: client,
      sounds: sounds,
      child: const MaterialApp(home: PuzzleScreen(puzzleId: 'seq1', stepDuration: Duration(milliseconds: 10))),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Left').first);
    await tester.pump();
    await tapPlay(tester);

    expect(find.byType(SuccessPopup), findsNothing);
    expect(find.textContaining('wall'), findsOneWidget);
    expect(sounds.played.last, Sfx.bump);
  });

  testWidgets('the mute button silences sound effects', (tester) async {
    final sounds = RecordingSoundService();
    await tester.pumpWidget(scope(
      http: MockClient((req) async => json(seq1)),
      sounds: sounds,
      child: const MaterialApp(home: PuzzleScreen(puzzleId: 'seq1', stepDuration: Duration(milliseconds: 10))),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mute')));
    await tester.pump();
    expect(sounds.muted.value, isTrue);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Right').first);
    await tester.pump();
    expect(sounds.played, isEmpty);
  });
}
