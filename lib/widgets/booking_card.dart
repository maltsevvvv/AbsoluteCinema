// ============================================================
//  lib/widgets/booking_card.dart
// ============================================================

import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/movie.dart';
import '../models/session.dart';
import '../styles/app_styles.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final Movie? movie;
  final Session? session;

  // 🔥 ДОБАВИЛИ
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final String? userName; // имя пользователя (показывается кассиру)

  const BookingCard({
    super.key,
    required this.booking,
    this.movie,
    this.session,
    this.onApprove,
    this.onReject,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingS, vertical: AppStyles.paddingS / 2),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Строка: фильм + статус ────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    movie?.title ?? 'Фильм #${booking.movieId}',
                    style: AppStyles.body.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 6),

            // ── Дата и зал ───────────────────────────────
            if (session != null) ...[
              _infoRow(Icons.event, session!.formattedDateTime),
              _infoRow(Icons.place, session!.hall),
            ],

            const SizedBox(height: 6),

            // ── Места ────────────────────────────────────
            _buildSeatsRow(),

            const SizedBox(height: 6),

            // ── Пользователь (только для кассира) ────────
            if (userName != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_outline,
                    size: 13, color: AppStyles.textSecond),
                const SizedBox(width: 4),
                Text(userName!, style: AppStyles.caption),
              ]),
            ],

            // ── Итоговая сумма ───────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${booking.totalPrice.toStringAsFixed(0)} ₽',
                style: AppStyles.body.copyWith(
                    color: AppStyles.accent, fontWeight: FontWeight.bold),
              ),
            ),

            // ── QR-код для одобренной брони (только зрителю) ──
            if (booking.status == BookingStatus.approved &&
                onApprove == null) ...[
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => _showQrFullscreen(context),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppStyles.radiusS),
                        ),
                        child: _QrWidget(data: _qrData(), size: 120),
                      ),
                      const SizedBox(height: 4),
                      Text('Нажмите для увеличения',
                          style: AppStyles.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],

            // 🔥 КНОПКИ ДЛЯ КАССИРА
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppStyles.error,
                        side: const BorderSide(
                            color: AppStyles.error, width: 1.5),
                      ),
                      child: const Text('Отклонить'),
                    ),
                  const SizedBox(width: 8),
                  if (onApprove != null)
                    ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Одобрить'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── QR данные ────────────────────────────────
  String _qrData() {
    return 'CINEMA:${booking.id}|${booking.movieId}|${booking.userId}|${booking.seatIds.join(",")}|${booking.totalPrice.toStringAsFixed(0)}';
  }

  void _showQrFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppStyles.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusL)),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ваш билет', style: AppStyles.title),
              const SizedBox(height: 8),
              Text(
                movie?.title ?? '',
                style: AppStyles.subtitle,
                textAlign: TextAlign.center,
              ),
              if (session != null)
                Text(session!.formattedDateTime, style: AppStyles.caption),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppStyles.radiusM),
                ),
                child: _QrWidget(data: _qrData(), size: 220),
              ),
              const SizedBox(height: 12),
              Text(
                'Места: ${booking.seatIds.join(", ")}',
                style: AppStyles.caption,
              ),
              Text(
                '${booking.totalPrice.toStringAsFixed(0)} ₽',
                style: AppStyles.body.copyWith(
                    color: AppStyles.accent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Закрыть',
                    style: TextStyle(color: AppStyles.textSecond)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Места ─────────────────────────────────────
  Widget _buildSeatsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.event_seat_outlined,
            size: 14, color: AppStyles.textSecond),
        const SizedBox(width: 4),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: booking.seatIds.map((id) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppStyles.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppStyles.radiusS),
                  border: Border.all(
                      color: AppStyles.primary.withValues(alpha: 0.4),
                      width: 0.5),
                ),
                child: Text(
                  id,
                  style: AppStyles.caption.copyWith(
                      color: AppStyles.textPrimary,
                      fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
          ),
        ),
        Text(
          '${booking.seatsCount} шт.',
          style: AppStyles.caption,
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Icon(icon, size: 13, color: AppStyles.textSecond),
          const SizedBox(width: 4),
          Text(text, style: AppStyles.caption),
        ]),
      );

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppStyles.pending;
      case BookingStatus.approved:
        return AppStyles.success;
      case BookingStatus.rejected:
        return AppStyles.error;
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m $h:$min';
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (status) {
      case BookingStatus.pending:
        bg = AppStyles.pending.withValues(alpha: 0.18);
        text = AppStyles.pending;
        break;
      case BookingStatus.approved:
        bg = AppStyles.success.withValues(alpha: 0.18);
        text = AppStyles.success;
        break;
      case BookingStatus.rejected:
        bg = AppStyles.error.withValues(alpha: 0.18);
        text = AppStyles.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppStyles.radiusS),
      ),
      child: Text(
        status.label,
        style: AppStyles.caption
            .copyWith(color: text, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── QR виджет ────────────────────────────────────────────────
class _QrWidget extends StatelessWidget {
  final String data;
  final double size;
  const _QrWidget({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );
  }
}
