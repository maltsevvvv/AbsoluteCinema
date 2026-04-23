// ============================================================
//  lib/screens/movie_detail_screen.dart
// ============================================================
//
//  ИЗМЕНЕНИЯ:
//    - _showBookingDialog() заменён на _openSeatPicker()
//    - _createBooking() принимает List<Seat> вместо int seats
//    - Booking создаётся с seatIds и реальной totalPrice
//
// ============================================================

import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../models/session.dart';
import '../models/booking.dart';
import '../models/seat.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../styles/app_styles.dart';
import '../widgets/seat_picker_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final AuthService    _auth    = AuthService();
  final StorageService _storage = StorageService();

  List<Session> _sessions  = [];
  List<int>     _favorites = [];
  bool          _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final allSessions = await _storage.loadSessions();
    final favs        = await _storage.loadFavorites(_auth.userId);
    setState(() {
      _sessions  = allSessions
          .where((s) => s.movieId == widget.movie.id)
          .toList();
      _favorites = favs;
      _isLoading = false;
    });
  }

  // ── Избранное ─────────────────────────────────────────────
  Future<void> _toggleFavorite() async {
    if (_favorites.contains(widget.movie.id)) {
      await _storage.removeFavorite(_auth.userId, widget.movie.id);
    } else {
      await _storage.addFavorite(_auth.userId, widget.movie.id);
    }
    final favs = await _storage.loadFavorites(_auth.userId);
    setState(() => _favorites = favs);
  }

  // ── Открыть схему зала ────────────────────────────────────
  Future<void> _openSeatPicker(Session session) async {
    // Перезагружаем свежее состояние сеанса (актуальные isBooked)
    final freshSessions = await _storage.loadSessions();
    final freshSession  = freshSessions.firstWhere(
      (s) => s.id == session.id,
      orElse: () => session,
    );

    if (!mounted) return;

    final chosenSeats = await showSeatPicker(
      context: context,
      session: freshSession,
    );

    if (chosenSeats == null || chosenSeats.isEmpty) return;

    await _createBooking(freshSession, chosenSeats);
  }

  // ── Создать бронь по выбранным местам ────────────────────
  Future<void> _createBooking(Session session, List<Seat> seats) async {
    final totalPrice = seats.fold<double>(0, (sum, s) => sum + s.price);

    final booking = Booking(
      id:         'b_${DateTime.now().millisecondsSinceEpoch}',
      userId:     _auth.userId,
      sessionId:  session.id,
      movieId:    widget.movie.id,
      seatIds:    seats.map((s) => s.id).toList(),
      totalPrice: totalPrice,
      createdAt:  DateTime.now(),
    );

    final error = await _storage.addBooking(booking);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppStyles.error,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Заявка отправлена! Ожидайте подтверждения кассира.'),
        backgroundColor: AppStyles.success,
      ));
      await _loadData();
    }
  }

  // ── Редактирование фильма (кассир) ────────────────────────
  Future<void> _showEditDialog() async {
    final descCtrl  = TextEditingController(text: widget.movie.description);
    final titleCtrl = TextEditingController(text: widget.movie.title);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppStyles.surface,
        title: Text('Редактировать фильм', style: AppStyles.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: AppStyles.body,
                decoration:
                    const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: AppStyles.body,
                maxLines: 5,
                decoration:
                    const InputDecoration(labelText: 'Описание'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена',
                style: TextStyle(color: AppStyles.textSecond)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = widget.movie.copyWith(
                title:       titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              final cached = await _storage.loadMoviesCache();
              final idx    = cached.indexWhere((m) => m.id == updated.id);
              if (idx != -1) {
                cached[idx] = updated;
                await _storage.saveMoviesCache(cached);
              }
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Изменения сохранены'),
                  backgroundColor: AppStyles.success,
                ),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final movie    = widget.movie;
    final isFav    = _favorites.contains(movie.id);
    final isViewer = _auth.isViewer;

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (isViewer)
            IconButton(
              icon: Icon(
                isFav ? Icons.star : Icons.star_border,
                color: isFav
                    ? AppStyles.accent
                    : AppStyles.textPrimary,
              ),
              onPressed: _toggleFavorite,
            ),
          if (_auth.isCashier)
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppStyles.textPrimary),
              tooltip: 'Редактировать описание',
              onPressed: _showEditDialog,
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _isLoading
          ? const Center(
              key: ValueKey('loading'),
              child: CircularProgressIndicator(color: AppStyles.accent))
          : SingleChildScrollView(
              key: const ValueKey('content'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(movie),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.paddingM),
                    child: Text(movie.description,
                        style: AppStyles.body),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.paddingM),
                    child: Text('Сеансы', style: AppStyles.title),
                  ),
                  const SizedBox(height: 8),
                  if (_sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppStyles.paddingM),
                      child: Text('Сеансов пока нет',
                          style: AppStyles.subtitle),
                    )
                  else
                    ..._sessions.map(
                        (s) => _buildSessionTile(s, isViewer)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
        ),
    );
  }

  Widget _buildHeader(Movie movie) {
    return Container(
      color: AppStyles.surface,
      padding: const EdgeInsets.all(AppStyles.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'poster_\${movie.id}',
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppStyles.radiusM),
              child: movie.posterUrl.isNotEmpty
                  ? Image.network(
                      movie.posterUrl,
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          width: 120,
                          height: 180,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppStyles.accent,
                              value: progress.expectedTotalBytes !=
                                      null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) =>
                          _posterPlaceholder(),
                    )
                  : _posterPlaceholder(),
            ),
          ),
          const SizedBox(width: AppStyles.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movie.title,
                    style: AppStyles.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                _infoRow(Icons.theaters, movie.genre.label),
                _infoRow(Icons.calendar_today,
                    movie.year.toString()),
                _infoRow(
                    Icons.star,
                    movie.rating.toStringAsFixed(1),
                    color: AppStyles.accent),
                if (movie.durationMinutes > 0)
                  _infoRow(Icons.access_time,
                      '${movie.durationMinutes} мин'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(icon,
              size: 14,
              color: color ?? AppStyles.textSecond),
          const SizedBox(width: 6),
          Text(text,
              style:
                  AppStyles.subtitle.copyWith(color: color)),
        ]),
      );

  Widget _posterPlaceholder() => Container(
        width: 120,
        height: 180,
        color: AppStyles.surface,
        child: const Icon(Icons.movie,
            color: AppStyles.textSecond, size: 48),
      );

  // ── Плитка сеанса ─────────────────────────────────────────
  Widget _buildSessionTile(Session session, bool canBook) {
    final isFull = session.availableSeats == 0;

    // Считаем свободные места из схемы (точнее, чем bookedSeats)
    final freeInLayout =
        session.seats.where((s) => !s.isBooked).length;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingM, vertical: 4),
      child: ListTile(
        title: Text(session.formattedDateTime,
            style: AppStyles.body),
        subtitle: Text(
          '${session.hall}  ·  от 350 ₽  '
          '·  свободно: $freeInLayout',
          style: AppStyles.subtitle,
        ),
        trailing: canBook
            ? ElevatedButton(
                onPressed: (isFull || freeInLayout == 0)
                    ? null
                    : () => _openSeatPicker(session),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (isFull || freeInLayout == 0)
                          ? AppStyles.textSecond
                          : AppStyles.primary,
                ),
                child: Text(
                    (isFull || freeInLayout == 0)
                        ? 'Мест нет'
                        : 'Выбрать место'),
              )
            : null,
      ),
    );
  }
}
