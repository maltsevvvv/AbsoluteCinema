// ============================================================
//  lib/models/user.dart
// ============================================================

// Роль определяется автоматически по логину:
//   login == 'cashier'  →  UserRole.cashier
//   любой другой логин  →  UserRole.viewer
enum UserRole { viewer, cashier }

class AppUser {
  final String id;
  final String login;
  final String password; // plaintext — учебный проект
  final UserRole role;

  AppUser({
    required this.id,
    required this.login,
    required this.password,
    required this.role,
  });

  // Роль определяется по логину — без кнопки выбора роли
  static UserRole detectRole(String login) {
    return login.trim().toLowerCase() == 'cashier'
        ? UserRole.cashier
        : UserRole.viewer;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'login': login,
        'password': password,
        'role': role.index, // enum → int
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        login: j['login'],
        password: j['password'],
        role: UserRole.values[j['role']], // int → enum
      );

  String get roleLabel =>
      role == UserRole.cashier ? 'Кассир' : 'Зритель';
}
