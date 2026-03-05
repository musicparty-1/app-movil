import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';
import '../providers/providers.dart';
import '../theme.dart';
import 'voting_screen.dart';
import 'qr_scan_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _idController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _goToEvent(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VotingScreen(eventId: trimmed)),
    );
  }

  Future<void> _openQrScanner() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (id != null && mounted) {
      _goToEvent(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

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
            onPressed: _openQrScanner,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Banner de entrada manual â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x406B3FFF), Color(0x1500F2FF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vota en el evento 🎵',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          hintText: 'ID del evento',
                          prefixIcon: Icon(
                            Icons.tag_rounded,
                            size: 18,
                            color: Colors.white38,
                          ),
                        ),
                        textInputAction: TextInputAction.go,
                        onSubmitted: _goToEvent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _goToEvent(_idController.text),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Ir'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // â”€â”€ TÃ­tulo secciÃ³n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

          // â”€â”€ Lista de eventos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.neonPurple),
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
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_off_rounded,
                          size: 52,
                          color: Colors.white12,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'No hay eventos activos',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Escanea el QR o ingresa el ID',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.neonPurple,
                  backgroundColor: AppTheme.darkCard,
                  onRefresh: () =>
                      ref.read(eventsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: events.length,
                    itemBuilder: (_, i) => _EventCard(
                      event: events[i],
                      onTap: () => _goToEvent(events[i].id),
                    ),
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

// â”€â”€â”€ Tarjeta de evento â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EventCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.eventThemeFor(widget.event.eventType);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: theme.accent.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Emoji del tipo de evento
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      theme.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Nombre y venue
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.event.venue,
                        style: TextStyle(
                          color: theme.accent.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Badge EN VIVO pulsante
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.liveGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.liveGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.liveGreen.withValues(
                              alpha: 0.4 + _pulse.value * 0.6,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.liveGreen.withValues(
                                  alpha: _pulse.value * 0.5,
                                ),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'EN VIVO',
                          style: TextStyle(
                            color: AppTheme.liveGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

