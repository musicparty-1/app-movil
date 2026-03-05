# 📱 App Móvil — MusicParty

Documentación completa de avances, arquitectura y decisiones técnicas.

---

## Repositorio

**GitHub:** https://github.com/musicparty-1/app-movil  
**Backend (API):** https://github.com/musicparty-1/repo-backend  
**Stack:** Expo ~52 + React Native 0.76 + TypeScript + expo-router

---

## Estado actual

| Módulo | Estado |
|---|---|
| Lista de eventos activos | ✅ Completo |
| Pantalla de votación | ✅ Completo |
| Votar canciones | ✅ Completo |
| Sugerir canciones (público) | ✅ Completo |
| Temas por tipo de evento | ✅ Completo |
| DeviceId único por dispositivo | ✅ Completo |
| Polling automático | ✅ Completo |
| Login DJ | 🔲 Pendiente Phase 2 |
| Consola DJ mobile | 🔲 Pendiente Phase 2 |
| Push notifications | 🔲 Pendiente Phase 2 |
| Publicación en stores | 🔲 Pendiente deploy |

---

## Arquitectura

```
app/                        ← Rutas (expo-router, estilo Next.js)
  _layout.tsx               ← Stack navigator raíz (fondo oscuro #08080c)
  index.tsx                 ← / → HomeScreen
  event/[id].tsx            ← /event/:id → VotingScreen

src/
  api/
    client.ts               ← axios configurado, BASE_URL desde EXPO_PUBLIC_API_URL
    events.ts               ← GET /eventos/publico · GET /eventos/:id
    votes.ts                ← POST /votar · POST /canciones/sugerir-publico
  screens/
    HomeScreen.tsx          ← Lista de eventos con colores temáticos
    VotingScreen.tsx        ← Canciones + votar + barra progreso + modal sugerir
  hooks/
    usePolling.ts           ← Polling configurable (cada N ms, auto-cleanup)
    useDeviceId.ts          ← ID único persistido en SecureStore (iOS Keychain / Android Keystore)
  constants/
    colors.ts               ← Paleta base + 6 temas por tipo de evento
  types/
    index.ts                ← Tipos idénticos al backend (Cancion, Evento)
```

---

## Endpoints del backend que usa la app

| Método | Endpoint | Auth | Descripción |
|---|---|---|---|
| GET | `/eventos/publico` | ❌ público | Lista eventos live + draft |
| GET | `/eventos/:id` | ❌ público | Detalle con canciones y votos |
| POST | `/votar` | ❌ público | Votar una canción (anti-spam por deviceId) |
| POST | `/canciones/sugerir-publico` | ❌ público | Sugerir canción al DJ |

---

## Pantallas

### HomeScreen (`/`)
- Lista todos los eventos activos (live primero, luego draft)
- Cada card muestra: nombre, venue, estado live/draft, conteo de canciones y votos
- Color de acento dinámico según `eventType` (club 🎧, wedding 💍, festival 🎪, etc.)
- Auto-refresh cada 15 segundos
- Pull-to-refresh manual

### VotingScreen (`/event/:id`)
- Canciones ordenadas por cantidad de votos (la más votada arriba)
- Barra de progreso relativa al máximo de votos
- Cover del álbum (Spotify) cuando está disponible
- Badges de BPM y Camelot key para DJs
- Botón de voto con haptic feedback y actualización optimista
- Anti-doble-voto por deviceId (persistido entre sesiones)
- Sección "Ya sonaron" al final (canciones con status `played`)
- Modal de sugerencia de canciones (si el DJ lo habilitó)

---

## Temas visuales por tipo de evento

| Tipo | Color | Emoji |
|---|---|---|
| `club` | Púrpura `#6b3fff` | 🎧 |
| `wedding` | Rosa `#d53f8c` | 💍 |
| `private` | Verde `#276749` | 🔒 |
| `festival` | Naranja `#c05621` | 🎪 |
| `corporate` | Azul `#2b6cb0` | 🏢 |
| `other` | Púrpura `#6b3fff` | 🎵 |

---

## Configuración local (desarrollo)

### Requisitos
- Node.js 18+
- Expo Go en el celular (Android o iOS)
- El celular y la PC en la misma WiFi

### Pasos

```bash
cd mobile
npm install

# Crear mobile/.env.local
# EXPO_PUBLIC_API_URL=http://192.168.X.X:3000
#   ↑ Tu IP local, NO localhost

npm start
# Escaneá el QR con Expo Go
```

---

## Decisiones técnicas

| Decisión | Motivo |
|---|---|
| **expo-router** en lugar de React Navigation manual | Rutas como archivos (estilo Next.js), typed routes, más simple de mantener |
| **Polling** en lugar de WebSocket | El backend no tiene WebSocket Gateway implementado aún; polling cada 8s es suficiente para votación en tiempo real |
| **SecureStore** para deviceId | iOS Keychain + Android Keystore — el deviceId es el mecanismo anti-spam de votos, tiene que ser seguro y persistente |
| **Sin Chakra/NativeBase** | Rendimiento nativo puro con StyleSheet, sin librería de UI pesada |
| **LinearGradient de expo-linear-gradient** | Nativo (no CSS), necesario para los temas de color |
| **Haptics en el voto** | Confirmación táctil inmediata mejora la UX percibida |

---

## Commits

| Hash | Descripción |
|---|---|
| `07beb3b` | `feat: initial commit — attendee voting MVP` |

---

## Roadmap — Phase 2 (DJ mobile)

- [ ] **Login DJ** — pantalla de autenticación, token en SecureStore
- [ ] **Mis eventos** — lista de eventos propios con estadísticas
- [ ] **Crear evento** desde el celular
- [ ] **Consola live** — marcar canciones como reproducidas, reordenar setlist
- [ ] **Push notifications** — aviso cuando una canción sube al top 3
- [ ] **QR compartible** — generar QR con el link del evento para proyectar en el venue
- [ ] **Publicación en stores** — EAS Build → Play Store + App Store

---

## Próximo paso sugerido

1. Instalar Expo Go y probar contra el backend local
2. Hacer deploy del backend (Railway) para que la URL sea real
3. Actualizar `EXPO_PUBLIC_API_URL` a la URL de Railway
4. Empezar Phase 2 (login DJ)
