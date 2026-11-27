import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserAccount {
  const UserAccount({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

/// Stores local demo accounts in the platform's secure key-value storage.
class AuthStore {
  AuthStore._();

  static const _storageKey = 'emosense.registered_users.v1';
  static const _sessionKey = 'emosense.active_user.v1';
  static const _storage = FlutterSecureStorage();
  static final Map<String, UserAccount> _users = {};
  static UserAccount? _currentUser;
  static bool _initialized = false;

  static bool get hasUsers => _users.isNotEmpty;
  static UserAccount? get currentUser => _currentUser;

  static Future<void> initialize() async {
    if (_initialized) return;

    final savedUsers = await _storage.read(key: _storageKey);
    if (savedUsers != null && savedUsers.isNotEmpty) {
      final decoded = jsonDecode(savedUsers);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is! Map<String, dynamic>) continue;
          final name = item['name'];
          final email = item['email'];
          final password = item['password'];
          if (name is! String || email is! String || password is! String) {
            continue;
          }
          _users[email.toLowerCase()] = UserAccount(
            name: name,
            email: email.toLowerCase(),
            password: password,
          );
        }
      }
    }
    final activeEmail = await _storage.read(key: _sessionKey);
    if (activeEmail != null) {
      _currentUser = _users[activeEmail.toLowerCase()];
    }
    _initialized = true;
  }

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await initialize();
    final key = email.trim().toLowerCase();
    if (_users.containsKey(key)) return false;
    final account = UserAccount(
      name: name.trim(),
      email: key,
      password: password,
    );
    _users[key] = account;
    try {
      await _persistUsers();
      await setCurrentUser(account);
    } catch (_) {
      _users.remove(key);
      rethrow;
    }
    return true;
  }

  static UserAccount? signIn({
    required String email,
    required String password,
  }) {
    final user = _users[email.trim().toLowerCase()];
    return user != null && user.password == password ? user : null;
  }

  static Future<void> setCurrentUser(UserAccount user) async {
    await initialize();
    _currentUser = user;
    await _storage.write(key: _sessionKey, value: user.email.toLowerCase());
  }

  static Future<void> signOut() async {
    _currentUser = null;
    await _storage.delete(key: _sessionKey);
  }

  static Future<void> _persistUsers() async {
    final users = _users.values
        .map((user) => {
              'name': user.name,
              'email': user.email,
              'password': user.password,
            })
        .toList();
    await _storage.write(key: _storageKey, value: jsonEncode(users));
  }
}
