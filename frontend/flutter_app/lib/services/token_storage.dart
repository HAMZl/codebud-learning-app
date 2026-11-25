import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the session is kept. It is an interface so tests can use [MemoryTokenStorage].
///
/// Only the account token is stored. Which child is playing is chosen again each
/// time the app opens, and the parent unlock is kept in memory only.
abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> save({required String token});
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'jwt_token';
  static const _legacyChildNameKey = 'child_name';

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> save({required String token}) => _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _legacyChildNameKey);
  }
}

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage({this.token});

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> save({required String token}) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}
