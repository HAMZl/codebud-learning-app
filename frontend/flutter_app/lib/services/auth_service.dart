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
}
