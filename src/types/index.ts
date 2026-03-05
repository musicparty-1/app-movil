// Tipos compartidos con el backend (mirrors de frontend/src/types.ts)

export interface Cancion {
  id: string;
  title: string;
  artist: string;
  status: 'pending' | 'played';
  addedBy: 'dj' | 'audience';
  suggestedBy?: string;
  orderIndex: number;
  playedAt?: string;
  createdAt?: string;
  updatedAt?: string;
  _count: { votes: number };
  spotifyId?: string;
  coverUrl?: string;
  bpm?: number;
  songKey?: number;   // 0-11 (Camelot notation)
  songMode?: number;  // 0=minor, 1=major
  valence?: number;
  energy?: number;
  danceability?: number;
}

export interface Evento {
  id: string;
  name: string;
  venue: string;
  eventType?: 'club' | 'wedding' | 'private' | 'festival' | 'corporate' | 'other';
  status: 'draft' | 'live' | 'finished';
  allowAudienceSuggestions?: boolean;
  createdAt: string;
  updatedAt?: string;
  startedAt?: string;
  finishedAt?: string;
  songs?: Cancion[];
  _count?: { songs: number; votes: number };
}
