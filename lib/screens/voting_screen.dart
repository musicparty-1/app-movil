import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song_model.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/song_tile.dart';
import '../widgets/suggest_song_sheet.dart';

class VotingScreen extends ConsumerWidget {
  final String eventId;

  const VotingScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(votingProvider(eventId));
    final votedMap = ref.watch(votedSongsMapProvider);
    final votedSet = votedMap[eventId] ?? const {};

    // â”€â”€ Carga inicial â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (state.isLoading && state.event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando evento...')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.neonPurple),
        ),
      );
    }

    // â”€â”€ Error sin datos previos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (state.error != null && state.event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.white24),
                const SizedBox(height: 14),
                const Text(
                  'No se pudo cargar el evento',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '(${state.error})',
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(votingProvider(eventId).notifier).refresh(),
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

    // Canciones pendientes ordenadas por votos (desc)
    final pendingSongs = (event.songs ?? <SongModel>[])
        .where((s) => s.status == 'pending')
        .toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    // Canciones ya reproducidas (la más reciente primero)
    final playedSongs = (event.songs ?? <SongModel>[])
        .where((s) => s.status == 'played')
        .toList()
      ..sort((a, b) => b.orderIndex.compareTo(a.orderIndex));

    final nowPlaying = playedSongs.isNotEmpty ? playedSongs.first : null;
    final maxVotes = pendingSongs.isNotEmpty ? pendingSongs.first.voteCount : 1;

    return Scaffold(
      // â”€â”€ AppBar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          // Botón compartir — copia el ID al portapapeles
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'Copiar ID del evento',
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
          // Chip contador de canciones
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              visualDensity: VisualDensity.compact,
              backgroundColor: eventTheme.accent.withValues(alpha: 0.15),
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
      ),

      // â”€â”€ Cuerpo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      body: Column(
        children: [
          // Sonando Ahora
          if (nowPlaying != null)
            _NowPlayingBanner(song: nowPlaying, theme: eventTheme),

          // Lista de canciones o empty state
          Expanded(
            child: pendingSongs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.queue_music_rounded,
                          size: 56,
                          color: eventTheme.accent.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No hay canciones todavía',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16),
                        ),
                        if (event.allowAudienceSuggestions) ...[
                          const SizedBox(height: 6),
                          const Text(
                            '¡Sé el primero en sugerir una!',
                            style:
                                TextStyle(color: Colors.white30, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                    itemCount: pendingSongs.length,
                    itemBuilder: (_, i) {
                      final song = pendingSongs[i];
                      final isVoted = votedSet.contains(song.id);
                      final progress =
                          maxVotes > 0 ? song.voteCount / maxVotes : 0.0;

                      return SongTile(
                        key: ValueKey(song.id),
                        song: song,
                        isVoted: isVoted,
                        progress: progress.clamp(0.0, 1.0),
                        onVote: () => _vote(context, ref, song),
                      );
                    },
                  ),
          ),
        ],
      ),

      // â”€â”€ FAB Sugerir â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      floatingActionButton: event.allowAudienceSuggestions
          ? FloatingActionButton.extended(
              onPressed: () => _openSuggestSheet(context),
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

  // â”€â”€â”€ LÃ³gica de voto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _vote(
    BuildContext context,
    WidgetRef ref,
    SongModel song,
  ) async {
    // Obtener deviceId (viene de FutureProvider, ya cacheado)
    final deviceId = await ref.read(deviceIdProvider.future);

    try {
      await ref.read(apiServiceProvider).vote(
            songId: song.id,
            eventId: eventId,
            deviceId: deviceId,
          );

      // Marcar como votada en el estado local
      _markVoted(ref, song.id);
    } on DioException catch (e) {
      final is409 = e.response?.statusCode == 409;

      if (is409) {
        // TambiÃ©n marca localmente para deshabilitar el botÃ³n
        _markVoted(ref, song.id);
      }

      if (context.mounted) {
        final msg = is409
            ? 'Ya votaste por esta canción'
            : dioErrorToMessage(e);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: is409
                ? AppTheme.neonPurple.withValues(alpha: 0.9)
                : AppTheme.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _markVoted(WidgetRef ref, String songId) {
    ref.read(votedSongsMapProvider.notifier).update((state) {
      final copy = Map<String, Set<String>>.from(state);
      copy[eventId] = {...(copy[eventId] ?? {}), songId};
      return copy;
    });
  }

  void _openSuggestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SuggestSongSheet(eventId: eventId),
    );
  }
}

// ─── Sonando Ahora ────────────────────────────────────────────────────────────
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

