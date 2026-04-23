// ============================================================
//  lib/screens/splash_screen.dart
// ============================================================
//
//  Приветственный экран с анимацией при старте приложения.
//  Групповое задание: анимация при входе.
//
//  Логика:
//    1. Показываем анимацию (fade + scale)
//    2. Восстанавливаем сессию через AuthService
//    3. Если пользователь залогинен → HomeScreen
//       Если нет → LoginScreen
//
// ============================================================

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../styles/app_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Запускаем анимацию, затем переходим на нужный экран
    _controller.forward().then((_) => _navigate());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    // Восстанавливаем сессию
    await AuthService().restoreSession();

    if (!mounted) return;

    final isLoggedIn = AuthService().isLoggedIn;

    // Небольшая пауза чтобы анимация была заметна
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      isLoggedIn ? '/home' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Иконка приложения
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppStyles.radiusL * 2),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'AbsoluteCinema',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.textPrimary,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Билеты онлайн — быстро и удобно',
                  style: AppStyles.subtitle,
                ),

                const SizedBox(height: 48),

                const CircularProgressIndicator(
                  color: AppStyles.accent,
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
