import { useEffect, useRef } from 'react';

/**
 * Ejecuta `fn` inmediatamente y luego cada `ms` milisegundos.
 * Se limpia automáticamente al desmontar.
 */
export function usePolling(fn: () => void, ms: number, enabled = true) {
  const fnRef = useRef(fn);
  fnRef.current = fn;

  useEffect(() => {
    if (!enabled) return;
    fnRef.current();
    const id = setInterval(() => fnRef.current(), ms);
    return () => clearInterval(id);
  }, [ms, enabled]);
}
