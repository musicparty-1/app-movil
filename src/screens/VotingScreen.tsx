import React, { useState, useCallback, useRef } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  StatusBar,
  TextInput,
  Modal,
  KeyboardAvoidingView,
  Platform,
  Animated,
  Image,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import * as Haptics from 'expo-haptics';
import { obtenerEvento } from '../api/events';
import { votar, sugerirCancion } from '../api/votes';
import { usePolling } from '../hooks/usePolling';
import { useDeviceId } from '../hooks/useDeviceId';
import { Colors, getTheme } from '../constants/colors';
import type { Cancion, Evento } from '../types';

const CAMELOT: Record<number, Record<number, string>> = {
  0: { 0: '5A', 1: '8B' }, 1: { 0: '12A', 1: '3B' },
  2: { 0: '7A', 1: '10B' }, 3: { 0: '2A', 1: '5B' },
  4: { 0: '9A', 1: '12B' }, 5: { 0: '4A', 1: '7B' },
  6: { 0: '11A', 1: '2B' }, 7: { 0: '6A', 1: '9B' },
  8: { 0: '1A', 1: '4B' }, 9: { 0: '8A', 1: '11B' },
  10: { 0: '3A', 1: '6B' }, 11: { 0: '10A', 1: '1B' },
};

function camelotLabel(key?: number, mode?: number): string | null {
  if (key == null || mode == null) return null;
  return CAMELOT[key]?.[mode] ?? null;
}

export default function VotingScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const deviceId = useDeviceId();

  const [event, setEvent] = useState<Evento | null>(null);
  const [loading, setLoading] = useState(true);
  const [votedIds, setVotedIds] = useState<Set<string>>(new Set());
  const [votingId, setVotingId] = useState<string | null>(null);
  const [showSuggest, setShowSuggest] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchEvent = useCallback(async () => {
    if (!id) return;
    try {
      const data = await obtenerEvento(id);
      setEvent(data);
      setError(null);
    } catch {
      setError('No se pudo cargar el evento');
    } finally {
      setLoading(false);
    }
  }, [id]);

  usePolling(fetchEvent, 8_000);

  const handleVote = useCallback(
    async (songId: string) => {
      if (!deviceId || votedIds.has(songId) || votingId) return;
      setVotingId(songId);
      try {
        await votar({ songId, deviceId });
        await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
        setVotedIds((prev) => new Set([...prev, songId]));
        // Optimistic update
        setEvent((prev) => {
          if (!prev?.songs) return prev;
          return {
            ...prev,
            songs: prev.songs.map((s) =>
              s.id === songId
                ? { ...s, _count: { votes: s._count.votes + 1 } }
                : s,
            ),
          };
        });
      } catch (err: any) {
        const msg = err?.response?.data?.message;
        if (msg && msg.toLowerCase().includes('ya votaste')) {
          setVotedIds((prev) => new Set([...prev, songId]));
        }
      } finally {
        setVotingId(null);
      }
    },
    [deviceId, votedIds, votingId],
  );

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Colors.purple} />
      </View>
    );
  }

  if (error || !event) {
    return (
      <View style={styles.center}>
        <Text style={{ color: Colors.red, fontSize: 16 }}>{error ?? 'Evento no encontrado'}</Text>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={{ color: Colors.purple }}>← Volver</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const theme = getTheme(event.eventType);
  const songs = event.songs ?? [];
  const pendingSongs = songs
    .filter((s) => s.status === 'pending')
    .sort((a, b) => b._count.votes - a._count.votes);
  const playedSongs = songs.filter((s) => s.status === 'played');
  const maxVotes = pendingSongs[0]?._count?.votes ?? 1;

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.bg} />

      {/* Header con gradiente del tema */}
      <LinearGradient
        colors={[theme.accent + '33', Colors.bg]}
        style={styles.headerGradient}
      >
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtnHeader}>
          <Text style={styles.backArrow}>←</Text>
        </TouchableOpacity>
        <View style={styles.headerInfo}>
          <Text style={styles.headerEmoji}>{theme.emoji}</Text>
          <View>
            <Text style={styles.headerName} numberOfLines={1}>{event.name}</Text>
            {event.venue ? <Text style={styles.headerVenue}>📍 {event.venue}</Text> : null}
          </View>
          {event.status === 'live' && (
            <View style={[styles.liveBadge, { borderColor: theme.accent + '55' }]}>
              <View style={[styles.liveDot, { backgroundColor: theme.accent }]} />
              <Text style={[styles.liveText, { color: theme.accent2 }]}>LIVE</Text>
            </View>
          )}
        </View>
      </LinearGradient>

      <FlatList
        data={pendingSongs}
        keyExtractor={(s) => s.id}
        contentContainerStyle={styles.list}
        ListHeaderComponent={
          pendingSongs.length === 0 ? (
            <View style={styles.emptyList}>
              <Text style={{ fontSize: 32 }}>🎵</Text>
              <Text style={{ color: Colors.textMuted, marginTop: 8 }}>Sin canciones pendientes</Text>
            </View>
          ) : null
        }
        ListFooterComponent={
          <>
            {event.allowAudienceSuggestions && (
              <TouchableOpacity
                style={[styles.suggestBtn, { borderColor: theme.accent + '55' }]}
                onPress={() => setShowSuggest(true)}
              >
                <Text style={[styles.suggestBtnText, { color: theme.accent2 }]}>
                  + Sugerir canción
                </Text>
              </TouchableOpacity>
            )}
            {playedSongs.length > 0 && (
              <View style={styles.playedSection}>
                <Text style={styles.playedLabel}>Ya sonaron</Text>
                {playedSongs.map((s) => (
                  <View key={s.id} style={styles.playedRow}>
                    <Text style={styles.playedCheck}>✓</Text>
                    <Text style={styles.playedTitle} numberOfLines={1}>
                      {s.title}
                    </Text>
                    <Text style={styles.playedArtist} numberOfLines={1}>
                      {s.artist}
                    </Text>
                  </View>
                ))}
              </View>
            )}
          </>
        }
        renderItem={({ item, index }) => (
          <SongCard
            song={item}
            index={index}
            maxVotes={maxVotes}
            voted={votedIds.has(item.id)}
            voting={votingId === item.id}
            theme={{ accent: theme.accent, accent2: theme.accent2, gradient: theme.gradient }}
            onVote={() => handleVote(item.id)}
          />
        )}
      />

      {showSuggest && event.allowAudienceSuggestions && (
        <SuggestModal
          eventId={event.id}
          theme={theme}
          onClose={() => setShowSuggest(false)}
        />
      )}
    </View>
  );
}

// ── SongCard ─────────────────────────────────────────────────────────────────

type SongCardProps = {
  song: Cancion;
  index: number;
  maxVotes: number;
  voted: boolean;
  voting: boolean;
  theme: { accent: string; accent2: string; gradient: [string, string] };
  onVote: () => void;
};

function SongCard({ song, index, maxVotes, voted, voting, theme, onVote }: SongCardProps) {
  const isTop = index === 0;
  const pct = maxVotes > 0 ? song._count.votes / maxVotes : 0;
  const camelot = camelotLabel(song.songKey, song.songMode);

  return (
    <View style={[styles.card, isTop && styles.cardTop, voted && styles.cardVoted]}>
      <View style={styles.cardRow}>
        {/* Cover / rank */}
        <View style={styles.coverWrap}>
          {song.coverUrl ? (
            <Image source={{ uri: song.coverUrl }} style={styles.cover} />
          ) : (
            <LinearGradient
              colors={isTop ? theme.gradient : ['rgba(255,255,255,0.06)', 'rgba(255,255,255,0.02)']}
              style={styles.cover}
            >
              <Text style={styles.rankText}>#{index + 1}</Text>
            </LinearGradient>
          )}
        </View>

        {/* Info */}
        <View style={styles.songInfo}>
          <Text style={[styles.songTitle, isTop && { color: Colors.text }]} numberOfLines={1}>
            {song.title}
          </Text>
          <Text style={styles.songArtist} numberOfLines={1}>{song.artist}</Text>
          <View style={styles.songMeta}>
            {camelot && (
              <View style={[styles.metaBadge, { borderColor: theme.accent + '55' }]}>
                <Text style={[styles.metaText, { color: theme.accent2 }]}>{camelot}</Text>
              </View>
            )}
            {song.bpm && (
              <View style={styles.metaBadge}>
                <Text style={styles.metaText}>{Math.round(song.bpm)} BPM</Text>
              </View>
            )}
          </View>
        </View>

        {/* Votar */}
        <View style={styles.voteWrap}>
          <TouchableOpacity
            style={styles.voteBtn}
            onPress={onVote}
            disabled={voted || voting || !song}
            activeOpacity={0.7}
          >
            {voting ? (
              <ActivityIndicator size="small" color="#fff" />
            ) : (
              <LinearGradient
                colors={voted ? ['#16a34a', '#22c55e'] : theme.gradient}
                style={styles.voteBtnGrad}
              >
                <Text style={styles.voteBtnIcon}>{voted ? '✓' : '❤'}</Text>
              </LinearGradient>
            )}
          </TouchableOpacity>
          <Text style={styles.voteCount}>{song._count.votes}</Text>
        </View>
      </View>

      {/* Barra de progreso */}
      <View style={styles.progressBar}>
        <Animated.View
          style={[
            styles.progressFill,
            { width: `${Math.round(pct * 100)}%`, backgroundColor: voted ? Colors.green : theme.accent },
          ]}
        />
      </View>
    </View>
  );
}

// ── SuggestModal ──────────────────────────────────────────────────────────────

type SuggestModalProps = {
  eventId: string;
  theme: { accent: string; accent2: string; gradient: [string, string] };
  onClose: () => void;
};

function SuggestModal({ eventId, theme, onClose }: SuggestModalProps) {
  const [title, setTitle] = useState('');
  const [artist, setArtist] = useState('');
  const [nick, setNick] = useState('');
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);

  const handleSend = async () => {
    if (!title.trim() || !artist.trim()) return;
    setSending(true);
    try {
      await sugerirCancion({
        eventId,
        title: title.trim(),
        artist: artist.trim(),
        suggestedBy: nick.trim() || undefined,
      });
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      setSent(true);
      setTimeout(onClose, 1500);
    } catch {
      // silencioso — el DJ puede haberla desactivado
    } finally {
      setSending(false);
    }
  };

  return (
    <Modal transparent animationType="slide" onRequestClose={onClose}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.modalOverlay}
      >
        <TouchableOpacity style={{ flex: 1 }} onPress={onClose} activeOpacity={1} />
        <View style={styles.modalSheet}>
          <View style={[styles.modalHandle, { backgroundColor: theme.accent }]} />
          <Text style={styles.modalTitle}>Sugerir canción</Text>

          {sent ? (
            <View style={styles.sentWrap}>
              <Text style={styles.sentEmoji}>✅</Text>
              <Text style={styles.sentText}>¡Sugerencia enviada!</Text>
            </View>
          ) : (
            <>
              <TextInput
                style={[styles.input, { borderColor: theme.accent + '44' }]}
                placeholder="Canción *"
                placeholderTextColor={Colors.textFaint}
                value={title}
                onChangeText={setTitle}
              />
              <TextInput
                style={[styles.input, { borderColor: theme.accent + '44' }]}
                placeholder="Artista *"
                placeholderTextColor={Colors.textFaint}
                value={artist}
                onChangeText={setArtist}
              />
              <TextInput
                style={[styles.input, { borderColor: theme.accent + '44' }]}
                placeholder="Tu nombre (opcional)"
                placeholderTextColor={Colors.textFaint}
                value={nick}
                onChangeText={setNick}
              />
              <TouchableOpacity
                onPress={handleSend}
                disabled={sending || !title.trim() || !artist.trim()}
                style={{ opacity: !title.trim() || !artist.trim() ? 0.4 : 1 }}
              >
                <LinearGradient
                  colors={theme.gradient}
                  style={styles.sendBtn}
                >
                  {sending ? (
                    <ActivityIndicator size="small" color="#fff" />
                  ) : (
                    <Text style={styles.sendBtnText}>Enviar sugerencia</Text>
                  )}
                </LinearGradient>
              </TouchableOpacity>
            </>
          )}
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.bg },
  center: {
    flex: 1,
    backgroundColor: Colors.bg,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  backBtn: { marginTop: 16, padding: 12 },
  headerGradient: {
    paddingTop: 52,
    paddingBottom: 20,
    paddingHorizontal: 20,
  },
  backBtnHeader: { marginBottom: 12 },
  backArrow: { fontSize: 18, color: Colors.textMuted },
  headerInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  headerEmoji: { fontSize: 32 },
  headerName: {
    fontSize: 18,
    fontWeight: '800',
    color: Colors.text,
    flex: 1,
  },
  headerVenue: { fontSize: 12, color: Colors.textMuted, marginTop: 2 },
  liveBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderWidth: 1,
    backgroundColor: 'rgba(107,63,255,0.1)',
  },
  liveDot: { width: 6, height: 6, borderRadius: 3 },
  liveText: { fontSize: 10, fontWeight: '800', letterSpacing: 0.5 },
  list: { paddingHorizontal: 16, paddingTop: 8, paddingBottom: 60, gap: 10 },
  card: {
    backgroundColor: Colors.surface,
    borderRadius: 18,
    borderWidth: 1.5,
    borderColor: Colors.border,
    padding: 14,
    gap: 10,
  },
  cardTop: {
    backgroundColor: 'rgba(107,63,255,0.08)',
    borderColor: 'rgba(107,63,255,0.4)',
  },
  cardVoted: {
    backgroundColor: 'rgba(34,197,94,0.04)',
    borderColor: 'rgba(34,197,94,0.3)',
  },
  cardRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  coverWrap: { width: 52, height: 52, borderRadius: 10, overflow: 'hidden' },
  cover: { width: 52, height: 52, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  rankText: { color: 'rgba(255,255,255,0.6)', fontSize: 13, fontWeight: '700' },
  songInfo: { flex: 1, gap: 3 },
  songTitle: { fontSize: 15, fontWeight: '700', color: Colors.text },
  songArtist: { fontSize: 12, color: Colors.textMuted },
  songMeta: { flexDirection: 'row', gap: 6, marginTop: 2 },
  metaBadge: {
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  metaText: { fontSize: 10, color: Colors.textMuted, fontWeight: '700' },
  voteWrap: { alignItems: 'center', gap: 4 },
  voteBtn: { width: 44, height: 44, borderRadius: 12, overflow: 'hidden' },
  voteBtnGrad: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
  },
  voteBtnIcon: { fontSize: 18, color: '#fff' },
  voteCount: { fontSize: 11, color: Colors.textMuted, fontWeight: '700' },
  progressBar: {
    height: 3,
    backgroundColor: Colors.border,
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressFill: { height: 3, borderRadius: 2 },
  suggestBtn: {
    marginTop: 8,
    borderWidth: 1.5,
    borderRadius: 14,
    borderStyle: 'dashed',
    padding: 14,
    alignItems: 'center',
  },
  suggestBtnText: { fontWeight: '700', fontSize: 14 },
  playedSection: { marginTop: 24 },
  playedLabel: {
    fontSize: 11,
    fontWeight: '800',
    color: Colors.textFaint,
    letterSpacing: 0.8,
    textTransform: 'uppercase',
    marginBottom: 10,
  },
  playedRow: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingVertical: 6 },
  playedCheck: { color: Colors.green, fontSize: 13 },
  playedTitle: { flex: 1, color: Colors.textMuted, fontSize: 13, fontWeight: '600' },
  playedArtist: { color: Colors.textFaint, fontSize: 12 },
  emptyList: { alignItems: 'center', paddingVertical: 40, gap: 8 },
  modalOverlay: { flex: 1, justifyContent: 'flex-end' },
  modalSheet: {
    backgroundColor: '#13131a',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    padding: 24,
    paddingBottom: 40,
    gap: 12,
  },
  modalHandle: {
    width: 40,
    height: 4,
    borderRadius: 2,
    alignSelf: 'center',
    marginBottom: 8,
    opacity: 0.5,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: Colors.text,
    marginBottom: 4,
  },
  input: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderWidth: 1.5,
    borderRadius: 12,
    padding: 14,
    color: Colors.text,
    fontSize: 15,
  },
  sendBtn: {
    borderRadius: 14,
    padding: 15,
    alignItems: 'center',
    marginTop: 4,
  },
  sendBtnText: { color: '#fff', fontWeight: '800', fontSize: 15 },
  sentWrap: { alignItems: 'center', padding: 32, gap: 12 },
  sentEmoji: { fontSize: 40 },
  sentText: { fontSize: 16, fontWeight: '700', color: Colors.text },
});
