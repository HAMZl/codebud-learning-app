// Renders real screenshots of the app into assets/screenshots/ for the landing page and README.
//
//     flutter test test_screenshots --update-goldens
//
// This lives outside test/ so that a plain `flutter test` (and CI) skip it. Pixels differ
// slightly between operating systems, so these images aren't compared in CI. They are
// regenerated on purpose when the UI changes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/models/command.dart';
import 'package:flutter_app/routes.dart';
import 'package:flutter_app/screens/puzzle_gameplay.dart';
import 'package:flutter_app/screens/settings_page.dart';
import 'package:flutter_app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/fake_backend.dart';

const phone = Size(390, 844);
const pixelRatio = 2.0;

/// Loads Roboto and the Material icon font from the Flutter SDK, so text and
/// icons render properly instead of as the test font's boxes.
Future<void> loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path; // .../flutter
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) throw StateError('Fonts not found in ${dir.path}');

  Future<ByteData> read(String name) async => ByteData.sublistView(await File('${dir.path}/$name').readAsBytes());

  final roboto = FontLoader('Roboto');
  for (final w in ['regular', 'medium', 'bold', 'black']) {
    roboto.addFont(read('roboto-$w.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(read('materialicons-regular.otf'))).load();
}

Future<void> setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
}

/// Pumps until network fakes, images and animations have settled.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> snap(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('../assets/screenshots/$name.png'));

/// A screenshot test. flutter_test draws shadows as solid outlines by default, so real shadows
/// are on for the whole test. Flutter requires the flag restored before the test ends.
void shot(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}

MaterialApp screen(Widget home) => MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.light(), home: home);

final progress = {'seq1': 3, 'seq2': 3, 'seq3': 2, 'seq4': 3, 'loop1': 3, 'loop2': 2};

void main() {
  setUpAll(loadFonts);

  shot('home', (tester) async {
    await setSize(tester, phone);
    final app = TestApp(backend: FakeBackend(stars: progress));
    await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.home)));
    await settle(tester);
    await snap(tester, 'home');
  });

  shot('levels', (tester) async {
    await setSize(tester, phone);
    final app = TestApp(backend: FakeBackend(stars: progress));
    await tester.pumpWidget(app.wrap(const CodeBudApp(initialRoute: Routes.home)));
    await settle(tester);
    await tester.tap(find.text('Sequencing'));
    await settle(tester);
    await snap(tester, 'levels');
  });

  shot('puzzle', (tester) async {
    await setSize(tester, phone);
    final app = TestApp();
    final program = [
      CommandItem(type: BlockType.loop, repeat: 4, body: [
        CommandItem(type: BlockType.right),
        CommandItem(type: BlockType.up),
      ]),
    ];
    await tester.pumpWidget(app.wrap(screen(PuzzleScreen(puzzleId: 'loop6', initialProgram: program))));
    await settle(tester);
    await snap(tester, 'puzzle');
  });

  shot('success', (tester) async {
    await setSize(tester, phone);
    final app = TestApp();
    final program = [
      CommandItem(type: BlockType.loop, repeat: 4, body: [CommandItem(type: BlockType.right)])
    ];
    await tester.pumpWidget(app.wrap(screen(PuzzleScreen(
      puzzleId: 'loop1',
      initialProgram: program,
      stepDuration: const Duration(milliseconds: 10),
    ))));
    await settle(tester);
    await tester.tap(find.byKey(const Key('play')));
    await settle(tester);
    await snap(tester, 'success');
  });

  shot('settings', (tester) async {
    await setSize(tester, phone);
    final app = TestApp();
    await tester.pumpWidget(app.wrap(screen(const SettingsPage())));
    await settle(tester);
    await snap(tester, 'settings');
  });

  shot('landing (desktop, for the README)', (tester) async {
    await setSize(tester, const Size(1280, 800));
    final app = TestApp(loggedIn: false);
    await tester.pumpWidget(app.wrap(const CodeBudApp()));
    await settle(tester);
    await snap(tester, 'landing');
  });
}
