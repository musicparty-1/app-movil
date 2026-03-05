import axios from 'axios';

// En desarrollo: cambiá esto a tu IP local (ej: http://192.168.1.X:3000)
// En producción: la URL de Railway
export const BASE_URL = process.env.EXPO_PUBLIC_API_URL ?? 'http://localhost:3000';

export const api = axios.create({
  baseURL: BASE_URL,
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' },
});
