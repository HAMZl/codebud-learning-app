import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/models/family.dart';
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

const parentToken = 'parent-token';

/// An in-memory stand-in for the Flask API that behaves like the real endpoints.
class FakeBackend {
  /// [stars] is the first child's progress.
  FakeBackend({Map<String, int>? stars}) {
    progress['c1'] = {...?stars};
  }

  final puzzles = loadPuzzles();
  final requests = <http.Request>[];
  String password = 'secret123';
  String parentName = 'Jane';
  String email = 'jane@example.com';
  List<Map<String, dynamic>> children = [
    {
      'id': 'c1',
      'name': 'Tommy',
      'age': 6,
      'robot': {'character': 'robot', 'color': 'teal', 'nickname': 'Sparky'},
    },
    {
      'id': 'c2',
      'name': 'Ava',
      'age': 4,
      'robot': {'character': 'bunny', 'color': 'pink', 'nickname': ''},
    },
  ];

  /// Best stars per child id, then per puzzle id.
  final Map<String, Map<String, int>> progress = {'c2': {}};

  Map<String, int> get stars => progress['c1']!;

  Family get family => Family.fromJson(_profile());

  Map<String, dynamic> _profile() =>
      {'username': 'tommy', 'parent_name': parentName, 'email': email, 'children': children};

  Map<String, dynamic> _public(Map<String, dynamic> p) => Map.of(p)..remove('solution');

  String _child(http.Request req, [Map<String, dynamic> body = const {}]) =>
      (body['child_id'] ?? req.url.queryParameters['child_id'] ?? 'c1') as String;

  late final client = MockClient((req) async {
    requests.add(req);
    final path = req.url.path;
    final body = req.body.isEmpty ? <String, dynamic>{} : jsonDecode(req.body) as Map<String, dynamic>;
    final isParent = req.headers['Authorization'] == 'Bearer $parentToken';
    final needParent =
        _json({'message': 'A grown-up needs to unlock parent settings first.', 'error': 'parent_required'}, 403);

    if (path == '/login') {
      if (body['username'] != 'tommy' || body['password'] != password) {
        return _json({'message': 'Incorrect username or password.'}, 401);
      }
      return _json({'token': 'token-123', 'message': 'Welcome back, $parentName!', ..._profile()});
    }
    if (path == '/signup') {
      children = [
        for (final (i, c) in (body['children'] as List).indexed)
          {
            'id': 'n$i',
            'name': c['name'],
            'age': c['age'],
            'robot': {'character': 'robot', 'color': RobotColor.all[i].id, 'nickname': ''},
          },
      ];
      parentName = body['parent_name'] as String;
      password = body['password'] as String;
      return _json({'success': true, 'message': 'Account created successfully!'});
    }
    if (path == '/api/parent/unlock') {
      if (body['password'] != password) {
        return _json({'message': 'That password is not right.', 'field': 'password'}, 403);
      }
      return _json({'parent_token': parentToken, 'expires_in': 1800});
    }
    if (path.startsWith('/api/puzzles/')) {
      final cat = path.split('/').last;
      final stars = progress[_child(req)] ?? const {};
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
      final stars = progress[_child(req)] ?? const {};
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
      progress.putIfAbsent(_child(req, body), () => {})[body['puzzle_id'] as String] = 3;
      return _json({'success': true, 'stars': 3, 'best_stars': 3}, 201);
    }
    if (path == '/api/progress' && req.method == 'DELETE') {
      if (!isParent) return needParent;
      final cat = req.url.queryParameters['category'];
      final stars = progress[_child(req)] ?? {};
      final before = stars.length;
      stars.removeWhere((id, _) => cat == null || puzzles.any((p) => p['id'] == id && p['category'] == cat));
      return _json({'success': true, 'removed': before - stars.length});
    }
    if (path == '/api/me' && req.method == 'GET') return _json(_profile());
    if (path == '/api/me' && req.method == 'PATCH') {
      if (!isParent) return needParent;
      parentName = body['parent_name'] as String? ?? parentName;
      email = body['email'] as String? ?? email;
      return _json({'success': true, ..._profile()});
    }
    if (path == '/api/me/password') {
      if (!isParent) return needParent;
      if (body['current_password'] != password) return _json({'message': 'Current password is incorrect.'}, 403);
      password = body['new_password'] as String;
      return _json({'success': true});
    }
    if (path == '/api/children' && req.method == 'POST') {
      if (!isParent) return needParent;
      final child = {
        'id': 'c${children.length + 1}',
        'name': body['name'],
        'age': body['age'],
        'robot': {'character': 'robot', 'color': 'sky', 'nickname': ''},
      };
      children = [...children, child];
      return _json({'success': true, 'child': child}, 201);
    }
    if (path.startsWith('/api/children/')) {
      final id = path.split('/').last;
      final i = children.indexWhere((c) => c['id'] == id);
      if (i < 0) return _json({'message': 'That child profile was not found.'}, 404);
      if (req.method == 'DELETE') {
        if (!isParent) return needParent;
        children = [...children]..removeAt(i);
        progress.remove(id);
        return _json({'success': true});
      }
      if ((body.containsKey('name') || body.containsKey('age')) && !isParent) return needParent;
      final child = {
        ...children[i],
        if (body.containsKey('name')) 'name': body['name'],
        if (body.containsKey('age')) 'age': body['age'],
        if (body['robot'] != null)
          'robot': {...children[i]['robot'] as Map<String, dynamic>, ...body['robot'] as Map<String, dynamic>},
      };
      children = [...children]..[i] = child;
      return _json({'success': true, 'child': child});
    }
    return _json({'message': 'not found'}, 404);
  });

  static http.Response _json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
}

/// Everything a widget test needs, wired together.
///
/// By default the family is logged in and the first child (Tommy, id `c1`) is playing.
class TestApp {
  TestApp({FakeBackend? backend, bool loggedIn = true, String? playing = 'c1', AppSettings? settings})
      : backend = backend ?? FakeBackend(),
        tokens = MemoryTokenStorage(token: loggedIn ? 'token-123' : null),
        settingsStore = MemorySettingsStore(settings?.toMap()) {
    this.settings = SettingsController(settingsStore)..value = settings ?? const AppSettings();
    sounds = RecordingSoundService(this.settings);
    final api = ApiClient(httpClient: this.backend.client, tokens: tokens, baseUrl: 'http://test');
    auth = AuthService(api);
    puzzles = PuzzleService(api, auth);
    if (loggedIn) auth.setSessionForTesting(this.backend.family, playing: playing);
  }

  final FakeBackend backend;
  final MemoryTokenStorage tokens;
  final MemorySettingsStore settingsStore;
  late final SettingsController settings;
  late final RecordingSoundService sounds;
  late final AuthService auth;
  late final PuzzleService puzzles;

  Widget wrap(Widget child) => AppScope(auth: auth, puzzles: puzzles, settings: settings, sounds: sounds, child: child);
}
