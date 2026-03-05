import { api } from './client';
import type { Evento } from '../types';

export async function listarEventosPublicos(): Promise<Evento[]> {
  const { data } = await api.get<Evento[]>('/eventos/publico');
  return data;
}

export async function obtenerEvento(id: string): Promise<Evento> {
  const { data } = await api.get<Evento>(`/eventos/${id}`);
  return data;
}
