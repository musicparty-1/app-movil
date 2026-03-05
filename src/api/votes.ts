import { api } from './client';

interface VotoPayload {
  songId: string;
  deviceId: string;
}

export async function votar(payload: VotoPayload): Promise<void> {
  await api.post('/votar', payload);
}

interface SugerirPayload {
  eventId: string;
  title: string;
  artist: string;
  suggestedBy?: string;
}

export async function sugerirCancion(payload: SugerirPayload): Promise<void> {
  await api.post('/canciones/sugerir-publico', payload);
}
