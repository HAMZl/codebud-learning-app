import 'package:flutter/foundation.dart';

import '../models/family.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// A child as entered on the sign-up form.
class ChildDraft {
  const ChildDraft({required this.name, required this.age});
  final String name;
  final int age;

  Map<String, dynamic> toJson() => {'name': name, 'age': age};
}

class SignUpData {
  final String parentName;
  final String email;
  final String username;
  final String password;
  final List<ChildDraft> children;

  const SignUpData({
    required this.parentName,
    required this.email,
    required this.username,
    required this.password,
    required this.children,
  });

  Map<String, dynamic> toJson() => {
        'parent_name': parentName,
        'email': email,
        'username': username,
        'password': password,
        'children': children.map((c) => c.toJson()).toList(),
      };
}

/// The signed-in family, which child is playing, and whether a grown-up has unlocked parent settings.
///
/// The account token lasts for days and is stored on the device. Parent-only
/// actions (changing the account, the password, the children, or resetting
/// progress) need a separate parent token, which the parent gets by typing the
/// password again. It lives only in memory and expires after a few minutes, so a
/// child who picks up the tablet later can't change anything.
class AuthService extends ChangeNotifier {
  AuthService(this._api, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ApiClient _api;
  final DateTime Function() _clock;
  TokenStorage get _tokens => _api.tokens;

  Family? _family;
  String? _activeChildId;
  String? _parentToken;
  DateTime? _parentExpiry;

  Family? get family => _family;
  List<Child> get children => _family?.children ?? const [];

  /// The child who is playing right now, picked on the "Who's playing?" screen.
  Child? get activeChild {
    for (final c in children) {
      if (c.id == _activeChildId) return c;
    }
    return null;
  }

  bool get isParentUnlocked => _parentToken != null && _clock().isBefore(_parentExpiry!);

  Future<bool> isLoggedIn() async => (await _tokens.readToken()) != null;

  /// Logs in and stores the session. Returns the welcome message.
  Future<String> login(String username, String password) async {
    final data = await _api.post('/login', {'username': username, 'password': password});
    await _tokens.save(token: data['token'] as String);
    _family = Family.fromJson({...data, 'username': username});
    _activeChildId = null;
    lockParent(notify: false);
    notifyListeners();
    return (data['message'] as String?) ?? 'Welcome!';
  }

  /// Creates an account. Returns the success message.
  Future<String> signUp(SignUpData form) async {
    final data = await _api.post('/signup', form.toJson());
    return (data['message'] as String?) ?? 'Account created!';
  }

  Future<void> logout() async {
    await _tokens.clear();
    _family = null;
    _activeChildId = null;
    lockParent(notify: false);
    notifyListeners();
  }

  /// Loads the family from the server, e.g. when the app opens with a saved session.
  Future<Family> loadFamily() async {
    final family = Family.fromJson(await _api.get('/api/me', auth: true));
    _family = family;
    notifyListeners();
    return family;
  }

  /// Starts a test or screenshot already signed in, without a network round trip.
  @visibleForTesting
  void setSessionForTesting(Family family, {String? playing}) {
    _family = family;
    _activeChildId = playing;
    notifyListeners();
  }

  void selectChild(Child child) {
    _activeChildId = child.id;
    notifyListeners();
  }

  void clearActiveChild() {
    _activeChildId = null;
    notifyListeners();
  }

  void _replaceChild(Child child) {
    final family = _family;
    if (family == null) return;
    _family = family.copyWith(children: [for (final c in family.children) c.id == child.id ? child : c]);
    notifyListeners();
  }

  /// Saves a child's robot. Kids can do this themselves, so no parent token is needed.
  Future<Child> updateRobot(Child child, RobotLook robot) async {
    final data = await _api.patch('/api/children/${child.id}', {'robot': robot.toJson()}, auth: true);
    final updated = Child.fromJson(data['child'] as Map<String, dynamic>);
    _replaceChild(updated);
    return updated;
  }

  // --- parent area ------------------------------------------------------------------

  /// Checks the account password and unlocks parent settings for a while.
  /// Throws an [ApiException] if the password is wrong.
  Future<void> unlockParent(String password) async {
    final data = await _api.post('/api/parent/unlock', {'password': password}, auth: true);
    final seconds = data['expires_in'] as int? ?? 900;
    _parentToken = data['parent_token'] as String;
    // Lock a little early, so a request never goes out with a token that is about to expire.
    _parentExpiry = _clock().add(Duration(seconds: seconds > 60 ? seconds - 30 : seconds));
    notifyListeners();
  }

  void lockParent({bool notify = true}) {
    final wasUnlocked = _parentToken != null;
    _parentToken = null;
    _parentExpiry = null;
    if (notify && wasUnlocked) notifyListeners();
  }

  /// Runs a parent-only request. If the parent token is missing or has expired,
  /// the area locks and an [ApiException] with [ApiException.needsParent] is thrown.
  Future<T> asParent<T>(Future<T> Function(String token) request) async {
    const locked = ApiException(
      'Parent settings have locked. Please enter your password again.',
      statusCode: 403,
      body: {'error': 'parent_required'},
    );
    final token = isParentUnlocked ? _parentToken! : null;
    if (token == null) {
      lockParent();
      throw locked;
    }
    try {
      return await request(token);
    } on ApiException catch (e) {
      // An expired parent token is a 401, but the account session itself is still fine.
      if (e.isUnauthorized || e.needsParent) {
        lockParent();
        throw locked;
      }
      rethrow;
    }
  }

  Future<Family> updateParent({String? parentName, String? email}) => asParent((token) async {
        final data = await _api.patch(
          '/api/me',
          {
            if (parentName != null) 'parent_name': parentName,
            if (email != null) 'email': email,
          },
          bearer: token,
        );
        _family = Family.fromJson(data);
        notifyListeners();
        return _family!;
      });

  Future<Child> addChild(String name, int age) => asParent((token) async {
        final data = await _api.post('/api/children', {'name': name, 'age': age}, bearer: token);
        final child = Child.fromJson(data['child'] as Map<String, dynamic>);
        final family = _family;
        if (family != null) _family = family.copyWith(children: [...family.children, child]);
        notifyListeners();
        return child;
      });

  Future<Child> updateChild(Child child, {String? name, int? age}) => asParent((token) async {
        final data = await _api.patch(
          '/api/children/${child.id}',
          {if (name != null) 'name': name, if (age != null) 'age': age},
          bearer: token,
        );
        final updated = Child.fromJson(data['child'] as Map<String, dynamic>);
        _replaceChild(updated);
        return updated;
      });

  Future<void> removeChild(Child child) => asParent((token) async {
        await _api.delete('/api/children/${child.id}', bearer: token);
        final family = _family;
        if (family != null) {
          _family = family.copyWith(children: family.children.where((c) => c.id != child.id).toList());
        }
        if (_activeChildId == child.id) _activeChildId = null;
        notifyListeners();
      });

  Future<void> changePassword(String current, String next) => asParent(
        (token) => _api.post('/api/me/password', {'current_password': current, 'new_password': next}, bearer: token),
      );
}
