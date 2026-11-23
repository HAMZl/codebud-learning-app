import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the session is kept. It is an interface so tests can use [MemoryTokenStorage].
abstract class TokenStorage {
  Future<String?> readToken();
  Future<String?> readChildName();
  Future<void> save({required String token, String? childName});
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'jwt_token';
  static const _childNameKey = 'child_name';

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<String?> readChildName() => _storage.read(key: _childNameKey);

  @override
  Future<void> save({required String token, String? childName}) async {
    await _storage.write(key: _tokenKey, value: token);
    if (childName != null) await _storage.write(key: _childNameKey, value: childName);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _childNameKey);
  }
}

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage({this.token, this.childName});

  String? token;
  String? childName;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<String?> readChildName() async => childName;

  @override
  Future<void> save({required String token, String? childName}) async {
    this.token = token;
    this.childName = childName ?? this.childName;
  }

  @override
  Future<void> clear() async {
    token = null;
    childName = null;
  }
}
