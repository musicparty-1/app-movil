import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song_model.dart';
import '../providers/providers.dart';
import '../theme.dart';

// ─── Modos de ranking ──────────────────────────────────────────────────────────

enum _RankMode { topPicks, mostVoted, trending }

extension _RankModeLabel on _RankMode {
  String get label {
    switch (this) {
      case _RankMode.topPicks:
        return 'TOP PICKS';
      case _RankMode.mostVoted:
        return 'MÁS VOTADAS';
      case _RankMode.trending:
        return 'EN ALZA';
    }
  }
}

// ─── Pantalla ──────────────────────────────────────────────────────────────────

class RankingScreen extends ConsumerStatefulWidget {
  final String eventId;

  const RankingScreen({super.key, required this.eventId});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _RankMode.values.length, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(votingProvider(widget.eventId));

    if (state.isLoading && state.event == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
    final allSongs = event.songs ?? <SongModel>[];

    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          _RankingAppBar(
            event: event,
            eventTheme: eventTheme,
            tab: _tab,
            innerBoxScrolled: innerBoxScrolled,
          ),
        ],
        body: RefreshIndicator(
          color: eventTheme.accent,
          backgroundColor: AppTheme.darkCard,
          onRefresh: () =>
              ref.read(votingProvider(widget.eventId).notifier).refresh(),
          child: TabBarView(
            controller: _tab,
            children: [
              _RankList(
                songs: _topPicks(allSongs),
                eventTheme: eventTheme,
                mode: _RankMode.topPicks,
              ),
              _RankList(
                songs: _mostVoted(allSongs),
                eventTheme: eventTheme,
                mode: _RankMode.mostVoted,
              ),
              _RankList(
                songs: _trending(allSongs),
                eventTheme: eventTheme,
                mode: _RankMode.trending,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Algoritmos de ordenación ────────────────────────────────────────────────

  /// Top Picks: pendientes primero (más votos), luego played
  List<SongModel> _topPicks(List<SongModel> songs) {
    final pending = songs.where((s) => s.status == 'pending').toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    final played = songs.where((s) => s.status == 'played').toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    return [...pending, ...played];
  }

  /// Más Votadas: todas ordenadas por votos desc
  List<SongModel> _mostVoted(List<SongModel> songs) {
    final sorted = List<SongModel>.from(songs)
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    return sorted;
  }

  /// En Alza: pendientes con más votos por minuto de vida
  /// (voteCount / minutos_desde_creación) — approximación de velocidad
  List<SongModel> _trending(List<SongModel> songs) {
    final now = DateTime.now();
    final pending = songs.where((s) => s.status == 'pending').toList();
    pending.sort((a, b) {
      final minA = now.difference(a.createdAt).inMinutes.clamp(1, 99999);
      final minB = now.difference(b.createdAt).inMinutes.clamp(1, 99999);
      final rateA = a.voteCount / minA;
      final rateB = b.voteCount / minB;
      return rateB.compareTo(rateA);
    });
    return pending;
  }
}

// ─── SliverAppBar con header + TabBar ─────────────────────────────────────────

class _RankingAppBar extends StatelessWidget {
  final dynamic event;
  final EventThemeData eventTheme;
  final TabController tab;
  final bool innerBoxScrolled;

  const _RankingAppBar({
    required this.event,
    required this.eventTheme,
    required this.tab,
    required this.innerBoxScrolled,
  });

  @override
  Widget build(BuildContext context) {
    return SliverOverlapAbsorber(
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
      sliver: SliverAppBar(
        backgroundColor: const Color(0xFF08080F),
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(),
        pinned: true,
        floating: false,
        expandedHeight: 130,
        forceElevated: innerBoxScrolled,
        shadowColor: Colors.black54,
        flexibleSpace: FlexibleSpaceBar(
          collapseMode: CollapseMode.pin,
          background: _HeaderContent(event: event, eventTheme: eventTheme),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _TabRow(tab: tab, eventTheme: eventTheme),
        ),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  final dynamic event;
  final EventThemeData eventTheme;

  const _HeaderContent({required this.event, required this.eventTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'event-name-${event.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      event.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 12,
                        color: eventTheme.accent.withValues(alpha: 0.8)),
                    const SizedBox(width: 3),
                    Text(
                      event.venue,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Badge de ranking
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [eventTheme.accent, eventTheme.neon],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: eventTheme.accent.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                eventTheme.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  final TabController tab;
  final EventThemeData eventTheme;

  const _TabRow({required this.tab, required this.eventTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
      ),
      child: TabBar(
        controller: tab,
        indicatorColor: eventTheme.accent,
        indicatorWeight: 2.5,
        labelColor: eventTheme.accent,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
        tabs: _RankMode.values.map((m) => Tab(text: m.label)).toList(),
      ),
    );
  }
}

// ─── Lista de ranking ──────────────────────────────────────────────────────────

class _RankList extends StatelessWidget {
  final List<SongModel> songs;
  final EventThemeData eventTheme;
  final _RankMode mode;

  const _RankList({
    required this.songs,
    required this.eventTheme,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 52, color: eventTheme.accent.withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            const Text(
              'Sin canciones todavía',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Builder(
      builder: (context) => CustomScrollView(
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _RankRow(
                  song: songs[i],
                  position: i + 1,
                  eventTheme: eventTheme,
                  showTrend: mode == _RankMode.trending,
                  isTop3: i < 3,
                ),
                childCount: songs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fila individual del ranking ───────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  final SongModel song;
  final int position;
  final EventThemeData eventTheme;
  final bool showTrend;
  final bool isTop3;

  const _RankRow({
    required this.song,
    required this.position,
    required this.eventTheme,
    required this.showTrend,
    required this.isTop3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isTop3
            ? eventTheme.accent.withValues(alpha: 0.07)
            : const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Posición
              SizedBox(
                width: 34,
                child: _PositionWidget(position: position, theme: eventTheme),
              ),
              const SizedBox(width: 10),

              // Portada
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: song.coverUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _Cover(theme: eventTheme),
                      )
                    : _Cover(theme: eventTheme),
              ),
              const SizedBox(width: 12),

              // Título + artista
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        color: isTop3 ? Colors.white : Colors.white,
                        fontSize: 13,
                        fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Métricas
              _MetricChip(
                song: song,
                theme: eventTheme,
                showTrend: showTrend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PositionWidget extends StatelessWidget {
  final int position;
  final EventThemeData theme;

  const _PositionWidget({required this.position, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (position == 1) {
      return const Text('🥇',
          style: TextStyle(fontSize: 22), textAlign: TextAlign.center);
    }
    if (position == 2) {
      return const Text('🥈',
          style: TextStyle(fontSize: 22), textAlign: TextAlign.center);
    }
    if (position == 3) {
      return const Text('🥉',
          style: TextStyle(fontSize: 22), textAlign: TextAlign.center);
    }
    return Text(
      '#$position',
      style: TextStyle(
        color: AppTheme.textSecondary.withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _Cover extends StatelessWidget {
  final EventThemeData theme;
  const _Cover({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: theme.accent.withValues(alpha: 0.15),
      child: Icon(Icons.music_note_rounded,
          color: theme.accent.withValues(alpha: 0.5), size: 22),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final SongModel song;
  final EventThemeData theme;
  final bool showTrend;

  const _MetricChip({
    required this.song,
    required this.theme,
    required this.showTrend,
  });

  String _format(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final isPlayed = song.status == 'played';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Votos principales
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showTrend ? Icons.trending_up_rounded : Icons.favorite_rounded,
              size: 13,
              color: showTrend ? AppTheme.neonCyan : theme.accent,
            ),
            const SizedBox(width: 3),
            Text(
              _format(song.voteCount),
              style: TextStyle(
                color: showTrend ? AppTheme.neonCyan : theme.accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        // Badge estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isPlayed
                ? Colors.white.withValues(alpha: 0.08)
                : theme.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isPlayed ? 'SONÓ' : 'EN COLA',
            style: TextStyle(
              color: isPlayed ? AppTheme.textSecondary : theme.accent,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
