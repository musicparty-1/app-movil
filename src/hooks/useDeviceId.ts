import * as SecureStore from 'expo-secure-store';
import { useEffect, useState } from 'react';

const DEVICE_ID_KEY = 'mp_device_id';

function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
}

/**
 * Retorna un deviceId persistente y único por dispositivo.
 * Se guarda en SecureStore (iOS Keychain / Android Keystore).
 */
export function useDeviceId(): string | null {
  const [deviceId, setDeviceId] = useState<string | null>(null);

  useEffect(() => {
    SecureStore.getItemAsync(DEVICE_ID_KEY).then(async (stored) => {
      if (stored) {
        setDeviceId(stored);
      } else {
        const newId = generateId();
        await SecureStore.setItemAsync(DEVICE_ID_KEY, newId);
        setDeviceId(newId);
      }
    });
  }, []);

  return deviceId;
}
