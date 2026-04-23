// ============================================================
//  lib/services/storage_service.dart
// ============================================================
//
//  ИЗМЕНЕНИЯ:
//    1. _seedIfFirstRun() добавляет viewer_001 (пункт 8 методички)
//    2. addBooking() помечает конкретные места isBooked = true
//    3. updateBookingStatus() при rejected освобождает места
//    4. Session сериализуется вместе с seats
//
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/movie.dart';
import '../models/session.dart';
import '../models/booking.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedIfFirstRun();
  }

  // ── ПЕРВЫЙ ЗАПУСК ─────────────────────────────────────────

  Future<void> _seedIfFirstRun() async {
    if ((_prefs.getStringList('users') ?? []).isNotEmpty) return;

    // Кассир (предустановленный аккаунт)
    await _saveUser(AppUser(
      id:       'cashier_001',
      login:    'cashier',
      password: 'cashier123',
      role:     UserRole.cashier,
    ));

    // Зритель (предустановленный — закрывает пункт 8 методички)
    await _saveUser(AppUser(
      id:       'viewer_001',
      login:    'viewer',
      password: 'viewer123',
      role:     UserRole.viewer,
    ));

    // Пустой список сеансов — кассир добавит или они создадутся
    // после загрузки фильмов через seedSessionsFromCache()
    if ((_prefs.getStringList('sessions') ?? []).isEmpty) {
      await _prefs.setStringList('sessions', []);
    }
  }

  // Вызывается из ApiService после первой загрузки фильмов
  Future<void> seedSessionsFromCache() async {
    final existing = _prefs.getStringList('sessions') ?? [];
    if (existing.isNotEmpty) return;

    final movies = await loadMoviesCache();
    if (movies.isEmpty) return;

    final ids = movies.take(5).map((m) => m.id).toList();
    final now = DateTime.now();
    final sessions = <Session>[];
    int n = 1;

    for (int i = 0; i < ids.length; i++) {
      sessions.add(Session(
        id:         's$n',
        movieId:    ids[i],
        dateTime:   DateTime(now.year, now.month, now.day + i + 1, 10, 0),
        hall:       'Зал 1',
        price:      350,
        totalSeats: 80,
      ));
      n++;
      sessions.add(Session(
        id:         's$n',
        movieId:    ids[i],
        dateTime:   DateTime(now.year, now.month, now.day + i + 1, 18, 30),
        hall:       'VIP',
        price:      700,
        totalSeats: 30,
      ));
      n++;
    }

    await saveSessions(sessions);
  }

  // ── ПОЛЬЗОВАТЕЛИ ──────────────────────────────────────────

  Future<List<AppUser>> loadUsers() async {
    final raw = _prefs.getStringList('users') ?? [];
    return raw.map((s) => AppUser.fromJson(jsonDecode(s))).toList();
  }

  Future<void> _saveUser(AppUser user) async {
    final users = await loadUsers();
    if (!users.any((u) => u.id == user.id)) users.add(user);
    await _prefs.setStringList(
        'users', users.map((u) => jsonEncode(u.toJson())).toList());
  }

  Future<String?> registerUser(String login, String password) async {
    if (login.trim().isEmpty || password.trim().isEmpty) {
      return 'Заполните все поля';
    }
    if (password.trim().length < 3) {
      return 'Пароль должен быть не менее 3 символов';
    }
    final users = await loadUsers();
    if (users.any(
        (u) => u.login.toLowerCase() == login.trim().toLowerCase())) {
      return 'Логин уже занят';
    }
    await _saveUser(AppUser(
      id:       'u_${DateTime.now().millisecondsSinceEpoch}',
      login:    login.trim(),
      password: password.trim(),
      role:     AppUser.detectRole(login.trim()),
    ));
    return null;
  }

  Future<AppUser?> loginUser(String login, String password) async {
    final users = await loadUsers();
    try {
      final user = users.firstWhere(
        (u) =>
            u.login.toLowerCase() == login.trim().toLowerCase() &&
            u.password == password.trim(),
      );
      await saveCurrentUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  // ── ТЕКУЩИЙ ПОЛЬЗОВАТЕЛЬ ──────────────────────────────────

  Future<void> saveCurrentUser(AppUser user) async =>
      _prefs.setString('current_user', jsonEncode(user.toJson()));

  Future<AppUser?> loadCurrentUser() async {
    final raw = _prefs.getString('current_user');
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw));
  }

  Future<void> clearCurrentUser() async =>
      _prefs.remove('current_user');

  // ── ФИЛЬМЫ (кэш TMDB) ─────────────────────────────────────

  Future<void> saveMoviesCache(List<Movie> movies) async {
    await _prefs.setStringList(
        'movies_cache',
        movies.map((m) => jsonEncode(m.toJson())).toList());
  }

  Future<List<Movie>> loadMoviesCache() async {
    final raw = _prefs.getStringList('movies_cache') ?? [];
    return raw.map((s) => Movie.fromJson(jsonDecode(s))).toList();
  }

  // ── ИЗБРАННОЕ ─────────────────────────────────────────────

  String _favKey(String userId) => 'favorites_$userId';

  Future<void> saveFavorites(String userId, List<int> ids) async =>
      _prefs.setStringList(
          _favKey(userId), ids.map((id) => id.toString()).toList());

  Future<List<int>> loadFavorites(String userId) async {
    final raw = _prefs.getStringList(_favKey(userId)) ?? [];
    return raw.map((s) => int.parse(s)).toList();
  }

  Future<void> addFavorite(String userId, int movieId) async {
    final favs = await loadFavorites(userId);
    if (!favs.contains(movieId)) {
      favs.add(movieId);
      await saveFavorites(userId, favs);
    }
  }

  Future<void> removeFavorite(String userId, int movieId) async {
    final favs = await loadFavorites(userId);
    favs.remove(movieId);
    await saveFavorites(userId, favs);
  }

  // ── СЕАНСЫ ────────────────────────────────────────────────

  Future<void> saveSessions(List<Session> sessions) async {
    await _prefs.setStringList(
        'sessions',
        sessions.map((s) => jsonEncode(s.toJson())).toList());
  }

  Future<List<Session>> loadSessions() async {
    final raw = _prefs.getStringList('sessions') ?? [];
    return raw
        .map((s) => Session.fromJson(jsonDecode(s)))
        .toList();
  }

  Future<void> updateSession(Session updated) async {
    final sessions = await loadSessions();
    final idx = sessions.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      sessions[idx] = updated;
      await saveSessions(sessions);
    }
  }

  Future<void> addSession(Session session) async {
    final sessions = await loadSessions();
    sessions.add(session);
    await saveSessions(sessions);
  }

  // ── БРОНИРОВАНИЯ ──────────────────────────────────────────

  Future<void> saveBookings(List<Booking> bookings) async {
    await _prefs.setStringList(
        'bookings',
        bookings.map((b) => jsonEncode(b.toJson())).toList());
  }

  Future<List<Booking>> loadBookings() async {
    final raw = _prefs.getStringList('bookings') ?? [];
    return raw
        .map((s) => Booking.fromJson(jsonDecode(s)))
        .toList();
  }

  // Создать бронь + пометить места занятыми в сеансе
  Future<String?> addBooking(Booking booking) async {
    final bookings = await loadBookings();

    // Проверка: зритель уже бронировал этот сеанс
    final alreadyBooked = bookings.any((b) =>
        b.userId == booking.userId &&
        b.sessionId == booking.sessionId &&
        b.status != BookingStatus.rejected);
    if (alreadyBooked) return 'Вы уже забронировали этот сеанс';

    // Обновляем схему мест в сеансе
    final sessions = await loadSessions();
    final sIdx =
        sessions.indexWhere((s) => s.id == booking.sessionId);

    if (sIdx != -1) {
      final session = sessions[sIdx];

      // Проверяем, что все выбранные места ещё свободны
      for (final seatId in booking.seatIds) {
        final seat = session.seats.firstWhere(
          (s) => s.id == seatId,
          orElse: () => throw Exception(
              'Место $seatId не найдено в сеансе'),
        );
        if (seat.isBooked) {
          return 'Место $seatId уже занято. Пожалуйста, выберите другое.';
        }
      }

      // Помечаем места занятыми
      for (final seatId in booking.seatIds) {
        final idx =
            session.seats.indexWhere((s) => s.id == seatId);
        if (idx != -1) {
          session.seats[idx] =
              session.seats[idx].copyWith(isBooked: true);
        }
      }

      // Обновляем счётчик занятых мест
      session.bookedSeats =
          (session.bookedSeats + booking.seatIds.length)
              .clamp(0, session.totalSeats);

      await saveSessions(sessions);
    }

    bookings.add(booking);
    await saveBookings(bookings);
    return null;
  }

  // Изменить статус брони; при rejected — освобождаем места
  Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    final bookings = await loadBookings();
    final idx = bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) return;

    final old = bookings[idx];
    bookings[idx] = old.copyWith(status: status);
    await saveBookings(bookings);

    // Освобождаем места если заявка отклонена
    if (status == BookingStatus.rejected) {
      final sessions = await loadSessions();
      final sIdx =
          sessions.indexWhere((s) => s.id == old.sessionId);
      if (sIdx != -1) {
        final session = sessions[sIdx];
        for (final seatId in old.seatIds) {
          final mIdx =
              session.seats.indexWhere((s) => s.id == seatId);
          if (mIdx != -1) {
            session.seats[mIdx] =
                session.seats[mIdx].copyWith(isBooked: false);
          }
        }
        session.bookedSeats = (session.bookedSeats -
                old.seatIds.length)
            .clamp(0, session.totalSeats);
        await saveSessions(sessions);
      }
    }
  }

  Future<List<Booking>> loadUserBookings(String userId) async {
    final all = await loadBookings();
    return all.where((b) => b.userId == userId).toList();
  }

  Future<List<Booking>> loadPendingBookings() async {
    final all = await loadBookings();
    return all
        .where((b) => b.status == BookingStatus.pending)
        .toList();
  }
}
