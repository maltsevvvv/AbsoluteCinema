// ============================================================
//  lib/screens/favorites_screen.dart
// ============================================================
//
//  Экран «Избранное» для зрителя.
//  Загружает список movieId из SharedPreferences и отображает
//  соответствующие фильмы.
//  Пункт 7 методички: дополнительная опция для элементов списка
//  (добавить/убрать из избранного + отдельный экран).
//
// ============================================================

import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../styles/app_styles.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final AuthService    _auth    = AuthService();
  final StorageService _storage = StorageService();

  List<Movie> _favorites = [];
  bool        _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    // Загружаем ID избранных и все фильмы из кэша
    final ids    = await _storage.loadFavorites(_auth.userId);
    final movies = await _storage.loadMoviesCache();

    setState(() {
      // Берём только те фильмы, чьи ID есть в избранном
      _favorites = movies.where((m) => ids.contains(m.id)).toList();
      _isLoading = false;
    });
  }

  // Убрать фильм из избранного
  Future<void> _removeFavorite(Movie movie) async {
    await _storage.removeFavorite(_auth.userId, movie.id);
    await _loadFavorites();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('«${movie.title}» убран из избранного'),
        action: SnackBarAction(
          label: 'Отмена',
          onPressed: () async {
            // Возможность восстановить (пункт 7 методички)
            await _storage.addFavorite(_auth.userId, movie.id);
            await _loadFavorites();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Избранное${_favorites.isNotEmpty ? ' (${_favorites.length})' : ''}',
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppStyles.accent))
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_outline,
                          size: 64, color: AppStyles.textSecond),
                      const SizedBox(height: 16),
                      const Text('Нет избранных фильмов',
                          style: AppStyles.subtitle),
                      const SizedBox(height: 8),
                      const Text(
                        'Нажмите ★ на карточке фильма, чтобы добавить',
                        style: AppStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppStyles.accent,
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppStyles.paddingS),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final movie = _favorites[index];
                      return MovieCard(
                        movie:      movie,
                        isFavorite: true,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MovieDetailScreen(movie: movie),
                            ),
                          );
                          await _loadFavorites();
                        },
                        // Кнопка убрать из избранного
                        onFavoriteTap: () => _removeFavorite(movie),
                      );
                    },
                  ),
                ),
    );
  }
}
