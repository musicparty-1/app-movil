import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';
import '../models/search_result_model.dart';
import '../services/api_service.dart';
import '../services/device_id_service.dart';
import '../config.dart';

// ─── Infraestructura ──────────────────────────────────────────────────────────

/// Singleton del servicio HTTP — compartido en toda la app.
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// DeviceId único del dispositivo. Se carga una sola vez.
final deviceIdProvider = FutureProvider<String>(
  (ref) => DeviceIdService.getDeviceId(),
);

// ─── Eventos públicos ─────────────────────────────────────────────────────────

/// Provider de la lista de eventos activos (HomeScreen).
/// Soporta refresh manual (pull-to-refresh, botón reintentar).
class EventsNotifier extends AsyncNotifier<List<EventModel>> {
  @override
  Future<List<EventModel>> build() => _fetch();

  Future<List<EventModel>> _fetch() =>
      ref.read(apiServiceProvider).getPublicEvents();

  /// Recarga la lista desde el servidor.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final eventsProvider =
    AsyncNotifierProvider<EventsNotifier, List<EventModel>>(
  EventsNotifier.new,
);

// ─── Votación (polling) ───────────────────────────────────────────────────────

/// Estado inmutable del evento en la VotingScreen.
class VotingState {
  final EventModel? event;
  final bool isLoading;
  final String? error;

  const VotingState({
    this.event,
    this.isLoading = true,
    this.error,
  });

  VotingState copyWith({
    EventModel? event,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      VotingState(
        event: event ?? this.event,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Notifier con polling cada [AppConfig.pollingIntervalSec] segundos.
///
/// - Primera carga: muestra spinner
/// - Polls sucesivos: actualiza silenciosamente (no interrumpe el scroll)
/// - Error en poll: se ignora — la UI mantiene los datos anteriores
/// - autoDispose: el timer se cancela al salir de VotingScreen
class VotingNotifier extends StateNotifier<VotingState> {
  VotingNotifier(this._api, this._eventId) : super(const VotingState()) {
    _load();
    _startPolling();
  }

  final ApiService _api;
  final String _eventId;
  Timer? _timer;

  /// Carga inicial — muestra el estado de carga.
  Future<void> _load() async {
    try {
      final event = await _api.getEvent(_eventId);
      if (mounted) {
        state = VotingState(event: event, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = VotingState(error: e.toString(), isLoading: false);
      }
    }
  }

  /// Poll silencioso — llamado por el timer.
  Future<void> _poll() async {
    try {
      final event = await _api.getEvent(_eventId);
      if (mounted) {
        state = state.copyWith(event: event);
      }
    } catch (_) {
      // Fallo silencioso — no reemplaza datos existentes con un error
    }
  }

  void _startPolling() {
    _timer = Timer.periodic(
      const Duration(seconds: AppConfig.pollingIntervalSec),
      (_) => _poll(),
    );
  }

  /// Refresh forzado (botón reintentar).
  Future<void> refresh() async {
    state = VotingState(event: state.event, isLoading: true);
    await _load();
  }

  /// Actualización optimista: +1 al voteCount de la canción votada.
  /// El poll siguiente sobreescribirá con el valor real del servidor.
  void incrementVote(String songId) {
    final event = state.event;
    if (event == null) return;
    final songs = event.songs?.map((s) {
      return s.id == songId ? s.copyWith(voteCount: s.voteCount + 1) : s;
    }).toList();
    if (mounted) {
      state = state.copyWith(
        event: EventModel(
          id: event.id,
          name: event.name,
          venue: event.venue,
          status: event.status,
          eventType: event.eventType,
          allowAudienceSuggestions: event.allowAudienceSuggestions,
          createdAt: event.createdAt,
          songs: songs,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Family provider: un notifier independiente por eventId.
/// autoDispose cancela el timer al hacer pop de VotingScreen.
final votingProvider = StateNotifierProvider.autoDispose
    .family<VotingNotifier, VotingState, String>(
  (ref, eventId) => VotingNotifier(ref.read(apiServiceProvider), eventId),
);

// ─── Votos locales (anti-duplicado en UI) ─────────────────────────────────────

/// Mapa en memoria: eventId → Set de songIds por los que ya votó el usuario.
/// Se pierde al cerrar la app (complementa el 409 del backend).
final votedSongsMapProvider =
    StateProvider<Map<String, Set<String>>>((ref) => {});

// ─── Búsqueda con debounce ────────────────────────────────────────────────────

/// Notifier de búsqueda con debounce de 350ms.
class SearchNotifier
    extends StateNotifier<AsyncValue<List<SearchResultModel>>> {
  SearchNotifier(this._api) : super(const AsyncValue.data([]));

  final ApiService _api;
  Timer? _debounce;

  void search(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      state = await AsyncValue.guard(() => _api.searchSongs(query));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier,
    AsyncValue<List<SearchResultModel>>>(
  (ref) => SearchNotifier(ref.read(apiServiceProvider)),
);
