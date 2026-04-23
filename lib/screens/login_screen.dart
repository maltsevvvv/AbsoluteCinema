// ============================================================
//  lib/screens/login_screen.dart
// ============================================================
//
//  Экран входа и регистрации.
//  Роль определяется автоматически по логину (пункт 8 + группа).
//  Использует Form + GlobalKey для валидации (как в методичке).
//
// ============================================================

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../styles/app_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();

  late TabController _tabController;

  // Ключи форм
  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  // Контроллеры полей
  final _loginLoginCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regLoginCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  String? _errorMsg;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _errorMsg = null);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginLoginCtrl.dispose();
    _loginPassCtrl.dispose();
    _regLoginCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  // ── Войти ─────────────────────────────────────────────────
  Future<void> _doLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final error = await _auth.login(
      _loginLoginCtrl.text,
      _loginPassCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ── Зарегистрироваться ─────────────────────────────────────
  Future<void> _doRegister() async {
    if (!_regFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final error = await _auth.register(
      _regLoginCtrl.text,
      _regPassCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppStyles.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Логотип
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppStyles.radiusL * 2),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('AbsoluteCinema', style: AppStyles.title),
                const SizedBox(height: 32),

                // Таб: Вход / Регистрация
                Container(
                  decoration: BoxDecoration(
                    color: AppStyles.surface,
                    borderRadius: BorderRadius.circular(AppStyles.radiusS),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    // Наш кастомный индикатор — синяя плашка
                    indicator: BoxDecoration(
                      color: AppStyles.primary,
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    // Убираем дефолтную линию снизу
                    indicatorColor: Colors.transparent,
                    dividerColor: Colors.transparent,
                    dividerHeight: 0,
                    // Убираем синий всплеск при нажатии
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    labelColor: AppStyles.textPrimary,
                    unselectedLabelColor: AppStyles.textSecond,
                    tabs: const [
                      Tab(text: 'Вход'),
                      Tab(text: 'Регистрация'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Формы
                SizedBox(
                  height: 220,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(),
                      _buildRegisterForm(),
                    ],
                  ),
                ),

                // Сообщение об ошибке
                if (_errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppStyles.paddingM),
                    decoration: BoxDecoration(
                      color: AppStyles.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppStyles.radiusS),
                      border: Border.all(color: AppStyles.error),
                    ),
                    child: Text(
                      _errorMsg!,
                      style:
                          AppStyles.subtitle.copyWith(color: AppStyles.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Форма входа ────────────────────────────────────────────
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginLoginCtrl,
            style: AppStyles.body,
            decoration: const InputDecoration(
              hintText: 'Логин',
              prefixIcon:
                  Icon(Icons.person_outline, color: AppStyles.textSecond),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Введите логин' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _loginPassCtrl,
            obscureText: true,
            style: AppStyles.body,
            decoration: const InputDecoration(
              hintText: 'Пароль',
              prefixIcon: Icon(Icons.lock_outline, color: AppStyles.textSecond),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Введите пароль' : null,
            onFieldSubmitted: (_) => _doLogin(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _doLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppStyles.textPrimary),
                    )
                  : const Text('Войти'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Форма регистрации ──────────────────────────────────────
  Widget _buildRegisterForm() {
    return Form(
      key: _regFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _regLoginCtrl,
            style: AppStyles.body,
            decoration: const InputDecoration(
              hintText: 'Логин',
              prefixIcon:
                  Icon(Icons.person_outline, color: AppStyles.textSecond),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Введите логин';
              if (v.trim().toLowerCase() == 'cashier') {
                return 'Этот логин зарезервирован';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regPassCtrl,
            obscureText: true,
            style: AppStyles.body,
            decoration: const InputDecoration(
              hintText: 'Пароль',
              prefixIcon: Icon(Icons.lock_outline, color: AppStyles.textSecond),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Введите пароль';
              if (v.trim().length < 3) return 'Минимум 3 символа';
              return null;
            },
            onFieldSubmitted: (_) => _doRegister(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _doRegister,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppStyles.textPrimary),
                    )
                  : const Text('Зарегистрироваться'),
            ),
          ),
        ],
      ),
    );
  }
}
