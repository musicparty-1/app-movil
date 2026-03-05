# MusicParty — App Móvil

Expo + React Native + TypeScript. App del **asistente** para votar canciones en tiempo real.

## Requisitos

- Node.js 18+
- [Expo Go](https://expo.dev/go) en el celular (para testear sin compilar)
- O Android Studio / Xcode para el emulador

## Instalación

```bash
cd mobile
npm install
```

## Configuración

Antes de correr, creá un archivo `.env.local` en `mobile/`:

```env
# Para dev local: usá la IP de tu PC en la red WiFi, NO localhost
EXPO_PUBLIC_API_URL=http://192.168.X.X:3000
```

> El celular y la PC tienen que estar en la **misma red WiFi**.
> `localhost` no funciona desde el celular físico.

## Correr

```bash
npm start
```

Escaneá el QR con Expo Go (Android) o la cámara (iOS).

## Estructura

```
mobile/
  app/                   # Rutas (expo-router, estilo Next.js)
    _layout.tsx          # Stack navigator raíz
    index.tsx            # / → HomeScreen
    event/[id].tsx       # /event/:id → VotingScreen
  src/
    api/                 # Clientes HTTP
      client.ts          # Axios con BASE_URL
      events.ts          # GET /eventos/publico, GET /eventos/:id
      votes.ts           # POST /votar, POST /canciones/sugerir-publico
    screens/
      HomeScreen.tsx     # Lista de eventos activos
      VotingScreen.tsx   # Canciones + votar + sugerir
    hooks/
      usePolling.ts      # Polling configurable
      useDeviceId.ts     # ID único por dispositivo (SecureStore)
    types/index.ts       # Tipos compartidos con el backend
    constants/colors.ts  # Paleta + temas por tipo de evento
```

## Roadmap (Phase 2 — DJ Console)

- [ ] Login DJ
- [ ] Lista de mis eventos
- [ ] Crear / editar evento
- [ ] Marcar canciones como reproducidas
- [ ] Push notifications (Expo Notifications)
