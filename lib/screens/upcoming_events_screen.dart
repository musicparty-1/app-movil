import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';
import '../providers/providers.dart';
import '../theme.dart';

// ─── Provider ──────────────────────────────────────────────────────────────────

final upcomingEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) {
  return ref.read(apiServiceProvider).getUpcomingEvents();
});

// ─── Pantalla ──────────────────────────────────────────────────────────────────

class UpcomingEventsScreen extends ConsumerWidget {
  const UpcomingEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text(
          'Próximos Eventos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: eventsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.neonPurple),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white24),
              const SizedBox(height: 14),
              const Text(
                'Error al cargar próximos eventos',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => ref.invalidate(upcomingEventsProvider),
                style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.neonPurple),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🗓️',
                    style: TextStyle(fontSize: 56),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sin próximos eventos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'El DJ no tiene eventos planificados aún',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.neonPurple,
            backgroundColor: AppTheme.darkCard,
            onRefresh: () async => ref.invalidate(upcomingEventsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: events.length,
              itemBuilder: (_, i) => _UpcomingEventCard(event: events[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Card de evento próximo ─────────────────────────────────────────────────────

class _UpcomingEventCard extends StatelessWidget {
  final EventModel event;

  const _UpcomingEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.eventThemeFor(event.eventType);
    final scheduled = event.scheduledAt;
    final countdown = scheduled != null ? _countdown(scheduled) : null;
    final dateLabel = scheduled != null ? _formatDate(scheduled) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.accent.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: emoji + nombre + badge countdown
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                event.venue,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (countdown != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.accent.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        countdown,
                        style: TextStyle(
                          color: theme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                ],
              ),

              if (dateLabel != null) ...[
                const SizedBox(height: 14),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (event.allowAudienceSuggestions)
                      Row(
                        children: [
                          Icon(
                            Icons.queue_music_rounded,
                            size: 13,
                            color: AppTheme.neonCyan.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sugerencias activadas',
                            style: TextStyle(
                              color: AppTheme.neonCyan.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Días/horas restantes hasta el evento
  String _countdown(DateTime scheduled) {
    final now = DateTime.now();
    if (scheduled.isBefore(now)) return '¡Hoy!';
    final diff = scheduled.difference(now);
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return 'en $months ${months == 1 ? "mes" : "meses"}';
    }
    if (diff.inDays >= 2) return 'en ${diff.inDays} días';
    if (diff.inDays == 1) return 'mañana';
    if (diff.inHours >= 1) return 'en ${diff.inHours}h';
    return 'en ${diff.inMinutes} min';
  }

  /// Formato legible de fecha
  String _formatDate(DateTime dt) {
    const meses = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    final weekday = dias[dt.weekday - 1];
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$weekday ${dt.day} ${meses[dt.month]} · $hora:$min hs';
  }
}
