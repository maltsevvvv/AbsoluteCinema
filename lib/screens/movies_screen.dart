// ============================================================
//  lib/screens/movies_screen.dart
// ============================================================
//
//  Закрывает сразу несколько пунктов методички:
//    1  — ListView 40+ строк + переход в детали
//    2  — TMDB API используется в UI (FutureBuilder)
//    3  — AppBar с действиями (поиск)
//    4  — RadioButton (фильтр по жанру) + Checkbox (фильтр по рейтингу)
//   10  — CircularProgressIndicator при загрузке с API
//   11  — Подгрузка по 5 элементов (кнопка «Показать ещё»)
//
// ============================================================

import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../styles/app_styles.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final ApiService _api       = ApiService();
  final AuthService _auth     = AuthService();
  final StorageService _store = StorageService();

  // Все фильмы загруженные с API
  List<Movie> _allMovies = [];

  // Фильтрованный список (после применения фильтров)
  List<Movie> _filtered = [];

  // Сколько сейчас показываем (подгрузка по 5 — пункт 11)
  int _visibleCount = 5;
  static const int _step = 5;

  // Состояние загрузки
  bool _isLoading = true;
  String? _errorMsg;

  // ── Фильтры (пункт 4 методички) ───────────────────────────
  // RadioButton — фильтр по жанру
  MovieGenre? _selectedGenre; // null = все жанры

  // Checkbox — показывать только с рейтингом 7+
  bool _onlyHighRated = false;

  // Список избранных movieId текущего зрителя
  List<int> _favoriteIds = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _loadFavorites();
  }

  // ── Загрузка фильмов с API (пункт 2 и 10) ─────────────────
  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // ApiService сам решает — из кэша или с сети
      final movies = await _api.fetchMovies(pages: 2);

      if (movies.isEmpty) {
        setState(() {
          _errorMsg = 'Не удалось загрузить фильмы. Проверьте интернет.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _allMovies = movies;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMsg = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final ids = await _store.loadFavorites(_auth.userId);
    setState(() => _favoriteIds = ids);
  }

  // ── Применить фильтры ──────────────────────────────────────
  void _applyFilters() {
    setState(() {
      _filtered = _allMovies.where((m) {
        // Radio-фильтр по жанру
        if (_selectedGenre != null && m.genre != _selectedGenre) return false;
        // Checkbox-фильтр по рейтингу
        if (_onlyHighRated && m.rating < 7.0) return false;
        return true;
      }).toList();

      // Сбрасываем счётчик видимых при смене фильтра
      _visibleCount = _step;
    });
  }

  // ── Переключить избранное ──────────────────────────────────
  Future<void> _toggleFavorite(Movie movie) async {
    if (_favoriteIds.contains(movie.id)) {
      await _store.removeFavorite(_auth.userId, movie.id);
    } else {
      await _store.addFavorite(_auth.userId, movie.id);
    }
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── AppBar с кнопкой обновления ──────────────────────
      appBar: AppBar(
        title: const Text('Афиша'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () async {
              await _api.invalidateCache();
              await _loadMovies();
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Фильтры ─────────────────────────────────────
          _buildFilters(),

          // ── Список фильмов ───────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Блок фильтров (RadioButton + Checkbox, пункт 4) ───────
  Widget _buildFilters() {
    return Container(
      color: AppStyles.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingM, vertical: AppStyles.paddingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RadioButton — жанры
          const Text('Жанр:', style: AppStyles.caption),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // «Все» — null жанр
                Row(
                  children: [
                    Radio<MovieGenre?>(
                      value: null,
                      groupValue: _selectedGenre,
                      activeColor: AppStyles.accent,
                      onChanged: (v) {
                        setState(() => _selectedGenre = v);
                        _applyFilters();
                      },
                    ),
                    const Text('Все', style: AppStyles.subtitle),
                  ],
                ),
                // Конкретные жанры
                ...MovieGenre.values.map((genre) => Row(
                      children: [
                        Radio<MovieGenre?>(
                          value: genre,
                          groupValue: _selectedGenre,
                          activeColor: AppStyles.accent,
                          onChanged: (v) {
                            setState(() => _selectedGenre = v);
                            _applyFilters();
                          },
                        ),
                        Text(genre.label, style: AppStyles.subtitle),
                      ],
                    )),
              ],
            ),
          ),

          // Checkbox — рейтинг 7+
          Row(
            children: [
              Checkbox(
                value: _onlyHighRated,
                activeColor: AppStyles.accent,
                onChanged: (v) {
                  setState(() => _onlyHighRated = v ?? false);
                  _applyFilters();
                },
              ),
              const Text('Только рейтинг 7+', style: AppStyles.subtitle),
            ],
          ),
        ],
      ),
    );
  }

  // ── Тело экрана (состояния: загрузка / ошибка / список) ───
  Widget _buildBody() {
    // Состояние: идёт загрузка → CircularProgressIndicator (пункт 10)
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppStyles.accent),
            SizedBox(height: 16),
            Text('Загружаем фильмы...', style: AppStyles.subtitle),
          ],
        ),
      );
    }

    // Состояние: ошибка
    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppStyles.error, size: 48),
              const SizedBox(height: 12),
              Text(_errorMsg!, style: AppStyles.subtitle,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMovies,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    // Состояние: список пустой после фильтрации
    if (_filtered.isEmpty) {
      return const Center(
        child: Text('Нет фильмов по выбранным фильтрам',
            style: AppStyles.subtitle),
      );
    }

    // Сколько показываем сейчас
    final showCount = _visibleCount.clamp(0, _filtered.length);
    final visible   = _filtered.sublist(0, showCount);
    final hasMore   = showCount < _filtered.length;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      // +1 для кнопки «Показать ещё» если есть что показывать
      itemCount: visible.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Последний элемент — кнопка подгрузки (пункт 11)
        if (index == visible.length) {
          return Padding(
            padding: const EdgeInsets.all(AppStyles.paddingM),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.expand_more),
              label: Text(
                'Показать ещё '
                '(${_filtered.length - showCount} осталось)',
              ),
              onPressed: () {
                setState(() => _visibleCount += _step);
              },
            ),
          );
        }

        final movie = visible[index];
        final isFav = _favoriteIds.contains(movie.id);

        // MovieCard — отдельный виджет (widgets/movie_card.dart)
        return AnimatedMovieCard(
          index: index,
          movie: movie,
          isFavorite: isFav,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(movie: movie),
              ),
            );
            // Обновляем избранное после возврата
            await _loadFavorites();
          },
          onFavoriteTap: _auth.isViewer
              ? () => _toggleFavorite(movie)
              : null, // кассир не может добавлять в избранное
        );
      },
    );
  }
}
