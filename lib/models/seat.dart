// ============================================================
//  lib/models/seat.dart
// ============================================================
//
//  Модель одного места в зале кинотеатра.
//  Тип места определяет цену билета.
//
//  Используется в:
//    - session.dart   (List<Seat> seats)
//    - seat_picker_dialog.dart (визуальная схема)
//    - booking.dart   (List<String> seatIds)
//    - storage_service.dart (сериализация)
//
// ============================================================

// ─── ENUM: тип места ─────────────────────────────────────────
enum SeatType { standard, comfort, vip }

extension SeatTypeInfo on SeatType {
  String get label {
    switch (this) {
      case SeatType.standard:
        return 'Стандарт';
      case SeatType.comfort:
        return 'Комфорт';
      case SeatType.vip:
        return 'VIP';
    }
  }

  double get price {
    switch (this) {
      case SeatType.standard:
        return 350;
      case SeatType.comfort:
        return 550;
      case SeatType.vip:
        return 850;
    }
  }
}

// ─── МОДЕЛЬ: Место ───────────────────────────────────────────
class Seat {
  final String id; // напр. 'A3' (ряд+номер)
  final String rowLabel; // 'A', 'B', ...
  final int number; // 1, 2, 3, ...
  final SeatType type;
  bool isBooked; // true = уже занято

  Seat({
    required this.id,
    required this.rowLabel,
    required this.number,
    required this.type,
    this.isBooked = false,
  });

  double get price => type.price;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rowLabel': rowLabel,
        'number': number,
        'type': type.index,
        'isBooked': isBooked,
      };

  factory Seat.fromJson(Map<String, dynamic> j) => Seat(
        id: j['id'],
        rowLabel: j['rowLabel'],
        number: j['number'],
        type: SeatType.values[j['type']],
        isBooked: j['isBooked'] ?? false,
      );

  Seat copyWith({bool? isBooked}) => Seat(
        id: id,
        rowLabel: rowLabel,
        number: number,
        type: type,
        isBooked: isBooked ?? this.isBooked,
      );
}

// ─── ГЕНЕРАТОР СХЕМЫ ЗАЛА ────────────────────────────────────
//
//  Зал 1 (80 мест): ряды A–C standard (10), D–F comfort (10)
//  Зал 2 (100 мест): ряды A–D standard (12), E–H comfort (12), I standard (4)
//  VIP   (30 мест): ряды A–E по 6 мест — все VIP (850 ₽)
//
class HallLayout {
  // Описание одного ряда: буква, кол-во мест, тип
  static const List<Map<String, dynamic>> _hall1 = [
    {'row': 'A', 'count': 10, 'type': 0}, // standard
    {'row': 'B', 'count': 10, 'type': 0},
    {'row': 'C', 'count': 10, 'type': 0},
    {'row': 'D', 'count': 10, 'type': 1}, // comfort
    {'row': 'E', 'count': 10, 'type': 1},
    {'row': 'F', 'count': 10, 'type': 1},
    {'row': 'G', 'count': 10, 'type': 1},
    {'row': 'H', 'count': 10, 'type': 1},
  ];

  static const List<Map<String, dynamic>> _hall2 = [
    {'row': 'A', 'count': 12, 'type': 0},
    {'row': 'B', 'count': 12, 'type': 0},
    {'row': 'C', 'count': 12, 'type': 0},
    {'row': 'D', 'count': 12, 'type': 0},
    {'row': 'E', 'count': 12, 'type': 1},
    {'row': 'F', 'count': 12, 'type': 1},
    {'row': 'G', 'count': 12, 'type': 1},
    {'row': 'H', 'count': 12, 'type': 1},
    {'row': 'I', 'count': 4, 'type': 0},
  ];

  static const List<Map<String, dynamic>> _vip = [
    {'row': 'A', 'count': 6, 'type': 2}, // vip
    {'row': 'B', 'count': 6, 'type': 2},
    {'row': 'C', 'count': 6, 'type': 2},
    {'row': 'D', 'count': 6, 'type': 2},
    {'row': 'E', 'count': 6, 'type': 2},
  ];

  static List<Seat> generateSeats(String hall) {
    final layout = hall.toUpperCase().startsWith('VIP')
        ? _vip
        : hall.contains('2')
            ? _hall2
            : _hall1;

    final seats = <Seat>[];
    for (final rowDef in layout) {
      final rowLabel = rowDef['row'] as String;
      final count = rowDef['count'] as int;
      final type = SeatType.values[rowDef['type'] as int];
      for (int n = 1; n <= count; n++) {
        seats.add(Seat(
          id: '$rowLabel$n',
          rowLabel: rowLabel,
          number: n,
          type: type,
        ));
      }
    }
    return seats;
  }

  // Группировка мест по рядам (для отрисовки)
  static Map<String, List<Seat>> groupByRow(List<Seat> seats) {
    final map = <String, List<Seat>>{};
    for (final s in seats) {
      map.putIfAbsent(s.rowLabel, () => []).add(s);
    }
    return map;
  }
}
