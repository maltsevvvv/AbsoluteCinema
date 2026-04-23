// ============================================================
//  lib/screens/my_tickets_screen.dart
// ============================================================
//
//  Экран «Мои билеты» для зрителя.
//  Показывает брони из SharedPreferences — это и есть
//  «использование сохранённых данных в UI» (пункт 9).
//
//  Зритель видит статусы: На рассмотрении / Одобрено / Отклонено.
//  Отклонённые брони — это «корзина» (пункт 7 методички).
//
// ============================================================

import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/movie.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../styles/app_styles.dart';
import '../widgets/booking_card.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService    _auth    = AuthService();
  final StorageService _storage = StorageService();

  // Вкладки: Активные / Отклонённые (корзина, пункт 7)
  late TabController _tabController;

  List<Booking>  _active   = []; // pending + approved
  List<Booking>  _rejected = []; // rejected
  List<Movie>    _movies   = [];
  List<Session>  _sessions = [];
  bool           _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final bookings = await _storage.loadUserBookings(_auth.userId);
    final movies   = await _storage.loadMoviesCache();
    final sessions = await _storage.loadSessions();

    setState(() {
      _active   = bookings.where((b) => b.status != BookingStatus.rejected).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _rejected = bookings.where((b) => b.status == BookingStatus.rejected).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _movies   = movies;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  // Найти фильм по movieId
  Movie? _movieById(int id) {
    try { return _movies.firstWhere((m) => m.id == id); }
    catch (_) { return null; }
  }

  // Найти сеанс по sessionId
  Session? _sessionById(String id) {
    try { return _sessions.firstWhere((s) => s.id == id); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои билеты'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppStyles.accent,
          labelColor: AppStyles.accent,
          unselectedLabelColor: AppStyles.textSecond,
          tabs: [
            Tab(text: 'Активные (${_active.length})'),
            Tab(text: 'Отклонённые (${_rejected.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppStyles.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_active,   emptyMsg: 'Нет активных броней'),
                _buildList(_rejected, emptyMsg: 'Нет отклонённых броней'),
              ],
            ),
    );
  }

  Widget _buildList(List<Booking> bookings, {required String emptyMsg}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_outlined,
                size: 56, color: AppStyles.textSecond),
            const SizedBox(height: 12),
            Text(emptyMsg, style: AppStyles.subtitle),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppStyles.accent,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppStyles.paddingS),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final movie   = _movieById(booking.movieId);
          final session = _sessionById(booking.sessionId);

          return BookingCard(
            booking: booking,
            movie:   movie,
            session: session,
          );
        },
      ),
    );
  }
}
