import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/song_model.dart';
import '../theme.dart';

/// Ãtem de la lista de votaciÃ³n.
///
/// DiseÃ±o:
/// â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
/// â”‚ [barra de progreso de fondo, color neÃ³n translÃºcido]     â”‚
/// â”‚  [portada]  TÃ­tulo            [â™¥ votos]                  â”‚
/// â”‚             Artista Â· BPM                                â”‚
/// â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
///
/// La barra de progreso usa el ancho relativo al mÃ¡ximo de votos del evento.
class SongTile extends StatelessWidget {
  final SongModel song;
  final bool isVoted;

  /// 0.0 â†’ 1.0, relativo a la canciÃ³n con mÃ¡s votos del evento.
  final double progress;

  final VoidCallback onVote;

  const SongTile({
    super.key,
    required this.song,
    required this.isVoted,
    required this.progress,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Stack(
        children: [
          // â”€â”€ Barra de progreso (fondo) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress > 0 ? progress : 0.01,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x4A6B3FFF),
                          Color(0x2000F2FF),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // â”€â”€ Tarjeta con contenido â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isVoted
                    ? AppTheme.neonPurple.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.07),
                width: isVoted ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: _AlbumArt(coverUrl: song.coverUrl),
              title: Text(
                song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: _Subtitle(song: song),
              trailing: _VoteButton(
                voteCount: song.voteCount,
                isVoted: isVoted,
                onVote: onVote,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Portada â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AlbumArt extends StatelessWidget {
  final String? coverUrl;

  const _AlbumArt({this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: coverUrl != null
            ? CachedNetworkImage(
                imageUrl: coverUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppTheme.darkSurface,
        child: const Icon(
          Icons.music_note_rounded,
          color: Colors.white24,
          size: 20,
        ),
      );
}

// â”€â”€â”€ SubtÃ­tulo (artista + chip BPM) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Subtitle extends StatelessWidget {
  final SongModel song;

  const _Subtitle({required this.song});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            song.artist,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (song.bpm != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              '${song.bpm!.toStringAsFixed(0)} BPM',
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (song.addedBy == 'audience') ...[
          const SizedBox(width: 4),
          Tooltip(
            message: song.suggestedBy != null
                ? 'Sugerida por ${song.suggestedBy}'
                : 'Sugerida por el pÃºblico',
            child: const Icon(
              Icons.person_rounded,
              size: 12,
              color: Colors.white30,
            ),
          ),
        ],
      ],
    );
  }
}

// â”€â”€â”€ BotÃ³n de voto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VoteButton extends StatelessWidget {
  final int voteCount;
  final bool isVoted;
  final VoidCallback onVote;

  const _VoteButton({
    required this.voteCount,
    required this.isVoted,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isVoted ? null : onVote,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isVoted
              ? AppTheme.neonPurple.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isVoted
                ? AppTheme.neonPurple
                : Colors.white.withValues(alpha: 0.15),
          ),
          boxShadow: isVoted
              ? [
                  BoxShadow(
                    color: AppTheme.neonPurple.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVoted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 14,
              color: isVoted ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              '$voteCount',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isVoted ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

