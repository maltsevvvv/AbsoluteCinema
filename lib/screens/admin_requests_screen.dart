// ============================================================
//  lib/screens/admin_requests_screen.dart
// ============================================================
//
//  Экран «Заявки» для кассира.
//  Кассир видит все pending-заявки от зрителей и может
//  одобрить или отклонить каждую.
//
//  Закрывает пункты методички:
//    1  — редактирование данных (смена статуса брони)
//    8  — два пользователя взаимодействуют
//    9  — изменения кассира сохраняются и видны зрителю
//  Группа: уведомления — счётчик pending в шапке
//
// ============================================================

import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/movie.dart';
import '../models/session.dart';
import '../services/storage_service.dart';
import '../styles/app_styles.dart';
import '../widgets/booking_card.dart';

class AdminRequestsScreen extends StatefulWidget {
  final VoidCallback? onBookingHandled;
  const AdminRequestsScreen({super.key, this.onBookingHandled});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();

  late TabController _tabController;

  List<Booking> _pending = [];
  List<Booking> _approved = [];
  List<Booking> _rejected = [];
  List<Movie> _movies = [];
  List<Session> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final bookings = await _storage.loadBookings();
    final movies = await _storage.loadMoviesCache();
    final sessions = await _storage.loadSessions();

    setState(() {
      _pending = bookings
          .where((b) => b.status == BookingStatus.pending)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _approved = bookings
          .where((b) => b.status == BookingStatus.approved)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _rejected = bookings
          .where((b) => b.status == BookingStatus.rejected)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _movies = movies;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Movie? _movieById(int id) {
    try {
      return _movies.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Session? _sessionById(String id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Одобрить заявку ───────────────────────────────────────
  Future<void> _approve(Booking booking) async {
    await _storage.updateBookingStatus(booking.id, BookingStatus.approved);
    await _loadData();
    widget.onBookingHandled?.call(); // FIX: обновляем колокольчик

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Заявка одобрена'),
        backgroundColor: AppStyles.success,
      ),
    );
  }

  // ── Отклонить заявку ──────────────────────────────────────
  Future<void> _reject(Booking booking) async {
    // Запрашиваем подтверждение
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppStyles.surface,
        title: const Text('Отклонить заявку?', style: AppStyles.title),
        content: Text(
          'Места будут освобождены и вернутся в доступные.',
          style: AppStyles.subtitle,
        ),
        actions: [
          TextButton(
            child: const Text('Отмена',
                style: TextStyle(color: AppStyles.textSecond)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppStyles.error),
            child: const Text('Отклонить'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _storage.updateBookingStatus(booking.id, BookingStatus.rejected);
    await _loadData();
    widget.onBookingHandled?.call(); // FIX: обновляем колокольчик

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Заявка отклонена, места освобождены'),
        backgroundColor: AppStyles.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Заявки'),
            // Счётчик уведомлений (групповое задание)
            if (_pending.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppStyles.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_pending.length}',
                  style: AppStyles.badge.copyWith(color: AppStyles.primary),
                ),
              ),
            ],
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          // ФИХ #3: текст в скобках обрезался — включаем скроллируемые табы
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppStyles.accent,
          labelColor: AppStyles.accent,
          unselectedLabelColor: AppStyles.textSecond,
          tabs: [
            Tab(text: 'Новые (${_pending.length})'),
            Tab(text: 'Одобрены (${_approved.length})'),
            Tab(text: 'Отклонены (${_rejected.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppStyles.accent))
          : RefreshIndicator(
              color: AppStyles.accent,
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Вкладка «Новые» — с кнопками одобрить/отклонить
                  _buildList(
                    _pending,
                    emptyMsg: 'Нет новых заявок',
                    showActions: true,
                  ),
                  // Вкладка «Одобрены»
                  _buildList(
                    _approved,
                    emptyMsg: 'Нет одобренных заявок',
                  ),
                  // Вкладка «Отклонены»
                  _buildList(
                    _rejected,
                    emptyMsg: 'Нет отклонённых заявок',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildList(
    List<Booking> bookings, {
    required String emptyMsg,
    bool showActions = false,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 56, color: AppStyles.textSecond),
            const SizedBox(height: 12),
            Text(emptyMsg, style: AppStyles.subtitle),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppStyles.paddingS),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
          movie: _movieById(booking.movieId),
          session: _sessionById(booking.sessionId),
          onApprove: showActions ? () => _approve(booking) : null,
          onReject: showActions ? () => _reject(booking) : null,
        );
      },
    );
  }
}
