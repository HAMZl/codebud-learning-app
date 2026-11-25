import 'package:flutter/material.dart';
import 'package:flutter_app/data/demo_puzzles.dart';
import 'package:flutter_app/game/engine.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/models/puzzle.dart';
import 'package:flutter_app/widgets/command_block_widget.dart';
import 'package:flutter_app/widgets/showcase.dart';
import 'package:flutter_app/widgets/success_popup_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_backend.dart';

void main() {
  for (final (name, size) in const [('phone', Size(390, 844)), ('desktop', Size(1280, 900))]) {
    testWidgets('landing page renders on $name and links to sign up', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final app = TestApp(loggedIn: false);
      await tester.pumpWidget(app.wrap(const CodeBudApp()));
      await tester.pumpAndSettle();

      expect(find.text('Coding adventures for little learners'), findsOneWidget);
      expect(tester.takeException(), isNull); // no overflow errors

      // The "Drag blocks" picture must fit in its 96px slot, so it can't cover the text below it.
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('1. Drag blocks'), 300, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(BlockStrip)).height, lessThanOrEqualTo(96));
      final strip = tester.getRect(find.byType(BlockStrip));
      final title = tester.getRect(find.text('1. Drag blocks'));
      expect(strip.bottom, lessThanOrEqualTo(title.top));

      await tester.scrollUntilVisible(find.byKey(const Key('hero-signup')), -300, scrollable: scrollable);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('hero-signup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hero-signup')));
      await tester.pumpAndSettle();
      expect(find.text('Create a family account'), findsOneWidget);
    });
  }

  testWidgets('the footer credits HAMZl with a link to GitHub', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = TestApp(loggedIn: false);
    await tester.pumpWidget(app.wrap(const CodeBudApp()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('author-link')), 500,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('HAMZl'), findsOneWidget);
    expect(find.textContaining('Created by'), findsOneWidget);
  });

  testWidgets('the demo puzzle can be solved without an account', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = TestApp(loggedIn: false);
    await tester.pumpWidget(app.wrap(const CodeBudApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('hero-try')));
    await tester.pumpAndSettle();

    // Solve "Around the Rock" (Right, Down, Right, Right, Up, Right) by tapping palette blocks.
    for (final move in ['Right', 'Down', 'Right', 'Right', 'Up', 'Right']) {
      final block = find.byWidgetPredicate((w) => w is DraggableBlock && w.type == move);
      await tester.ensureVisible(block);
      await tester.tap(block);
      await tester.pump();
    }
    final play = find.byKey(const Key('play'));
    await tester.ensureVisible(play);
    await tester.tap(play);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(SuccessPopup), findsOneWidget);
    expect(app.backend.requests, isEmpty); // nothing was sent to the server
  });

  test('bundled demo puzzles match database/puzzles.json', () {
    final shipped = {for (final p in loadPuzzles()) p['id']: p};
    for (final demo in demoPuzzles) {
      final json = shipped[demo.puzzle.id]!;
      final real = Puzzle.fromJson(json);
      expect(demo.puzzle.gridSize, real.gridSize);
      expect(demo.puzzle.start, real.start);
      expect(demo.puzzle.goal, real.goal);
      expect(demo.puzzle.obstacles, unorderedEquals(real.obstacles));
      expect(demo.puzzle.par, real.par);
      expect(demo.puzzle.boards.length, real.boards.length);
      for (var i = 1; i < real.boards.length; i++) {
        expect(demo.puzzle.boards[i].start, real.boards[i].start);
        expect(demo.puzzle.boards[i].goal, real.boards[i].goal);
        expect(demo.puzzle.boards[i].obstacles, unorderedEquals(real.boards[i].obstacles));
      }
      expect(GameEngine.runPuzzle(demo.puzzle, demo.solution()).stars, 3);
      expect(demo.solution().map((b) => b.toJson()).toList(), json['solution']);
    }
  });
}
