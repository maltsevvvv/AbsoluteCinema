// ============================================================
//  lib/services/auth_service.dart
// ============================================================
//
//  Логика авторизации и определения роли.
//  Работает поверх StorageService — не хранит данные напрямую.
//
//  Роль определяется автоматически по логину:
//    login == 'cashier'  →  UserRole.cashier
//    любой другой логин  →  UserRole.viewer
//
// ============================================================

import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  // Синглтон
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final StorageService _storage = StorageService();

  // Текущий пользователь — хранится в памяти после входа
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;
  bool get isCashier => _currentUser?.role == UserRole.cashier;
  bool get isViewer => _currentUser?.role == UserRole.viewer;

  // ── Восстановление сессии при запуске приложения ──────────
  // Вызывается в main() после StorageService.init()
  Future<void> restoreSession() async {
    final saved = await _storage.loadCurrentUser();
    if (saved != null) {
      _currentUser = saved;
    }
  }

  // ── Вход ──────────────────────────────────────────────────
  // Возвращает null при успехе, сообщение об ошибке при провале
  Future<String?> login(String login, String password) async {
    if (login.trim().isEmpty || password.trim().isEmpty) {
      return 'Заполните все поля';
    }

    final user = await _storage.loginUser(login, password);
    if (user == null) {
      return 'Неверный логин или пароль';
    }

    _currentUser = user;
    return null; // успех
  }

  // ── Регистрация (только для зрителей) ─────────────────────
  // Кассир — предустановленный аккаунт, регистрация не нужна.
  // Возвращает null при успехе, сообщение об ошибке при провале.
  Future<String?> register(String login, String password) async {
    if (login.trim().toLowerCase() == 'cashier') {
      return 'Этот логин зарезервирован';
    }

    final error = await _storage.registerUser(login, password);
    if (error != null) return error;

    // Сразу входим после регистрации
    _currentUser = await _storage.loginUser(login, password);
    return null;
  }

  // ── Выход ─────────────────────────────────────────────────
  Future<void> logout() async {
    _currentUser = null;
    await _storage.clearCurrentUser();
  }

  // ── Вспомогательные геттеры ───────────────────────────────
  String get userId => _currentUser?.id ?? '';
  String get displayName => _currentUser?.login ?? '';
  String get roleLabel => _currentUser?.roleLabel ?? '';
}
