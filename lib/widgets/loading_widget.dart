// ============================================================
//  lib/widgets/loading_widget.dart
// ============================================================
//
//  Универсальный виджет состояния загрузки.
//  Используется на всех экранах вместо прямого
//  CircularProgressIndicator — единообразный стиль.
//
// ============================================================

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({
    super.key,
    this.message = 'Загрузка...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppStyles.accent,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(message, style: AppStyles.subtitle),
        ],
      ),
    );
  }
}

// ── Виджет ошибки ─────────────────────────────────────────────
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppStyles.error, size: 56),
            const SizedBox(height: 12),
            Text(message,
                style: AppStyles.subtitle,
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Виджет пустого списка ─────────────────────────────────────
class EmptyWidget extends StatelessWidget {
  final IconData icon;
  final String   message;
  final String?  subtitle;

  const EmptyWidget({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppStyles.textSecond),
          const SizedBox(height: 16),
          Text(message, style: AppStyles.subtitle),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!,
                style: AppStyles.caption,
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
