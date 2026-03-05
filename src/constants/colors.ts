export const Colors = {
  bg: '#08080c',
  surface: 'rgba(255,255,255,0.04)',
  surfaceHover: 'rgba(255,255,255,0.07)',
  border: 'rgba(255,255,255,0.08)',
  borderStrong: 'rgba(255,255,255,0.15)',
  text: '#f7fafc',
  textMuted: '#a0aec0',
  textFaint: '#4a5568',
  purple: '#6b3fff',
  purpleLight: '#9b59ff',
  green: '#22c55e',
  red: '#ef4444',
  white: '#ffffff',
} as const;

export type EventTheme = {
  accent: string;
  accent2: string;
  glow: string;
  gradient: [string, string]; // for LinearGradient
  emoji: string;
};

export const EVENT_THEMES: Record<string, EventTheme> = {
  club:      { accent: '#6b3fff', accent2: '#9b59ff', glow: 'rgba(107,63,255,0.55)', gradient: ['#6b3fff', '#9b59ff'], emoji: '🎧' },
  wedding:   { accent: '#d53f8c', accent2: '#f687b3', glow: 'rgba(213,63,140,0.5)',  gradient: ['#d53f8c', '#f687b3'], emoji: '💍' },
  private:   { accent: '#276749', accent2: '#48bb78', glow: 'rgba(72,187,120,0.5)',  gradient: ['#276749', '#48bb78'], emoji: '🔒' },
  festival:  { accent: '#c05621', accent2: '#ed8936', glow: 'rgba(237,137,54,0.55)', gradient: ['#c05621', '#f6e05e'], emoji: '🎪' },
  corporate: { accent: '#2b6cb0', accent2: '#63b3ed', glow: 'rgba(66,153,225,0.5)',  gradient: ['#2b6cb0', '#63b3ed'], emoji: '🏢' },
  other:     { accent: '#6b3fff', accent2: '#9b59ff', glow: 'rgba(107,63,255,0.55)', gradient: ['#6b3fff', '#9b59ff'], emoji: '🎵' },
};

export function getTheme(eventType?: string): EventTheme {
  return EVENT_THEMES[(eventType ?? 'club').toLowerCase()] ?? EVENT_THEMES.club;
}
