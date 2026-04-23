// ============================================================
//  lib/models/booking.dart
// ============================================================
//
//  ИЗМЕНЕНИЯ:
//    - поле seats (int) заменено на seatIds (List<String>)
//    - totalPrice теперь считается по типам мест, а не по базовой цене
//    - добавлен геттер seatsCount для обратной совместимости UI
//
// ============================================================

enum BookingStatus { pending, approved, rejected }

extension BookingStatusLabel on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:  return 'На рассмотрении';
      case BookingStatus.approved: return 'Одобрено';
      case BookingStatus.rejected: return 'Отклонено';
    }
  }
}

class Booking {
  final String       id;
  final String       userId;
  final String       sessionId;
  final int          movieId;
  final List<String> seatIds;     // ← НОВОЕ: ['A3', 'A4', 'B5']
  final double       totalPrice;  // сумма по типам мест
  final DateTime     createdAt;
  BookingStatus      status;

  Booking({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.movieId,
    required this.seatIds,
    required this.totalPrice,
    required this.createdAt,
    this.status = BookingStatus.pending,
  });

  // Для обратной совместимости в UI (например, "2 места")
  int get seatsCount => seatIds.length;

  // Отображаемый список мест: 'A3, A4, B5'
  String get seatsLabel => seatIds.join(', ');

  Map<String, dynamic> toJson() => {
    'id':         id,
    'userId':     userId,
    'sessionId':  sessionId,
    'movieId':    movieId,
    'seatIds':    seatIds,
    'totalPrice': totalPrice,
    'createdAt':  createdAt.toIso8601String(),
    'status':     status.index,
  };

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Поддержка старого формата (int seats) при миграции данных
    List<String> seatIds;
    if (json['seatIds'] != null) {
      seatIds = List<String>.from(json['seatIds']);
    } else {
      // Старый формат — генерируем заглушки
      final count = (json['seats'] as int?) ?? 1;
      seatIds = List.generate(count, (i) => '?${i + 1}');
    }

    return Booking(
      id:         json['id'],
      userId:     json['userId'],
      sessionId:  json['sessionId'],
      movieId:    json['movieId'],
      seatIds:    seatIds,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      createdAt:  DateTime.parse(json['createdAt']).toLocal(),
      status:     BookingStatus.values[json['status']],
    );
  }

  Booking copyWith({BookingStatus? status}) => Booking(
    id:         id,
    userId:     userId,
    sessionId:  sessionId,
    movieId:    movieId,
    seatIds:    seatIds,
    totalPrice: totalPrice,
    createdAt:  createdAt,
    status:     status ?? this.status,
  );
}
