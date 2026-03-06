import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';
import '../providers/providers.dart';
import '../services/geo_service.dart';
import '../theme.dart';
import '../widgets/skeleton_loader.dart';
import 'voting_screen.dart';
import 'qr_scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openQr(BuildContext context) async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (id != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VotingScreen(eventId: id)),
      );
    }
  }

  void _goToEvent(BuildContext context, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VotingScreen(eventId: id)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final geoAsync = ref.watch(userPositionProvider);

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Music',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonPurple,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Party',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonCyan,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Escanear QR del evento',
            onPressed: () => _openQr(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              'EVENTOS EN VIVO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: eventsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: 5,
                itemBuilder: (_, __) => const SkeletonEventCard(),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.signal_wifi_statusbar_connected_no_internet_4,
                      size: 48,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudo cargar',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(eventsProvider.notifier).refresh(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.music_off_rounded,
                          size: 52,
                          color: Colors.white12,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No hay eventos activos',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pedile el QR al DJ',
                          style: TextStyle(color: Colors.white30, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _openQr(context),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.neonPurple),
                          icon: const Icon(Icons.qr_code_rounded, size: 18),
                          label: const Text('Escanear QR'),
                        ),
                      ],
                    ),
                  );
                }

                // Calcular distancias si hay posición disponible
                GeoPosition? userPos;
                if (geoAsync is AsyncData<GeoResult>) {
                  final r = geoAsync.value;
                  if (r is GeoPosition) userPos = r;
                }

                // Ordenar: primero los cercanos (si tiene coordenadas), luego el resto
                final sorted = List<EventModel>.from(events);
                if (userPos != null) {
                  sorted.sort((a, b) {
                    final da = (a.latitude != null && a.longitude != null)
                        ? haversineMeters(userPos!.lat, userPos.lng,
                            a.latitude!, a.longitude!)
                        : double.infinity;
                    final db = (b.latitude != null && b.longitude != null)
                        ? haversineMeters(userPos!.lat, userPos.lng,
                            b.latitude!, b.longitude!)
                        : double.infinity;
                    return da.compareTo(db);
                  });
                }

                return RefreshIndicator(
                  color: AppTheme.neonPurple,
                  backgroundColor: AppTheme.darkCard,
                  onRefresh: () => ref.read(eventsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: sorted.length,
                    itemBuilder: (_, i) {
                      final event = sorted[i];
                      double? distM;
                      if (userPos != null &&
                          event.latitude != null &&
                          event.longitude != null) {
                        distM = haversineMeters(userPos.lat, userPos.lng,
                            event.latitude!, event.longitude!);
                      }
                      return _EventCard(
                        event: event,
                        distanceMeters: distM,
                        onTap: () => _goToEvent(context, event.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: unused_element

class _EventCard extends StatefulWidget {
  final EventModel event;
  final double? distanceMeters;
  final VoidCallback onTap;

  const _EventCard(
      {required this.event, required this.onTap, this.distanceMeters});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _genreLabel(String? type) {
    switch (type) {
      case 'club':
        return 'Club';
      case 'wedding':
        return 'Casamiento';
      case 'festival':
        return 'Festival';
      case 'corporate':
        return 'Corporativo';
      case 'private':
        return 'Privado';
      default:
        return 'Evento';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.eventThemeFor(widget.event.eventType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: theme.accent.withValues(alpha: 0.12),
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.accent.withValues(alpha: 0.22),
                    const Color(0xFF0D0D1A),
                  ],
                ),
                border: Border.all(
                  color: theme.accent.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Emoji watermark
                  Positioned(
                    right: 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        theme.emoji,
                        style: TextStyle(
                          fontSize: 72,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ),
                  // Contenido
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila top: EN VIVO + genre badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.liveGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.liveGreen
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: AppTheme.liveGreen.withValues(
                                        alpha: 0.5 + _pulse.value * 0.5,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.liveGreen.withValues(
                                              alpha: _pulse.value * 0.6),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'EN VIVO',
                                    style: TextStyle(
                                      color: AppTheme.liveGreen,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Genre badge
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.accent.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _genreLabel(widget.event.eventType),
                                style: TextStyle(
                                  color: theme.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            if (widget.distanceMeters != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: widget.distanceMeters! < 300
                                      ? AppTheme.liveGreen
                                          .withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: widget.distanceMeters! < 300
                                        ? AppTheme.liveGreen
                                            .withValues(alpha: 0.4)
                                        : Colors.white.withValues(alpha: 0.12),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.distanceMeters! < 300
                                          ? Icons.near_me_rounded
                                          : Icons.location_on_rounded,
                                      size: 9,
                                      color: widget.distanceMeters! < 300
                                          ? AppTheme.liveGreen
                                          : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      widget.distanceMeters! < 300
                                          ? '\u00a1Estás aquí!'
                                          : formatDistance(
                                              widget.distanceMeters!),
                                      style: TextStyle(
                                        color: widget.distanceMeters! < 300
                                            ? AppTheme.liveGreen
                                            : AppTheme.textSecondary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),
                        // Fila inferior: nombre + venue + ENTRAR
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Hero(
                                    tag: 'event-name-${widget.event.id}',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        widget.event.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 11,
                                        color: theme.accent
                                            .withValues(alpha: 0.75),
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          widget.event.venue,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: widget.onTap,
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'ENTRAR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
