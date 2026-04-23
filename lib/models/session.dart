// ============================================================
//  lib/models/session.dart
// ============================================================
//
//  ИЗМЕНЕНИЯ: добавлено поле List<Seat> seats — полная карта
//  мест зала. Генерируется через HallLayout.generateSeats().
//  Сериализация включает каждое место со статусом isBooked.
//
// ============================================================

import 'seat.dart';

class Session {
  final String      id;
  final int         movieId;
  final DateTime    dateTime;
  final String      hall;
  final double      price;      // базовая цена (для совместимости UI)
  final int         totalSeats;
  int               bookedSeats;
  List<Seat>        seats;      // ← НОВОЕ: полная карта мест

  Session({
    required this.id,
    required this.movieId,
    required this.dateTime,
    required this.hall,
    required this.price,
    required this.totalSeats,
    this.bookedSeats = 0,
    List<Seat>? seats,
  }) : seats = seats ?? HallLayout.generateSeats(hall);

  int get availableSeats => totalSeats - bookedSeats;

  String get formattedDateTime {
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day} ${months[dateTime.month]}, $h:$m';
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'movieId':     movieId,
    'dateTime':    dateTime.toIso8601String(),
    'hall':        hall,
    'price':       price,
    'totalSeats':  totalSeats,
    'bookedSeats': bookedSeats,
    'seats':       seats.map((s) => s.toJson()).toList(),
  };

  factory Session.fromJson(Map<String, dynamic> json) {
    final rawSeats = json['seats'] as List?;
    final seats = rawSeats != null
        ? rawSeats.map((s) => Seat.fromJson(s as Map<String, dynamic>)).toList()
        : HallLayout.generateSeats(json['hall'] as String);

    return Session(
      id:          json['id'],
      movieId:     json['movieId'],
      dateTime:    DateTime.parse(json['dateTime']).toLocal(),
      hall:        json['hall'],
      price:       (json['price'] as num).toDouble(),
      totalSeats:  json['totalSeats'],
      bookedSeats: json['bookedSeats'] ?? 0,
      seats:       seats,
    );
  }

  Session copyWith({
    int?       movieId,
    DateTime?  dateTime,
    String?    hall,
    double?    price,
    int?       totalSeats,
    int?       bookedSeats,
    List<Seat>? seats,
  }) {
    return Session(
      id:          id,
      movieId:     movieId     ?? this.movieId,
      dateTime:    dateTime    ?? this.dateTime,
      hall:        hall        ?? this.hall,
      price:       price       ?? this.price,
      totalSeats:  totalSeats  ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      seats:       seats       ?? List.from(this.seats),
    );
  }
}
