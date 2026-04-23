// ============================================================
//  lib/models/movie.dart
// ============================================================

// ─── ENUM: жанр фильма ───────────────────────────────────────
// Используется для фильтрации (RadioButton в UI)
enum MovieGenre {
  action, // Боевик
  comedy, // Комедия
  drama, // Драма
  horror, // Ужасы
  animation, // Мультфильм
  scifi, // Фантастика
  other, // Прочее
}

extension MovieGenreLabel on MovieGenre {
  String get label {
    switch (this) {
      case MovieGenre.action:
        return 'Боевик';
      case MovieGenre.comedy:
        return 'Комедия';
      case MovieGenre.drama:
        return 'Драма';
      case MovieGenre.horror:
        return 'Ужасы';
      case MovieGenre.animation:
        return 'Мультфильм';
      case MovieGenre.scifi:
        return 'Фантастика';
      case MovieGenre.other:
        return 'Прочее';
    }
  }
}

// TMDB возвращает жанры как числовые ID.
// Маппинг используется в api_service.dart при парсинге ответа.
// Полный список: https://developer.themoviedb.org/reference/genre-movie-list
const Map<int, MovieGenre> tmdbGenreMap = {
  28: MovieGenre.action, // Action
  12: MovieGenre.action, // Adventure
  35: MovieGenre.comedy, // Comedy
  10749: MovieGenre.comedy, // Romance
  18: MovieGenre.drama, // Drama
  80: MovieGenre.drama, // Crime
  27: MovieGenre.horror, // Horror
  53: MovieGenre.horror, // Thriller
  16: MovieGenre.animation, // Animation
  878: MovieGenre.scifi, // Science Fiction
  14: MovieGenre.scifi, // Fantasy
};

// Берём первый подходящий жанр из списка ID, иначе other
MovieGenre genreFromTmdbIds(List<int> ids) {
  for (final id in ids) {
    final genre = tmdbGenreMap[id];
    if (genre != null) return genre;
  }
  return MovieGenre.other;
}

// ─── МОДЕЛЬ: Фильм ───────────────────────────────────────────
class Movie {
  final int id; // TMDB id — уникальный ключ
  final String title;
  final String description;
  final String posterUrl; // Полный URL постера (базовый TMDB + poster_path)
  final MovieGenre genre;
  final int year;
  final double rating; // vote_average из TMDB
  final int durationMinutes; // runtime — приходит из /movie/{id}
  bool isFavorite; // Локальное поле зрителя, хранится в SharedPreferences

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.genre,
    required this.year,
    required this.rating,
    required this.durationMinutes,
    this.isFavorite = false,
  });

  // ── Парсинг ответа TMDB ──────────────────────────────────
  // Вызывается в api_service.dart:
  //   List<Movie> movies = response['results']
  //       .map((e) => Movie.fromTmdb(e))
  //       .toList();
  factory Movie.fromTmdb(Map<String, dynamic> json) {
    // poster_path приходит как "/abc.jpg" — добавляем базовый URL
    final posterPath = json['poster_path'] as String? ?? '';
    final posterUrl = posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : '';

    // release_date приходит как "2014-11-05" — берём только год
    final releaseDate = json['release_date'] as String? ?? '';
    final year = releaseDate.length >= 4
        ? int.tryParse(releaseDate.substring(0, 4)) ?? 0
        : 0;

    // genre_ids — список int, маппим в наш enum
    final genreIds =
        (json['genre_ids'] as List?)?.map((e) => e as int).toList() ?? [];

    return Movie(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['overview'] ?? '',
      posterUrl: posterUrl,
      genre: genreFromTmdbIds(genreIds),
      year: year,
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['runtime'] ?? 0, // 0 пока нет детального запроса
    );
  }

  // ── Сериализация для кэша в SharedPreferences ─────────────
  // Фильмы из API не сохраняются постоянно,
  // но toJson/fromJson нужны для кэша загруженного списка
  // и для хранения isFavorite у зрителя.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'genre': genre.index, // enum → int
      'year': year,
      'rating': rating,
      'durationMinutes': durationMinutes,
      'isFavorite': isFavorite,
    };
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      posterUrl: json['posterUrl'],
      genre: MovieGenre.values[json['genre']], // int → enum
      year: json['year'],
      rating: (json['rating'] as num).toDouble(),
      durationMinutes: json['durationMinutes'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // Нужен при редактировании фильма кассиром
  Movie copyWith({
    String? title,
    String? description,
    String? posterUrl,
    MovieGenre? genre,
    int? year,
    double? rating,
    int? durationMinutes,
    bool? isFavorite,
  }) {
    return Movie(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      posterUrl: posterUrl ?? this.posterUrl,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
