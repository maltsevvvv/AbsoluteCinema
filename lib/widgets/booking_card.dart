// ============================================================
//  lib/widgets/booking_card.dart
// ============================================================

import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/movie.dart';
import '../models/session.dart';
import '../styles/app_styles.dart';

class BookingCard extends StatelessWidget {
  final Booking bookig;
  final Movie? movie;
  final Session? session;

  // 🔥 ДОБАВИЛИ
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const BookingCard({
    super.key,
    required this.booking,
    this.movie,
    this.session,
    this.onApprove,
    this.onReject,
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

            // ── Итоговая сумма ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Создана: ${_formatDate(booking.createdAt)}',
                  style: AppStyles.caption,
                ),
                Text(
                  '${booking.totalPrice.toStringAsFixed(0)} ₽',
                  style: AppStyles.body.copyWith(
                      color: AppStyles.accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),

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
