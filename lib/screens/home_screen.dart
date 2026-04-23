// ============================================================
//  lib/screens/home_screen.dart
// ============================================================

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../styles/app_styles.dart';
import 'movies_screen.dart';
import 'my_tickets_screen.dart';
import 'favorites_screen.dart';
import 'admin_requests_screen.dart';
import 'admin_sessions_screen.dart';
import '../widgets/notification_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();

  // GlobalKey нужен чтобы вызывать refresh() на колокольчике извне
  final GlobalKey<NotificationIconState> _notifKey =
      GlobalKey<NotificationIconState>();

  int _selectedIndex = 0;

  final List<Widget> _viewerScreens = const [
    MoviesScreen(),
    MyTicketsScreen(),
    FavoritesScreen(),
  ];

  // FIX: кассирские экраны с callback для обновления колокольчика
  List<Widget> get _cashierScreens => [
        const MoviesScreen(),
        AdminRequestsScreen(onBookingHandled: _refreshNotifications),
        const AdminSessionsScreen(),
      ];

  List<Widget> get _screens =>
      _auth.isCashier ? _cashierScreens : _viewerScreens;

  void _refreshNotifications() {
    _notifKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.primary,
        title: const Text('AbsoluteCinema'),

        // FIX: явная кнопка открытия Drawer
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Меню',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),

        actions: [
          if (_auth.isCashier)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: NotificationIcon(
                key: _notifKey,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
            ),
        ],
      ),
      body: _screens[_selectedIndex],
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
              ),
              accountName: Text(_auth.displayName, style: AppStyles.title),
              accountEmail: Text(_auth.roleLabel, style: AppStyles.subtitle),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppStyles.primary,
                child: Text(
                  _auth.displayName.isNotEmpty
                      ? _auth.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            if (!_auth.isCashier) ...[
              _drawerItem(icon: Icons.movie_outlined, label: 'Афиша', index: 0),
              _drawerItem(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Мои билеты',
                  index: 1),
              _drawerItem(
                  icon: Icons.favorite_outline, label: 'Избранное', index: 2),
            ],

            if (_auth.isCashier) ...[
              _drawerItem(icon: Icons.movie_outlined, label: 'Афиша', index: 0),
              _drawerItem(
                  icon: Icons.inbox_outlined, label: 'Заявки', index: 1),
              _drawerItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Сеансы',
                  index: 2),
            ],

            const Divider(),

            // FIX: диалог подтверждения выхода
            ListTile(
              leading: const Icon(Icons.logout, color: AppStyles.error),
              title: const Text('Сменить аккаунт / Выйти',
                  style: TextStyle(color: AppStyles.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppStyles.surface,
                    title: const Text('Выход'),
                    content: const Text(
                        'Выйти из аккаунта и вернуться к экрану входа?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Выйти'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _auth.logout();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? AppStyles.accent : AppStyles.textSecond),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppStyles.accent : AppStyles.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppStyles.primary.withValues(alpha: 0.15),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
        if (index == 1 && _auth.isCashier) _refreshNotifications();
      },
    );
  }
}
