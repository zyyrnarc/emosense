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

/// Simple in-memory account store for the current app session.
class AuthStore {
  AuthStore._();

  static final Map<String, UserAccount> _users = {};

  static bool register({
    required String name,
    required String email,
    required String password,
  }) {
    final key = email.trim().toLowerCase();
    if (_users.containsKey(key)) return false;
    _users[key] = UserAccount(
      name: name.trim(),
      email: key,
      password: password,
    );
    return true;
  }

  static UserAccount? signIn({
    required String email,
    required String password,
  }) {
    final user = _users[email.trim().toLowerCase()];
    return user != null && user.password == password ? user : null;
  }
}
