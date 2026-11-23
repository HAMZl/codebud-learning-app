import 'api_client.dart';
import 'token_storage.dart';

class SignUpData {
  final String parentName;
  final String email;
  final String childName;
  final String childAge;
  final String username;
  final String password;

  const SignUpData({
    required this.parentName,
    required this.email,
    required this.childName,
    required this.childAge,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'parent_name': parentName,
        'email': email,
        'child_name': childName,
        'child_age': int.tryParse(childAge) ?? childAge,
        'username': username,
        'password': password,
      };
}

class AuthService {
  AuthService(this._api);

  final ApiClient _api;
  TokenStorage get _tokens => _api.tokens;

  Future<bool> isLoggedIn() async => (await _tokens.readToken()) != null;

  Future<String?> childName() => _tokens.readChildName();

  /// Logs in and stores the session. Returns the welcome message.
  Future<String> login(String username, String password) async {
    final data = await _api.post('/login', {'username': username, 'password': password});
    await _tokens.save(token: data['token'] as String, childName: data['child_name'] as String?);
    return (data['message'] as String?) ?? 'Welcome!';
  }

  /// Creates an account. Returns the success message.
  Future<String> signUp(SignUpData form) async {
    final data = await _api.post('/signup', form.toJson());
    return (data['message'] as String?) ?? 'Account created! Please log in.';
  }

  Future<void> logout() => _tokens.clear();

  Future<Profile> fetchProfile() async => Profile.fromJson(await _api.get('/api/me', auth: true));

  /// Saves profile changes. Only non-null fields are sent.
  Future<Profile> updateProfile({String? childName, int? childAge, String? parentName, String? email}) async {
    final data = await _api.patch(
      '/api/me',
      {
        if (childName != null) 'child_name': childName,
        if (childAge != null) 'child_age': childAge,
        if (parentName != null) 'parent_name': parentName,
        if (email != null) 'email': email,
      },
      auth: true,
    );
    final profile = Profile.fromJson(data);
    // Keep the greeting on the home screen in sync.
    final token = await _tokens.readToken();
    if (token != null) await _tokens.save(token: token, childName: profile.childName);
    return profile;
  }

  Future<void> changePassword(String current, String next) =>
      _api.post('/api/me/password', {'current_password': current, 'new_password': next}, auth: true);
}

class Profile {
  final String username;
  final String childName;
  final int? childAge;
  final String? parentName;
  final String? email;

  const Profile({required this.username, required this.childName, this.childAge, this.parentName, this.email});

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        username: j['username'] as String? ?? '',
        childName: j['child_name'] as String? ?? '',
        childAge: j['child_age'] as int?,
        parentName: j['parent_name'] as String?,
        email: j['email'] as String?,
      );
}
