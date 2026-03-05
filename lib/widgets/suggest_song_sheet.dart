import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_result_model.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme.dart';

/// Modal inferior para buscar y sugerir canciones al evento.
///
/// Se abre con showModalBottomSheet desde VotingScreen.
/// Usa DraggableScrollableSheet para ajustarse al teclado.
class SuggestSongSheet extends ConsumerStatefulWidget {
  final String eventId;

  const SuggestSongSheet({super.key, required this.eventId});

  @override
  ConsumerState<SuggestSongSheet> createState() => _SuggestSongSheetState();
}

class _SuggestSongSheetState extends ConsumerState<SuggestSongSheet> {
  final _searchController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isSuggesting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _suggest(SearchResultModel result) async {
    setState(() => _isSuggesting = true);

    try {
      await ref.read(apiServiceProvider).suggestSong(
            title: result.title,
            artist: result.artist,
            eventId: widget.eventId,
            coverUrl: result.coverUrl,
            spotifyId: result.spotifyId,
            suggestedBy: _nicknameController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context); // cierra el sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡"${result.title}" sugerida al DJ!'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dioErrorToMessage(e)),
            backgroundColor: AppTheme.errorColor,
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
    } finally {
      if (mounted) setState(() => _isSuggesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // â”€â”€ Asa â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // â”€â”€ Cabecera + campos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: EdgeInsets.fromLTRB(16, 2, 16, keyboardHeight > 0 ? 8 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sugerir canción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Apodo (opcional)
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      hintText: 'Tu apodo (opcional)',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: Colors.white38,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),

                  // Buscador de canciÃ³n
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Buscar canción o artista...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Colors.white38,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchProvider.notifier).search('');
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white38,
                              ),
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      ref.read(searchProvider.notifier).search(v);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.white10),

            // â”€â”€ Resultados â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: searchState.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: AppTheme.neonPurple,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error al buscar: $e',
                      style: const TextStyle(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (results) {
                  if (_searchController.text.trim().length < 2) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 40,
                            color: Colors.white12,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Escribe al menos 2 caracteres',
                            style: TextStyle(color: Colors.white30),
                          ),
                        ],
                      ),
                    );
                  }

                  if (results.isEmpty) {
                    return Center(
                      child: Text(
                        'Sin resultados para "${_searchController.text}"',
                        style: const TextStyle(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: results.length,
                    itemBuilder: (_, i) => _SearchResultTile(
                      result: results[i],
                      onTap: _isSuggesting ? null : () => _suggest(results[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// â”€â”€â”€ Ãtem de resultado de bÃºsqueda â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SearchResultTile extends StatelessWidget {
  final SearchResultModel result;
  final VoidCallback? onTap;

  const _SearchResultTile({required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 46,
          height: 46,
          child: result.coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: result.coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _imgPlaceholder(),
                  errorWidget: (_, __, ___) => _imgPlaceholder(),
                )
              : _imgPlaceholder(),
        ),
      ),
      title: Text(
        result.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        result.album != null
            ? '${result.artist} Â· ${result.album}'
            : result.artist,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.add_circle_outline_rounded,
        color: onTap != null
            ? AppTheme.neonPurple
            : AppTheme.neonPurple.withValues(alpha: 0.3),
        size: 22,
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: AppTheme.darkSurface,
        child: const Icon(
          Icons.music_note_rounded,
          color: Colors.white24,
          size: 18,
        ),
      );
}

