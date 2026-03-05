import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

    // ── Carga inicial ──────────────────────────────────────────────────────
    if (state.isLoading && state.event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando evento...')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.neonPurple),
        ),
      );
    }

    // ── Error sin datos previos ────────────────────────────────────────────
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

    // Filtrar sólo canciones pendientes, ordenadas por votos (desc)
    final songs = (event.songs ?? <SongModel>[])
        .where((s) => s.status == 'pending')
        .toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    final maxVotes = songs.isNotEmpty ? songs.first.voteCount : 1;

    return Scaffold(
      // ── AppBar ────────────────────────────────────────────────────────────
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
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Indicador de canciones
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Chip(
              visualDensity: VisualDensity.compact,
              backgroundColor: AppTheme.neonPurple.withOpacity(0.15),
              side: const BorderSide(
                color: AppTheme.neonPurple,
                width: 0.5,
              ),
              label: Text(
                '${songs.length} canciones',
                style: const TextStyle(
                  color: AppTheme.neonPurple,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Cuerpo ────────────────────────────────────────────────────────────
      body: songs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.queue_music_rounded,
                    size: 56,
                    color: Colors.white12,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No hay canciones todavía',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                  if (event.allowAudienceSuggestions) ...[
                    const SizedBox(height: 6),
                    const Text(
                      '¡Sé el primero en sugerir una!',
                      style: TextStyle(color: Colors.white30, fontSize: 13),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
              itemCount: songs.length,
              itemBuilder: (_, i) {
                final song = songs[i];
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

      // ── FAB Sugerir ───────────────────────────────────────────────────────
      floatingActionButton: event.allowAudienceSuggestions
          ? FloatingActionButton.extended(
              onPressed: () => _openSuggestSheet(context),
              backgroundColor: AppTheme.neonPurple,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Sugerir canción',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  // ─── Lógica de voto ────────────────────────────────────────────────────────

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
        // También marca localmente para deshabilitar el botón
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
                ? AppTheme.neonPurple.withOpacity(0.9)
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
