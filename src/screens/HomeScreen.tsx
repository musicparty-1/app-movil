import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  RefreshControl,
  StatusBar,
} from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { listarEventosPublicos } from '../api/events';
import { usePolling } from '../hooks/usePolling';
import { Colors, getTheme } from '../constants/colors';
import type { Evento } from '../types';

export default function HomeScreen() {
  const router = useRouter();
  const [events, setEvents] = useState<Evento[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchEvents = useCallback(async () => {
    try {
      const data = await listarEventosPublicos();
      // Solo mostramos los LIVE primero, luego draft
      setEvents(
        data.sort((a, b) => {
          if (a.status === 'live' && b.status !== 'live') return -1;
          if (b.status === 'live' && a.status !== 'live') return 1;
          return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
        }),
      );
      setError(null);
    } catch {
      setError('No se pudo cargar los eventos');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  usePolling(fetchEvents, 15_000);

  const onRefresh = useCallback(() => {
    setRefreshing(true);
    fetchEvents();
  }, [fetchEvents]);

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Colors.purple} />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.bg} />

      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.logo}>♫ MusicParty</Text>
        <Text style={styles.subtitle}>Votá las canciones del evento</Text>
      </View>

      {error && (
        <View style={styles.errorBox}>
          <Text style={styles.errorText}>{error}</Text>
        </View>
      )}

      {events.length === 0 && !error ? (
        <View style={styles.empty}>
          <Text style={styles.emptyEmoji}>🎵</Text>
          <Text style={styles.emptyText}>No hay eventos activos ahora</Text>
          <Text style={styles.emptyHint}>Volvé más tarde o pedile el link al DJ</Text>
        </View>
      ) : (
        <FlatList
          data={events}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.list}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor={Colors.purple}
            />
          }
          renderItem={({ item }) => <EventCard event={item} onPress={() => router.push(`/event/${item.id}`)} />}
        />
      )}
    </View>
  );
}

function EventCard({ event, onPress }: { event: Evento; onPress: () => void }) {
  const theme = getTheme(event.eventType);
  const isLive = event.status === 'live';

  return (
    <TouchableOpacity style={styles.card} onPress={onPress} activeOpacity={0.75}>
      <View style={[styles.cardAccentBar, { backgroundColor: theme.accent }]} />
      <View style={styles.cardContent}>
        <View style={styles.cardTop}>
          <Text style={styles.eventEmoji}>{theme.emoji}</Text>
          <View style={styles.cardInfo}>
            <Text style={styles.eventName} numberOfLines={1}>{event.name}</Text>
            {event.venue ? (
              <Text style={styles.eventVenue} numberOfLines={1}>📍 {event.venue}</Text>
            ) : null}
          </View>
          {isLive && (
            <View style={styles.liveBadge}>
              <View style={[styles.liveDot, { backgroundColor: theme.accent }]} />
              <Text style={[styles.liveText, { color: theme.accent2 }]}>LIVE</Text>
            </View>
          )}
        </View>

        {event._count ? (
          <View style={styles.cardStats}>
            <Text style={styles.statText}>🎵 {event._count.songs} canciones</Text>
            <Text style={styles.statSep}>·</Text>
            <Text style={styles.statText}>❤️ {event._count.votes} votos</Text>
          </View>
        ) : null}

        {/* Barra de acento */}
        <LinearGradient
          colors={[theme.accent + '22', 'transparent']}
          style={StyleSheet.absoluteFillObject}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          pointerEvents="none"
        />
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bg,
  },
  center: {
    flex: 1,
    backgroundColor: Colors.bg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  header: {
    paddingTop: 60,
    paddingHorizontal: 24,
    paddingBottom: 24,
  },
  logo: {
    fontSize: 26,
    fontWeight: '800',
    color: Colors.purple,
    letterSpacing: -0.5,
  },
  subtitle: {
    fontSize: 14,
    color: Colors.textMuted,
    marginTop: 4,
  },
  list: {
    paddingHorizontal: 16,
    paddingBottom: 40,
    gap: 12,
  },
  card: {
    backgroundColor: Colors.surface,
    borderRadius: 18,
    borderWidth: 1.5,
    borderColor: Colors.border,
    overflow: 'hidden',
    flexDirection: 'row',
  },
  cardAccentBar: {
    width: 4,
  },
  cardContent: {
    flex: 1,
    padding: 16,
  },
  cardTop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  eventEmoji: {
    fontSize: 28,
  },
  cardInfo: {
    flex: 1,
  },
  eventName: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.text,
    letterSpacing: -0.3,
  },
  eventVenue: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 2,
  },
  liveBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: 'rgba(107,63,255,0.12)',
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: 'rgba(107,63,255,0.3)',
  },
  liveDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  liveText: {
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  cardStats: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 10,
    gap: 8,
  },
  statText: {
    fontSize: 12,
    color: Colors.textMuted,
  },
  statSep: {
    color: Colors.textFaint,
    fontSize: 12,
  },
  errorBox: {
    marginHorizontal: 16,
    marginBottom: 12,
    backgroundColor: 'rgba(239,68,68,0.1)',
    borderRadius: 12,
    padding: 12,
    borderWidth: 1,
    borderColor: 'rgba(239,68,68,0.3)',
  },
  errorText: {
    color: Colors.red,
    fontSize: 14,
    textAlign: 'center',
  },
  empty: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  emptyEmoji: {
    fontSize: 48,
    marginBottom: 8,
  },
  emptyText: {
    fontSize: 17,
    fontWeight: '700',
    color: Colors.text,
  },
  emptyHint: {
    fontSize: 14,
    color: Colors.textMuted,
    textAlign: 'center',
    paddingHorizontal: 40,
  },
});
