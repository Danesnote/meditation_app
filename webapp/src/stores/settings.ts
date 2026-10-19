import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { AmbientSound, BreathingPattern, GuidedMeditation } from '../core/content'

export type ThemeMode = 'system' | 'light' | 'dark'

export interface Settings {
  /** 마지막으로 고른 명상 시간(분). */
  durationMinutes: number
  /** 시작 전 준비 시간(초). 0이면 바로 시작. */
  prepSeconds: number
  startBell: boolean
  /** 중간 종 간격(분). 0이면 사용 안 함. */
  intervalBellMinutes: number
  keepScreenOn: boolean
  ambientSound: AmbientSound
  ambientVolume: number
  guided: GuidedMeditation
  breathing: BreathingPattern
  reminderEnabled: boolean
  /** "HH:MM" */
  reminderTime: string
  themeMode: ThemeMode
}

export const DEFAULT_SETTINGS: Settings = {
  durationMinutes: 5,
  prepSeconds: 10,
  startBell: true,
  intervalBellMinutes: 0,
  keepScreenOn: true,
  ambientSound: 'none',
  ambientVolume: 0.5,
  guided: 'none',
  breathing: 'none',
  reminderEnabled: false,
  reminderTime: '08:00',
  themeMode: 'system',
}

interface SettingsStore extends Settings {
  update(patch: Partial<Settings>): void
}

/** 사용자 설정. 바뀔 때마다 브라우저(localStorage)에 저장된다. */
export const useSettings = create<SettingsStore>()(
  persist(
    (set) => ({
      ...DEFAULT_SETTINGS,
      update: (patch) => set(patch),
    }),
    { name: 'meditation-settings' },
  ),
)
