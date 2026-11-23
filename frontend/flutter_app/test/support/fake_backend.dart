import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/services/api_client.dart';
import 'package:flutter_app/services/app_scope.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/puzzle_service.dart';
import 'package:flutter_app/services/settings.dart';
import 'package:flutter_app/services/sound_service.dart';
import 'package:flutter_app/services/token_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The real level data, read from the repository.
List<Map<String, dynamic>> loadPuzzles() {
  // Tests run from the package root, frontend/flutter_app.
  final file = File('../../database/puzzles.json');
  return (jsonDecode(file.readAsStringSync()) as List).cast<Map<String, dynamic>>();
}

/// An in-memory stand-in for the Flask API that behaves like the real endpoints.
class FakeBackend {
  FakeBackend({Map<String, int>? stars}) : stars = {...?stars};

  final puzzles = loadPuzzles();
  final Map<String, int> stars;
  final requests = <http.Request>[];
  Map<String, dynamic> profile = {
    'username': 'tommy',
    'child_name': 'Tommy',
    'child_age': 6,
    'parent_name': 'Jane',
    'email': 'jane@example.com',
  };
  String password = 'secret123';

  Map<String, dynamic> _public(Map<String, dynamic> p) => Map.of(p)..remove('solution');

  late final client = MockClient((req) async {
    requests.add(req);
    final path = req.url.path;
    final body = req.body.isEmpty ? <String, dynamic>{} : jsonDecode(req.body) as Map<String, dynamic>;

    if (path.startsWith('/api/puzzles/')) {
      final cat = path.split('/').last;
      final list = puzzles.where((p) => p['category'] == cat).map((p) {
        return {..._public(p), 'best_stars': stars[p['id']] ?? 0};
      }).toList();
      return _json({'puzzles': list});
    }
    if (path.startsWith('/api/puzzle/')) {
      final id = path.split('/').last;
      final i = puzzles.indexWhere((p) => p['id'] == id);
      if (i < 0) return _json({'message': 'Puzzle not found'}, 404);
      final p = puzzles[i];
      final next = i + 1 < puzzles.length && puzzles[i + 1]['category'] == p['category'] ? puzzles[i + 1] : null;
      return _json({
        ..._public(p),
        'next': next == null ? null : {'id': next['id'], 'title': next['title']}
      });
    }
    if (path == '/api/progress' && req.method == 'GET') {
      final cats = <String, Map<String, int>>{};
      for (final p in puzzles) {
        final c =
            cats.putIfAbsent(p['category'] as String, () => {'total': 0, 'completed': 0, 'stars': 0, 'max_stars': 0});
        c['total'] = c['total']! + 1;
        c['max_stars'] = c['max_stars']! + 3;
        final s = stars[p['id']] ?? 0;
        if (s > 0) c['completed'] = c['completed']! + 1;
        c['stars'] = c['stars']! + s;
      }
      return _json({'categories': cats});
    }
    if (path == '/api/progress' && req.method == 'POST') {
      stars[body['puzzle_id'] as String] = 3;
      return _json({'success': true, 'stars': 3, 'best_stars': 3}, 201);
    }
    if (path == '/api/progress' && req.method == 'DELETE') {
      final cat = req.url.queryParameters['category'];
      final before = stars.length;
      stars.removeWhere((id, _) => cat == null || puzzles.any((p) => p['id'] == id && p['category'] == cat));
      return _json({'success': true, 'removed': before - stars.length});
    }
    if (path == '/api/me' && req.method == 'GET') return _json(profile);
    if (path == '/api/me' && req.method == 'PATCH') {
      profile = {...profile, ...body};
      return _json({'success': true, ...profile});
    }
    if (path == '/api/me/password') {
      if (body['current_password'] != password) return _json({'message': 'Current password is incorrect.'}, 403);
      password = body['new_password'] as String;
      return _json({'success': true});
    }
    return _json({'message': 'not found'}, 404);
  });

  static http.Response _json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
}

/// Everything a widget test needs, wired together.
class TestApp {
  TestApp({FakeBackend? backend, bool loggedIn = true, AppSettings? settings})
      : backend = backend ?? FakeBackend(),
        tokens = MemoryTokenStorage(token: loggedIn ? 'token-123' : null, childName: loggedIn ? 'Tommy' : null),
        settingsStore = MemorySettingsStore(settings?.toMap()) {
    this.settings = SettingsController(settingsStore)..value = settings ?? const AppSettings();
    sounds = RecordingSoundService(this.settings);
  }

  final FakeBackend backend;
  final MemoryTokenStorage tokens;
  final MemorySettingsStore settingsStore;
  late final SettingsController settings;
  late final RecordingSoundService sounds;

  Widget wrap(Widget child) {
    final api = ApiClient(httpClient: backend.client, tokens: tokens, baseUrl: 'http://test');
    return AppScope(
      auth: AuthService(api),
      puzzles: PuzzleService(api),
      settings: settings,
      sounds: sounds,
      child: child,
    );
  }
}
