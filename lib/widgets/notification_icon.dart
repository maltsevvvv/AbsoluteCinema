// ============================================================
//  lib/widgets/notification_icon.dart
// ============================================================

import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../styles/app_styles.dart';

class NotificationIcon extends StatefulWidget {
  final VoidCallback? onTap;
  const NotificationIcon({super.key, this.onTap});

  @override
  // FIX: State публичный (не _) чтобы GlobalKey мог вызвать refresh()
  State<NotificationIcon> createState() => NotificationIconState();
}

class NotificationIconState extends State<NotificationIcon> {
  final StorageService _storage = StorageService();

  int _pendingCount = 0;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  // FIX: публичный метод — вызывается из HomeScreen через GlobalKey
  // после того как кассир обработал заявку
  Future<void> refresh() async {
    final pending = await _storage.loadPendingBookings();
    if (!mounted) return;
    final newCount = pending.length;
    setState(() {
      _isBlinking = newCount > _pendingCount;
      _pendingCount = newCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _pendingCount > 0
          ? 'Новых заявок: $_pendingCount'
          : 'Нет новых заявок',
      onPressed: () {
        setState(() => _isBlinking = false);
        widget.onTap?.call();
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedOpacity(
            opacity: _isBlinking ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 600),
            child: Icon(
              _pendingCount > 0
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color:
                  _pendingCount > 0 ? AppStyles.accent : AppStyles.textPrimary,
            ),
          ),
          if (_pendingCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppStyles.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _pendingCount > 99 ? '99+' : '$_pendingCount',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
