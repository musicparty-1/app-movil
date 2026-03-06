import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song_model.dart';
import '../providers/providers.dart';
import '../screens/now_playing_screen.dart';
import '../screens/ranking_screen.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/skeleton_loader.dart';

class VotingScreen extends ConsumerStatefulWidget {
  final String eventId;

  const VotingScreen({super.key, required this.eventId});

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(votingProvider(widget.eventId));
    final votedMap = ref.watch(votedSongsMapProvider);
    final votedSet = votedMap[widget.eventId] ?? const {};

    // Carga inicial
    if (state.isLoading && state.event == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: 6,
          itemBuilder: (_, __) => const SkeletonSongTile(),
        ),
      );
    }

    // Error sin datos previos
    if (state.error != null && state.event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 52, color: Colors.white24),
                const SizedBox(height: 14),
                const Text(
                  'No se pudo cargar el evento',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '(${state.error})',
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(votingProvider(widget.eventId).notifier)
                      .refresh(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final event = state.event!;
    final eventTheme = AppTheme.eventThemeFor(event.eventType);

    // Evento finalizado
    if (event.status != 'live') {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(eventTheme.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              const Text(
                'Este evento ha terminado',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(event.name,
                  style: TextStyle(color: eventTheme.accent, fontSize: 16)),
              const SizedBox(height: 6),
              Text(event.venue,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: eventTheme.accent),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Volver a eventos'),
              ),
            ],
          ),
        ),
      );
    }

    final pendingSongs = (event.songs ?? <SongModel>[])
        .where((s) => s.status == 'pending')
        .toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    final playedSongs = (event.songs ?? <SongModel>[])
        .where((s) => s.status == 'played')
        .toList()
      ..sort((a, b) => b.orderIndex.compareTo(a.orderIndex));

    final nowPlaying = playedSongs.isNotEmpty ? playedSongs.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      bottomNavigationBar: _EventBottomNav(
        eventId: widget.eventId,
        accent: eventTheme.accent,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, size: 22),
            tooltip: 'Ranking',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RankingScreen(eventId: widget.eventId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'Copiar ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: event.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ID copiado: ${event.id.substring(0, 8)}...'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        color: eventTheme.accent,
        backgroundColor: AppTheme.darkCard,
        onRefresh: () =>
            ref.read(votingProvider(widget.eventId).notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // Banner del evento
            SliverToBoxAdapter(
              child: _EventBanner(
                event: event,
                eventTheme: eventTheme,
              ),
            ),

            // Sonando ahora (tappable → U3)
            if (nowPlaying != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NowPlayingScreen(eventId: widget.eventId),
                      ),
                    ),
                    child:
                        _NowPlayingBanner(song: nowPlaying, theme: eventTheme),
                  ),
                ),
              ),

            // Cabecera de sección
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    const Text(
                      'Elegir tus favoritas:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: eventTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: eventTheme.accent.withValues(alpha: 0.35),
                            width: 0.8),
                      ),
                      child: Text(
                        '${pendingSongs.length} canciones',
                        style: TextStyle(
                          color: eventTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de canciones o empty state
            if (pendingSongs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.queue_music_rounded,
                          size: 56,
                          color: eventTheme.accent.withValues(alpha: 0.2)),
                      const SizedBox(height: 14),
                      const Text(
                        'No hay canciones todavía',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final song = pendingSongs[i];
                      final isVoted = votedSet.contains(song.id);
                      return _U2SongRow(
                        key: ValueKey(song.id),
                        song: song,
                        isVoted: isVoted,
                        eventTheme: eventTheme,
                        onVote: () => _vote(song),
                      );
                    },
                    childCount: pendingSongs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _vote(SongModel song) async {
    final deviceId = await ref.read(deviceIdProvider.future);
    try {
      await ref.read(apiServiceProvider).vote(
            songId: song.id,
            eventId: widget.eventId,
            deviceId: deviceId,
          );
      _markVoted(song.id);
      ref.read(votingProvider(widget.eventId).notifier).incrementVote(song.id);
    } on DioException catch (e) {
      final is409 = e.response?.statusCode == 409;
      if (is409) _markVoted(song.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                is409 ? 'Ya votaste por esta canción' : dioErrorToMessage(e)),
            backgroundColor: is409
                ? AppTheme.neonPurple.withValues(alpha: 0.9)
                : AppTheme.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _markVoted(String songId) {
    ref.read(votedSongsMapProvider.notifier).update((state) {
      final copy = Map<String, Set<String>>.from(state);
      copy[widget.eventId] = {...(copy[widget.eventId] ?? {}), songId};
      return copy;
    });
  }
}

// ─── Banner del evento ─────────────────────────────────────────────────────────

class _EventBanner extends StatelessWidget {
  final dynamic event;
  final EventThemeData eventTheme;

  const _EventBanner({required this.event, required this.eventTheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  eventTheme.accent.withValues(alpha: 0.45),
                  eventTheme.neon.withValues(alpha: 0.15),
                  const Color(0xFF08080F),
                ],
              ),
            ),
          ),
          // Emoji watermark
          Positioned(
            right: -10,
            top: -10,
            child: Text(
              eventTheme.emoji,
              style: TextStyle(
                fontSize: 140,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Contenido
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'event-name-${event.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      event.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 13,
                        color: eventTheme.accent.withValues(alpha: 0.9)),
                    const SizedBox(width: 3),
                    Text(
                      event.venue,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fila de canción U2 ────────────────────────────────────────────────────────

class _U2SongRow extends StatelessWidget {
  final SongModel song;
  final bool isVoted;
  final EventThemeData eventTheme;
  final VoidCallback onVote;

  const _U2SongRow({
    super.key,
    required this.song,
    required this.isVoted,
    required this.eventTheme,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isVoted ? null : onVote,
          borderRadius: BorderRadius.circular(14),
          splashColor: eventTheme.accent.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Portada
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: song.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: song.coverUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _CoverPlaceholder(theme: eventTheme),
                        )
                      : _CoverPlaceholder(theme: eventTheme),
                ),
                const SizedBox(width: 12),
                // Título + artista
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        song.artist,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Votos + botón
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (song.voteCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '${song.voteCount} voto${song.voteCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: eventTheme.accent.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _VoteButton(
                      isVoted: isVoted,
                      accent: eventTheme.accent,
                      neon: eventTheme.neon,
                      onTap: onVote,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final EventThemeData theme;
  const _CoverPlaceholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      color: theme.accent.withValues(alpha: 0.15),
      child: Icon(Icons.music_note_rounded,
          color: theme.accent.withValues(alpha: 0.6), size: 26),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final bool isVoted;
  final Color accent;
  final Color neon;
  final VoidCallback onTap;

  const _VoteButton({
    required this.isVoted,
    required this.accent,
    required this.neon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isVoted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: accent, size: 14),
            const SizedBox(width: 4),
            Text(
              'VOTADO',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent, neon]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_rounded, color: Colors.white, size: 13),
            SizedBox(width: 5),
            Text(
              'VOTAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sonando Ahora ─────────────────────────────────────────────────────────────

class _NowPlayingBanner extends StatelessWidget {
  final SongModel song;
  final EventThemeData theme;

  const _NowPlayingBanner({required this.song, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.accent.withValues(alpha: 0.25),
            theme.neon.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.music_note_rounded, color: theme.accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SONANDO AHORA',
                  style: TextStyle(
                    color: theme.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  song.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.graphic_eq_rounded, color: theme.accent, size: 22),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  color: theme.accent.withValues(alpha: 0.6), size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Barra de navegación del evento ───────────────────────────────────────────

class _EventBottomNav extends StatelessWidget {
  final String eventId;
  final Color accent;

  const _EventBottomNav({required this.eventId, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E1A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.music_note_rounded,
                label: 'Canciones',
                selected: true,
                accent: accent,
                onTap: () {}, // ya estamos aquí
              ),
              _NavItem(
                icon: Icons.graphic_eq_rounded,
                label: 'Sonando',
                selected: false,
                accent: accent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NowPlayingScreen(eventId: eventId),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: 'Ranking',
                selected: false,
                accent: accent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RankingScreen(eventId: eventId),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : AppTheme.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withValues(alpha: 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 18 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
