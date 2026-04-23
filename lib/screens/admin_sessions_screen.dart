// ============================================================
//  lib/screens/admin_sessions_screen.dart
// ============================================================
//
//  Экран «Сеансы» для кассира.
//  Кассир может просматривать, добавлять и редактировать сеансы.
//  Редактирование вручную закрывает пункт 1 методички полностью.
//
//  Закрывает пункты методички:
//    1  — редактирование данных вручную (изменение сеанса)
//    6  — хранение через storage_service
//
// ============================================================

import 'package:flutter/material.dart';

import '../models/seat.dart';
import '../models/session.dart';
import '../services/storage_service.dart';
import '../styles/app_styles.dart';

class AdminSessionsScreen extends StatefulWidget {
  const AdminSessionsScreen({super.key});

  @override
  State<AdminSessionsScreen> createState() => _AdminSessionsScreenState();
}

class _AdminSessionsScreenState extends State<AdminSessionsScreen> {
  final StorageService _storage = StorageService();

  List<Session> _sessions  = [];
  bool          _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final sessions = await _storage.loadSessions();
    sessions.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    setState(() {
      _sessions  = sessions;
      _isLoading = false;
    });
  }

  // ── Диалог добавления / редактирования сеанса ─────────────
  // Пункт 1 методички: реальное редактирование данных вручную
  Future<void> _showSessionDialog({Session? existing}) async {
    // Контроллеры полей
    final hallCtrl  = TextEditingController(text: existing?.hall ?? '');
    final priceCtrl = TextEditingController(
        text: existing?.price.toInt().toString() ?? '');
    final seatsCtrl = TextEditingController(
        text: existing?.totalSeats.toString() ?? '');

    // Выбранные дата и время
    DateTime selectedDate = existing?.dateTime ??
        DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay.fromDateTime(existing.dateTime)
        : const TimeOfDay(hour: 18, minute: 0);

    // movieId — для простоты вводится вручную
    // (в реальном проекте был бы Dropdown из загруженных фильмов)
    final movieIdCtrl = TextEditingController(
        text: existing?.movieId.toString() ?? '');

    final formKey = GlobalKey<FormState>();
    final isEdit  = existing != null;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppStyles.surface,
          title: Text(
            isEdit ? 'Редактировать сеанс' : 'Новый сеанс',
            style: AppStyles.title,
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ID фильма
                  TextFormField(
                    controller: movieIdCtrl,
                    keyboardType: TextInputType.number,
                    style: AppStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'ID фильма (из TMDB)',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Введите ID фильма';
                      }
                      if (int.tryParse(v.trim()) == null) {
                        return 'Должно быть числом';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Зал
                  TextFormField(
                    controller: hallCtrl,
                    style: AppStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'Зал (например: Зал 1, VIP)',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Введите зал' : null,
                  ),
                  const SizedBox(height: 12),

                  // Цена
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: AppStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'Цена билета (₽)',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Введите цену';
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return 'Должно быть числом';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Количество мест
                  TextFormField(
                    controller: seatsCtrl,
                    keyboardType: TextInputType.number,
                    style: AppStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'Количество мест',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Введите количество мест';
                      }
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) {
                        return 'Должно быть положительным числом';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Выбор даты
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today,
                        color: AppStyles.accent),
                    title: Text(
                      '${selectedDate.day.toString().padLeft(2, '0')}.'
                      '${selectedDate.month.toString().padLeft(2, '0')}.'
                      '${selectedDate.year}',
                      style: AppStyles.body,
                    ),
                    subtitle: const Text('Дата сеанса',
                        style: AppStyles.caption),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.dark(),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),

                  // Выбор времени
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time,
                        color: AppStyles.accent),
                    title: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:'
                      '${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: AppStyles.body,
                    ),
                    subtitle: const Text('Время начала',
                        style: AppStyles.caption),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime,
                        builder: (ctx, child) => Theme(
                          data: ThemeData.dark(),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Отмена',
                  style: TextStyle(color: AppStyles.textSecond)),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              child: Text(isEdit ? 'Сохранить' : 'Добавить'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                // Собираем дату+время
                final dateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                if (isEdit) {
                  // ФИХ #4: если изменился зал или количество мест —
                  // пересоздаём схему мест (seats), иначе зритель
                  // видит старое количество свободных мест
                  final newHall = hallCtrl.text.trim();
                  final newTotal = int.parse(seatsCtrl.text.trim());
                  final hallChanged = newHall != existing!.hall;
                  final seatsChanged = newTotal != existing.totalSeats;

                  // Сохраняем уже занятые места если зал не менялся
                  List<Seat>? newSeats;
                  if (hallChanged || seatsChanged) {
                    // Зал или количество изменилось — генерируем новую схему
                    // Занятые брони при этом остаются в booking-ах,
                    // но физическая схема пересоздаётся
                    newSeats = HallLayout.generateSeats(newHall);
                  }

                  final updated = existing.copyWith(
                    movieId:    int.parse(movieIdCtrl.text.trim()),
                    dateTime:   dateTime,
                    hall:       newHall,
                    price:      double.parse(priceCtrl.text.trim()),
                    totalSeats: newTotal,
                    bookedSeats: (hallChanged || seatsChanged) ? 0 : null,
                    seats:      newSeats,
                  );
                  await _storage.updateSession(updated);
                } else {
                  // Добавление нового сеанса
                  final newSession = Session(
                    id:         's_${DateTime.now().millisecondsSinceEpoch}',
                    movieId:    int.parse(movieIdCtrl.text.trim()),
                    dateTime:   dateTime,
                    hall:       hallCtrl.text.trim(),
                    price:      double.parse(priceCtrl.text.trim()),
                    totalSeats: int.parse(seatsCtrl.text.trim()),
                  );
                  await _storage.addSession(newSession);
                }

                Navigator.pop(ctx);
                await _loadSessions();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сеансы'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppStyles.accent))
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 56, color: AppStyles.textSecond),
                      const SizedBox(height: 12),
                      const Text('Нет сеансов',
                          style: AppStyles.subtitle),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить сеанс'),
                        onPressed: () => _showSessionDialog(),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppStyles.accent,
                  onRefresh: _loadSessions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppStyles.paddingS),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return _buildSessionTile(session);
                    },
                  ),
                ),

      // Кнопка добавить сеанс
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppStyles.accent,
        foregroundColor: AppStyles.primary,
        onPressed: () => _showSessionDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSessionTile(Session session) {
    final isFull = session.availableSeats == 0;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingM, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isFull ? AppStyles.error : AppStyles.primary,
          child: Text(
            session.availableSeats.toString(),
            style: AppStyles.badge,
          ),
        ),
        title: Text(session.formattedDateTime, style: AppStyles.body),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.hall}  ·  ${session.price.toInt()} ₽',
              style: AppStyles.subtitle,
            ),
            Text(
              'ID фильма: ${session.movieId}  '
              '·  мест: ${session.bookedSeats}/${session.totalSeats}',
              style: AppStyles.caption,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined,
              color: AppStyles.textSecond),
          tooltip: 'Редактировать',
          onPressed: () => _showSessionDialog(existing: session),
        ),
        isThreeLine: true,
      ),
    );
  }
}
