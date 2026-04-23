// ============================================================
//  lib/main.dart
// ============================================================
//
//  Точка входа приложения.
//
//  Порядок инициализации:
//    1. WidgetsFlutterBinding.ensureInitialized()  — обязательно перед await
//    2. StorageService().init()                    — SharedPreferences + seed
//    3. AuthService().restoreSession()             — восстановление сессии
//    4. runApp(MyApp())
//
// ============================================================

import 'package:flutter/material.dart';

import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'styles/app_styles.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Шаг 1: обязательно перед любым await в main()
  WidgetsFlutterBinding.ensureInitialized();

  // Шаг 2: инициализируем SharedPreferences + засеиваем данные
  await StorageService().init();

  // Шаг 3: восстанавливаем сессию если пользователь уже входил
  await AuthService().restoreSession();

  // Шаг 4: запускаем приложение
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AbsoluteCinema',
      debugShowCheckedModeBanner: false,

      // Тема из AppStyles (пункт 5 методички)
      theme: AppStyles.theme,

      // Splash — первый экран (групповое задание)
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
