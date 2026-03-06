import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  final String eventId;

  const NowPlayingScreen({super.key, required this.eventId});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _eqController;

  @override
  void initState() {
    super.initState();
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _eqController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(votingProvider(widget.eventId));

    if (state.isLoading && state.event == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.event == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: Colors.white24),
              const SizedBox(height: 12),
              const Text('Sin conexión',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(votingProvider(widget.eventId).notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final event = state.event!;
    final eventTheme = AppTheme.eventThemeFor(event.eventType);

    final playedSongs = (event.songs ?? [])
        .where((s) => s.status == 'played')
        .toList()
      ..sort((a, b) => b.orderIndex.compareTo(a.orderIndex));

    final nowPlaying = playedSongs.isNotEmpty ? playedSongs.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          event.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: RefreshIndicator(
        color: eventTheme.accent,
        backgroundColor: AppTheme.darkCard,
        onRefresh: () =>
            ref.read(votingProvider(widget.eventId).notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                // Portada + gradiente superior
                _AlbumArtHero(
                  song: nowPlaying,
                  eventTheme: eventTheme,
                  eventEmoji: eventTheme.emoji,
                ),

                // Info de la canción
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Label + título + artista
                        Column(
                          children: [
                            Text(
                              'AHORA SUENA',
                              style: TextStyle(
                                color: eventTheme.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              nowPlaying?.title ?? '—',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              nowPlaying?.artist ?? '',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        // Visualizador EQ
                        if (nowPlaying != null)
                          _EqBars(
                            controller: _eqController,
                            color: eventTheme.accent,
                            neon: eventTheme.neon,
                          )
                        else
                          _NoSongState(theme: eventTheme),

                        // Info del evento (venue)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 14,
                                color:
                                    eventTheme.accent.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              event.venue,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Portada grande con gradiente ─────────────────────────────────────────────

class _AlbumArtHero extends StatelessWidget {
  final dynamic song;
  final EventThemeData eventTheme;
  final String eventEmoji;

  const _AlbumArtHero({
    required this.song,
    required this.eventTheme,
    required this.eventEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;
    final coverUrl = song?.coverUrl as String?;

    return SizedBox(
      width: double.infinity,
      height: size * 0.72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen o fondo degradado
          if (coverUrl != null)
            CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  _GradientPlaceholder(theme: eventTheme, emoji: eventEmoji),
            )
          else
            _GradientPlaceholder(theme: eventTheme, emoji: eventEmoji),

          // Overlay gradiente inferior para fundir
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.55, 1.0],
                  colors: [
                    Colors.transparent,
                    const Color(0xFF08080F).withValues(alpha: 0.3),
                    const Color(0xFF08080F),
                  ],
                ),
              ),
            ),
          ),

          // Overlay gradiente superior (detrás del AppBar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  final EventThemeData theme;
  final String emoji;

  const _GradientPlaceholder({required this.theme, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.accent.withValues(alpha: 0.6),
            theme.neon.withValues(alpha: 0.3),
            const Color(0xFF08080F),
          ],
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: 100,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}

// ─── Visualizador EQ animado ──────────────────────────────────────────────────

class _EqBars extends StatefulWidget {
  final AnimationController controller;
  final Color color;
  final Color neon;

  const _EqBars(
      {required this.controller, required this.color, required this.neon});

  @override
  State<_EqBars> createState() => _EqBarsState();
}

class _EqBarsState extends State<_EqBars> {
  static const _barCount = 28;
  final _rng = math.Random();
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _animations = List.generate(_barCount, (i) {
      final minH = 0.1 + _rng.nextDouble() * 0.2;
      final maxH = 0.4 + _rng.nextDouble() * 0.6;
      final curve = CurvedAnimation(
        parent: widget.controller,
        curve: Interval(
          (_rng.nextDouble() * 0.5).clamp(0.0, 0.5),
          (0.5 + _rng.nextDouble() * 0.5).clamp(0.5, 1.0),
          curve: Curves.easeInOut,
        ),
      );
      return Tween<double>(begin: minH, end: maxH).animate(curve);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        return SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_barCount, (i) {
              final h = (_animations[i].value * 60).clamp(4.0, 60.0);
              return Container(
                width: 4,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [widget.color, widget.neon],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ─── Sin canción reproduciendo ────────────────────────────────────────────────

class _NoSongState extends StatelessWidget {
  final EventThemeData theme;
  const _NoSongState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.hourglass_empty_rounded,
            size: 42, color: theme.accent.withValues(alpha: 0.3)),
        const SizedBox(height: 10),
        const Text(
          'Aún no hay canción en reproducción',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
