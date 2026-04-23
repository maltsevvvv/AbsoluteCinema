// ============================================================
//  lib/widgets/seat_picker_dialog.dart
// ============================================================
//
//  Диалог выбора мест в зале кинотеатра.
//
//  Показывает:
//    - экран (синяя полоса сверху)
//    - схему зала с цветовой градацией по типу места
//    - легенду: стандарт/комфорт/vip/занято/выбрано с ценами
//    - итоговую сумму и выбранные места
//    - кнопку подтверждения
//
//  Цветовая схема:
//    Стандарт  → зелёный  (350 ₽)
//    Комфорт   → синий    (550 ₽)
//    VIP       → жёлтый   (850 ₽)
//    Занято    → серый, не кликается
//    Выбрано   → фиолетовый
//
// ============================================================

import 'package:flutter/material.dart';
import '../models/seat.dart';
import '../models/session.dart';
import '../styles/app_styles.dart';

// ── Цвета типов мест ──────────────────────────────────────────
const _colorStd = Color(0xFF1D9E75); // зелёный
const _colorStdLight = Color(0xFFE1F5EE);
const _colorComf = Color(0xFF378ADD); // синий
const _colorComfLight = Color(0xFFE6F1FB);
const _colorVip = Color(0xFFBA7517); // янтарный
const _colorVipLight = Color(0xFFFAEEDA);
const _colorBooked = Color(0xFF888780); // серый
const _colorSelected = Color(0xFF534AB7); // фиолетовый
const _colorSelLight = Color(0xFFCECBF6);

// ── Вспомогательная функция-обёртка ──────────────────────────
Future<List<Seat>?> showSeatPicker({
  required BuildContext context,
  required Session session,
}) {
  return showDialog<List<Seat>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SeatPickerDialog(session: session),
  );
}

// ── Виджет диалога ────────────────────────────────────────────
class SeatPickerDialog extends StatefulWidget {
  final Session session;
  const SeatPickerDialog({super.key, required this.session});

  @override
  State<SeatPickerDialog> createState() => _SeatPickerDialogState();
}

class _SeatPickerDialogState extends State<SeatPickerDialog> {
  // Рабочая копия мест — не мутируем оригинал
  late List<Seat> _seats;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Глубокая копия, чтобы пометка selected не утекала наружу
    _seats = widget.session.seats
        .map((s) => Seat(
              id: s.id,
              rowLabel: s.rowLabel,
              number: s.number,
              type: s.type,
              isBooked: s.isBooked,
            ))
        .toList();
  }

  // ── Переключить выбор места ──────────────────────────────
  void _toggle(Seat seat) {
    if (seat.isBooked) return;
    setState(() {
      if (_selectedIds.contains(seat.id)) {
        _selectedIds.remove(seat.id);
      } else {
        _selectedIds.add(seat.id);
      }
    });
  }

  // ── Итоговая сумма ───────────────────────────────────────
  double get _total {
    double sum = 0;
    for (final id in _selectedIds) {
      final seat = _seats.firstWhere((s) => s.id == id);
      sum += seat.price;
    }
    return sum;
  }

  // ── Выбранные объекты ────────────────────────────────────
  List<Seat> get _selectedSeats =>
      _seats.where((s) => _selectedIds.contains(s.id)).toList();

  @override
  Widget build(BuildContext context) {
    final rows = HallLayout.groupByRow(_seats);
    final rowKeys = rows.keys.toList();

    return Dialog(
      backgroundColor: AppStyles.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusL)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Шапка ────────────────────────────────────────
          _buildHeader(),

          // ── Экран ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(children: [
              Container(
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Color(0xFF378ADD).withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('экран',
                  style: AppStyles.caption.copyWith(
                      letterSpacing: 1.5, color: AppStyles.textSecond)),
            ]),
          ),

          // ── Схема мест (скроллируемая) ────────────────────
          // ФИХ #2: добавляем горизонтальный скролл чтобы
          // убрать overflow / жёлто-чёрную ленту
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      rowKeys.map((rk) => _buildRow(rk, rows[rk]!)).toList(),
                ),
              ),
            ),
          ),

          // ── Легенда ───────────────────────────────────────
          _buildLegend(),

          // ── Итог и кнопки ────────────────────────────────
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Шапка ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppStyles.primary,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppStyles.radiusL)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Выбор мест',
                    style: AppStyles.title.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  '${widget.session.formattedDateTime}  ·  ${widget.session.hall}',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.close, color: AppStyles.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ── Один ряд кресел ──────────────────────────────────────
  Widget _buildRow(String rowLabel, List<Seat> seats) {
    // Сортируем по номеру места
    final sorted = [...seats]..sort((a, b) => a.number.compareTo(b.number));
    final half = sorted.length ~/ 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Метка ряда
          SizedBox(
            width: 20,
            child: Text(rowLabel,
                style: AppStyles.caption.copyWith(fontSize: 11),
                textAlign: TextAlign.right),
          ),
          const SizedBox(width: 4),
          // Левая половина
          ...sorted.take(half).map((s) => _buildSeat(s)),
          // Проход между секторами
          const SizedBox(width: 10),
          // Правая половина
          ...sorted.skip(half).map((s) => _buildSeat(s)),
        ],
      ),
    );
  }

  // ── Одно кресло ──────────────────────────────────────────
  Widget _buildSeat(Seat seat) {
    final isSelected = _selectedIds.contains(seat.id);
    final isBooked = seat.isBooked;

    Color bg, border;
    if (isBooked) {
      bg = AppStyles.surface;
      border = _colorBooked.withValues(alpha: 0.5);
    } else if (isSelected) {
      bg = _colorSelected;
      border = _colorSelLight;
    } else {
      switch (seat.type) {
        case SeatType.standard:
          bg = _colorStdLight;
          border = _colorStd;
          break;
        case SeatType.comfort:
          bg = _colorComfLight;
          border = _colorComf;
          break;
        case SeatType.vip:
          bg = _colorVipLight;
          border = _colorVip;
          break;
      }
    }

    return GestureDetector(
      onTap: isBooked ? null : () => _toggle(seat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.all(2),
        width: 26,
        height: 22,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 0.8),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(4),
            bottom: Radius.circular(2),
          ),
        ),
        child: Center(
          child: Text(
            '${seat.number}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isBooked
                  ? _colorBooked
                  : isSelected
                      ? _colorSelLight
                      : _textColor(seat.type),
            ),
          ),
        ),
      ),
    );
  }

  Color _textColor(SeatType t) {
    switch (t) {
      case SeatType.standard:
        return _colorStd;
      case SeatType.comfort:
        return _colorComf;
      case SeatType.vip:
        return _colorVip;
    }
  }

  // ── Легенда ───────────────────────────────────────────────
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
              color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          if (!widget.session.hall.toUpperCase().startsWith('VIP')) ...[
            _legendItem(_colorStdLight, _colorStd, 'Стандарт — 350 ₽'),
            _legendItem(_colorComfLight, _colorComf, 'Комфорт — 550 ₽'),
          ],
          if (widget.session.hall.toUpperCase().startsWith('VIP'))
            _legendItem(_colorVipLight, _colorVip, 'VIP — 850 ₽'),
          _legendItem(
              AppStyles.surface, _colorBooked.withValues(alpha: 0.5), 'Занято'),
          _legendItem(_colorSelected, _colorSelLight, 'Выбрано'),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 0.8),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3), bottom: Radius.circular(1)),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppStyles.caption),
      ],
    );
  }

  // ── Итог + кнопки ─────────────────────────────────────────
  Widget _buildFooter() {
    final hasSelection = _selectedIds.isNotEmpty;
    final sortedIds = [..._selectedIds]..sort();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Строка с выбранными местами и суммой
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppStyles.background,
              borderRadius: BorderRadius.circular(AppStyles.radiusS),
            ),
            child: Row(
              children: [
                Expanded(
                  child: hasSelection
                      ? Text(
                          'Места: ${sortedIds.join(', ')}',
                          style: AppStyles.subtitle.copyWith(fontSize: 13),
                        )
                      : Text(
                          'Выберите место на схеме',
                          style: AppStyles.caption,
                        ),
                ),
                if (hasSelection)
                  Text(
                    '${_total.toStringAsFixed(0)} ₽',
                    style: AppStyles.title
                        .copyWith(color: AppStyles.accent, fontSize: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Кнопки
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppStyles.textSecond),
                    foregroundColor: AppStyles.textSecond,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: hasSelection
                      ? () => Navigator.pop(
                            context,
                            _selectedSeats,
                          )
                      : null,
                  child: Text(hasSelection ? 'Подтвердить' : 'Выберите место'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
