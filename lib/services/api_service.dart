// ============================================================
//  lib/services/api_service.dart
// ============================================================
//
//  Работа с TMDB API. Паттерн как в методичке:
//    1. Uri.https() с параметрами
//    2. http.get()
//    3. try/catch + проверка statusCode
//    4. jsonDecode → Map
//    5. Маппинг в модель Movie
//
//  Добавь в pubspec.yaml:
//    dependencies:
//      http: ^1.2.0
//
// ============================================================
//  lib/services/api_service.dart
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/movie.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storage = StorageService();

  // ── fetchMovies ───────────────────────────────────────────
  Future<List<Movie>> fetchMovies({int pages = 2}) async {
    final cached = await _storage.loadMoviesCache();
    if (cached.isNotEmpty) return cached;

    try {
      final futures = List.generate(pages, (i) => _fetchPage(i + 1));

      final results = await Future.wait(futures);

      final seen = <int>{};
      final unique = results
          .expand((list) => list)
          .where((m) => seen.add(m.id))
          .toList();

      await _storage.saveMoviesCache(unique);

      // FIX: после первой загрузки фильмов создаём демо-сеансы
      // с реальными TMDB movieId (иначе сеансы не совпадут с фильмами)
      await _storage.seedSessionsFromCache();

      return unique;
    } catch (e) {
      print('>>> fetchMovies ошибка: $e');
      return [];
    }
  }

  // ── _fetchPage ───────────────────────────────────────────
  Future<List<Movie>> _fetchPage(int page) async {
    final uri = Uri.https(AppConfig.tmdbHost, '/3/movie/popular', {
      'api_key': AppConfig.tmdbApiKey,
      'language': AppConfig.tmdbLang,
      'page': page.toString(),
    });

    print('>>> Запрос: $uri');

    try {
      final response = await http.get(uri);

      print('>>> Статус: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('>>> HTTP ошибка: ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];

      final List<Movie> movies = [];

      for (final e in results) {
        try {
          movies.add(Movie.fromTmdb(e));
        } catch (err) {
          print('>>> Ошибка парсинга фильма: $err');
        }
      }

      return movies;
    } catch (e) {
      print('>>> Ошибка сети: $e');
      return [];
    }
  }

  // ── fetchMovieDetails ─────────────────────────────────────
  Future<Movie?> fetchMovieDetails(int movieId) async {
    try {
      final uri = Uri.https(AppConfig.tmdbHost, '/3/movie/$movieId', {
        'api_key': AppConfig.tmdbApiKey,
        'language': AppConfig.tmdbLang,
      });

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print('>>> Ошибка деталей: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      return Movie.fromTmdb(data);
    } catch (e) {
      print('>>> fetchMovieDetails ошибка: $e');
      return null;
    }
  }

  // ── searchMovies ─────────────────────────────────────────
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.https(AppConfig.tmdbHost, '/3/search/movie', {
        'api_key': AppConfig.tmdbApiKey,
        'language': AppConfig.tmdbLang,
        'query': query.trim(),
        'page': '1',
      });

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print('>>> Ошибка поиска: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];

      final List<Movie> movies = [];

      for (final e in results) {
        try {
          movies.add(Movie.fromTmdb(e));
        } catch (err) {
          print('>>> Ошибка парсинга поиска: $err');
        }
      }

      return movies;
    } catch (e) {
      print('>>> searchMovies ошибка: $e');
      return [];
    }
  }

  // ── invalidateCache ──────────────────────────────────────
  Future<void> invalidateCache() async {
    await _storage.saveMoviesCache([]);
  }
}
