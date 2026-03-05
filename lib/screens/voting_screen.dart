import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song_model.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/song_tile.dart';
import '../widgets/suggest_song_sheet.dart';

class VotingScreen extends ConsumerStatefulWidget {
  final String eventId;

  const VotingScreen({super.key, required this.eventId});

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(votingProvider(widget.eventId));
    final votedMap = ref.watch(votedSongsMapProvider);
    final votedSet = votedMap[widget.eventId] ?? const {};

    // Carga inicial
    if (state.isLoading && state.event == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Cargando evento...'),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
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
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '(${state.error})',
                  style:
                      const TextStyle(color: Colors.white24, fontSize: 11),
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
              Text(eventTheme.emoji,
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              const Text(
                'Este evento ha terminado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.name,
                style: TextStyle(color: eventTheme.accent, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                event.venue,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
              ),
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

    // Canciones pendientes ordenadas por votos (desc)
    final pendingSongs = (event.songs ?? <SongModel>[])
        .where((s) => s.status == 'pending')
        .toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    // Canciones ya reproducidas
    final playedSongs = (event.songs ?? <SongModel>[])
        .where((s) => s.status == 'played')
        .toList()
      ..sort((a, b) => b.orderIndex.compareTo(a.orderIndex));

    // Canciones votadas por el usuario
    final myVotedSongs = (event.songs ?? <SongModel>[])
        .where((s) => votedSet.contains(s.id))
        .toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    final nowPlaying =
        playedSongs.isNotEmpty ? playedSongs.first : null;
    final topVotes =
        pendingSongs.isNotEmpty ? pendingSongs.first.voteCount : 1;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'event-name-${widget.eventId}',
              flightShuttleBuilder: (_, anim, __, ___, ____) =>
                  FadeTransition(
                opacity: anim,
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    event.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Text(
                  event.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Text(
              event.venue,
              style: TextStyle(
                color: eventTheme.accent.withValues(alpha: 0.85),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'Copiar ID del evento',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: event.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('ID copiado: ${event.id.substring(0, 8)}...'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              visualDensity: VisualDensity.compact,
              backgroundColor:
                  eventTheme.accent.withValues(alpha: 0.15),
              side: BorderSide(color: eventTheme.accent, width: 0.5),
              label: Text(
                '${pendingSongs.length} canciones',
                style: TextStyle(
                  color: eventTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: eventTheme.accent,
          labelColor: eventTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          tabs: [
            const Tab(text: 'COLA'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('MIS VOTOS'),
                  if (myVotedSongs.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: eventTheme.accent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${myVotedSongs.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _QueueTab(
            pendingSongs: pendingSongs,
            nowPlaying: nowPlaying,
            votedSet: votedSet,
            topVotes: topVotes,
            eventTheme: eventTheme,
            allowSuggestions: event.allowAudienceSuggestions,
            onVote: _vote,
            onRefresh: () =>
                ref.read(votingProvider(widget.eventId).notifier).refresh(),
          ),
          _MyVotesTab(
            votedSongs: myVotedSongs,
            topVotes: topVotes,
            eventTheme: eventTheme,
            onVote: _vote,
          ),
        ],
      ),
      floatingActionButton: event.allowAudienceSuggestions
          ? FloatingActionButton.extended(
              onPressed: _openSuggestSheet,
              backgroundColor: eventTheme.accent,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Sugerir canción',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
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
    } on DioException catch (e) {
      final is409 = e.response?.statusCode == 409;
      if (is409) _markVoted(song.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(is409
                ? 'Ya votaste por esta canción'
                : dioErrorToMessage(e)),
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

  void _openSuggestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SuggestSongSheet(eventId: widget.eventId),
    );
  }
}

// Cola de canciones pendientes
class _QueueTab extends StatelessWidget {
  final List<SongModel> pendingSongs;
  final SongModel? nowPlaying;
  final Set<String> votedSet;
  final int topVotes;
  final EventThemeData eventTheme;
  final bool allowSuggestions;
  final Future<void> Function(SongModel) onVote;
  final Future<void> Function() onRefresh;

  const _QueueTab({
    required this.pendingSongs,
    required this.nowPlaying,
    required this.votedSet,
    required this.topVotes,
    required this.eventTheme,
    required this.allowSuggestions,
    required this.onVote,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (nowPlaying != null)
          _NowPlayingBanner(song: nowPlaying!, theme: eventTheme),
        Expanded(
          child: RefreshIndicator(
            color: eventTheme.accent,
            backgroundColor: AppTheme.darkCard,
            onRefresh: onRefresh,
            child: pendingSongs.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: 280,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.queue_music_rounded,
                              size: 56,
                              color:
                                  eventTheme.accent.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No hay canciones todavía',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16),
                            ),
                            if (allowSuggestions) ...[
                              const SizedBox(height: 6),
                              const Text(
                                '¡Sé el primero en sugerir una!',
                                style: TextStyle(
                                    color: Colors.white30, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(0, 8, 0, 100),
                    itemCount: pendingSongs.length,
                    itemBuilder: (_, i) {
                      final song = pendingSongs[i];
                      final isVoted = votedSet.contains(song.id);
                      final progress =
                          topVotes > 0 ? song.voteCount / topVotes : 0.0;
                      return SongTile(
                        key: ValueKey(song.id),
                        song: song,
                        isVoted: isVoted,
                        progress: progress.clamp(0.0, 1.0),
                        onVote: () => onVote(song),
                        position: i + 1,
                        topVotes: topVotes,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// Mis votos
class _MyVotesTab extends StatelessWidget {
  final List<SongModel> votedSongs;
  final int topVotes;
  final EventThemeData eventTheme;
  final Future<void> Function(SongModel) onVote;

  const _MyVotesTab({
    required this.votedSongs,
    required this.topVotes,
    required this.eventTheme,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    if (votedSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 56,
              color: eventTheme.accent.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 14),
            const Text(
              'Todavía no votaste por ninguna',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tus votos aparecen aquí',
              style: TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
      itemCount: votedSongs.length,
      itemBuilder: (_, i) {
        final song = votedSongs[i];
        final progress = topVotes > 0 ? song.voteCount / topVotes : 0.0;
        return SongTile(
          key: ValueKey('voted-${song.id}'),
          song: song,
          isVoted: true,
          progress: progress.clamp(0.0, 1.0),
          onVote: () => onVote(song),
          topVotes: topVotes,
        );
      },
    );
  }
}

class _NowPlayingBanner extends StatelessWidget {
  final SongModel song;
  final EventThemeData theme;

  const _NowPlayingBanner({required this.song, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.accent.withValues(alpha: 0.25),
            theme.neon.withValues(alpha: 0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // Indicador de música
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.music_note_rounded, color: theme.accent, size: 16),
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
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.graphic_eq_rounded, color: theme.accent, size: 22),
        ],
      ),
    );
  }
}

