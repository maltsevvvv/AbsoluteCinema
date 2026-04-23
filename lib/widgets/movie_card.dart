// ============================================================
//  lib/widgets/movie_card.dart
// ============================================================
//
//  Анимации:
//    1. Hero-анимация постера (tag: 'poster_${movie.id}')
//    2. Shimmer-эффект загрузки постера
//    3. Slide+Fade появление карточки при скролле (AnimatedMovieCard)
//    4. Анимация звёздочки избранного (ScaleTransition)
//
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../styles/app_styles.dart';

// ── Shimmer виджет ────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  const _Shimmer({required this.width, required this.height});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFF1A1A1A),
              Color(0xFF2A2A2A),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Карточка с анимацией появления (slide + fade) ────────────
class AnimatedMovieCard extends StatefulWidget {
  final Movie movie;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final int index;

  const AnimatedMovieCard({
    super.key,
    required this.movie,
    required this.isFavorite,
    required this.onTap,
    required this.index,
    this.onFavoriteTap,
  });

  @override
  State<AnimatedMovieCard> createState() => _AnimatedMovieCardState();
}

class _AnimatedMovieCardState extends State<AnimatedMovieCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 300));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: MovieCard(
          movie: widget.movie,
          isFavorite: widget.isFavorite,
          onTap: widget.onTap,
          onFavoriteTap: widget.onFavoriteTap,
        ),
      ),
    );
  }
}

// ── Основная карточка ─────────────────────────────────────────
class MovieCard extends StatelessWidget {
  final Movie movie;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;

  const MovieCard({
    super.key,
    required this.movie,
    required this.isFavorite,
    required this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppStyles.paddingM,
        vertical: AppStyles.paddingS / 2,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppStyles.radiusM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingS),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero-постер ──────────────────────────────
              Hero(
                tag: 'poster_${movie.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppStyles.radiusS),
                  child: _buildPoster(),
                ),
              ),

              const SizedBox(width: AppStyles.paddingM),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: AppStyles.title.copyWith(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(movie.genre.label, style: AppStyles.caption),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: AppStyles.accent, size: 14),
                        const SizedBox(width: 4),
                        Text(movie.rating.toStringAsFixed(1),
                            style: AppStyles.caption),
                        const SizedBox(width: 12),
                        Text(movie.year.toString(),
                            style: AppStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.description,
                      style: AppStyles.subtitle.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── Звёздочка с анимацией ────────────────────
              if (onFavoriteTap != null)
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      key: ValueKey(isFavorite),
                      color: isFavorite
                          ? AppStyles.accent
                          : AppStyles.textSecond,
                    ),
                  ),
                  onPressed: onFavoriteTap,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (movie.posterUrl.isEmpty) return _placeholder();
    return Image.network(
      movie.posterUrl,
      width: AppStyles.posterW,
      height: AppStyles.posterH,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _Shimmer(
            width: AppStyles.posterW, height: AppStyles.posterH);
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: AppStyles.posterW,
        height: AppStyles.posterH,
        color: AppStyles.surface,
        child: const Icon(Icons.movie,
            color: AppStyles.textSecond, size: 32),
      );
}
