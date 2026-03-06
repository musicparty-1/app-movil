import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_result_model.dart';
import '../providers/providers.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1E1E35),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.liveGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${result.title}" sugerida al DJ',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: Text(dioErrorToMessage(e)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: Text('Error: $e'),
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final screenH = MediaQuery.of(context).size.height;
    final resultsH = (screenH - bottom - 340).clamp(160.0, 520.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.neonPurple, Color(0xFF9B59FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.queue_music_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sugerir cancion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'El DJ vera tu sugerencia',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Campos
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  _buildField(
                    controller: _nicknameController,
                    hint: 'Tu nombre o apodo (opcional)',
                    icon: Icons.person_outline_rounded,
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  _buildField(
                    controller: _searchController,
                    hint: 'Buscar cancion o artista...',
                    icon: Icons.search_rounded,
                    iconColor: AppTheme.neonPurple,
                    autofocus: true,
                    showClear: _searchController.text.isNotEmpty,
                    onClear: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).search('');
                      setState(() {});
                    },
                    onChanged: (v) {
                      ref.read(searchProvider.notifier).search(v);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const Divider(
                height: 1, thickness: 1, color: Color(0xFF1E1E30)),

            // Resultados
            SizedBox(
              height: resultsH,
              child: searchState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.neonPurple,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error al buscar: $e',
                    style: const TextStyle(
                        color: AppTheme.errorColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (results) {
                  if (_searchController.text.trim().length < 2) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.neonPurple
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.music_note_rounded,
                                size: 34, color: AppTheme.neonPurple),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Busca una cancion',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Escribe el nombre o artista',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 40, color: Colors.white12),
                          const SizedBox(height: 10),
                          Text(
                            'Sin resultados para\n"${_searchController.text}"',
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(12, 8, 12, 32),
                    itemCount: results.length,
                    itemBuilder: (_, i) => _SongTile(
                      result: results[i],
                      isBusy: _isSuggesting,
                      onTap: _isSuggesting
                          ? null
                          : () => _suggest(results[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Color iconColor = Colors.white38,
    bool autofocus = false,
    bool showClear = false,
    TextInputAction action = TextInputAction.done,
    VoidCallback? onClear,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      textInputAction: action,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: iconColor),
        suffixIcon: showClear
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: Colors.white38),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.neonPurple, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
    );
  }
}

// ─── Song tile ──────────────────────────────────────────────────────────────

class _SongTile extends StatelessWidget {
  final SearchResultModel result;
  final VoidCallback? onTap;
  final bool isBusy;

  const _SongTile(
      {required this.result, this.onTap, this.isBusy = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Portada
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: result.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: result.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    result.artist,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.album != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      result.album!,
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Boton sugerir
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: onTap != null
                    ? const LinearGradient(
                        colors: [
                          AppTheme.neonPurple,
                          Color(0xFF9B59FF)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: onTap == null ? Colors.white10 : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white54),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            color: Colors.white, size: 15),
                        SizedBox(width: 4),
                        Text(
                          'Sugerir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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

  Widget _placeholder() => Container(
        color: const Color(0xFF1E1E35),
        child: const Icon(Icons.music_note_rounded,
            color: Colors.white24, size: 22),
      );
}

