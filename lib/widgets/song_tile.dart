import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// Posición en el ranking (1 = primero). 0 = sin badge.
  final int position;

  /// Votos máximos del evento (para calcular diferencia).
  final int topVotes;

  const SongTile({
    super.key,
    required this.song,
    required this.isVoted,
    required this.progress,
    required this.onVote,
    this.position = 0,
    this.topVotes = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showSpotifyMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            if (position > 0) ...[
              _PositionBadge(position: position),
              const SizedBox(width: 6),
            ],
            Expanded(
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
              subtitle: _Subtitle(
                song: song,
                position: position,
                topVotes: topVotes,
              ),
              trailing: _VoteButton(
                voteCount: song.voteCount,
                isVoted: isVoted,
                onVote: onVote,
              ),
            ),
          ),
        ],
      ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpotifyMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              song.artist,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor: const Color(0xFF1DB954).withValues(alpha: 0.08),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_new_rounded,
                  color: Color(0xFF1DB954),
                  size: 20,
                ),
              ),
              title: const Text(
                'Buscar en Spotify',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Abre la búsqueda en el navegador',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _openSpotify();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSpotify() async {
    final query = Uri.encodeComponent('${song.title} ${song.artist}');
    final uri = Uri.parse('https://open.spotify.com/search/$query');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
  final int position;
  final int topVotes;

  const _Subtitle({
    required this.song,
    this.position = 0,
    this.topVotes = 0,
  });

  @override
  Widget build(BuildContext context) {
    final diff = topVotes - song.voteCount;
    final showDiff = position > 1 && diff > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                    : 'Sugerida por el público',
                child: const Icon(
                  Icons.person_rounded,
                  size: 12,
                  color: Colors.white30,
                ),
              ),
            ],
          ],
        ),
        if (showDiff)
          Text(
            '−$diff vs #1',
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
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

// ─── Badge de posición ────────────────────────────────────────────────────────────────

class _PositionBadge extends StatelessWidget {
  final int position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    if (position <= 3) {
      final emojis = ['🥇', '🥈', '🥉'];
      return SizedBox(
        width: 28,
        child: Center(
          child: Text(
            emojis[position - 1],
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    return SizedBox(
      width: 28,
      child: Center(
        child: Text(
          '#$position',
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
