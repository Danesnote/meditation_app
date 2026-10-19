import type { AmbientSound } from '../core/content'
import type { AudioPort } from '../services/audio'
import type { DevicePort } from '../services/device'
import { useHistory } from '../stores/history'
import { DEFAULT_SETTINGS, useSettings } from '../stores/settings'

/** 실제 소리를 내지 않고 호출 기록만 남긴다. */
export class FakeAudio implements AudioPort {
  bells: number[] = []
  spoken: string[] = []
  ambient: AmbientSound | null = null
  ambientPaused = false
  unlocked = false

  unlock() {
    this.unlocked = true
  }
  playBell(volume = 1) {
    this.bells.push(volume)
  }
  startAmbient(sound: AmbientSound) {
    this.ambient = sound
    this.ambientPaused = false
  }
  changeAmbient(sound: AmbientSound) {
    this.ambient = sound
  }
  pauseAmbient() {
    this.ambientPaused = true
  }
  resumeAmbient() {
    this.ambientPaused = false
  }
  stopAmbient() {
    this.ambient = null
  }
  speak(text: string) {
    this.spoken.push(text)
  }
  stopSpeaking() {}
}

export class FakeDevice implements DevicePort {
  wakeLock: boolean[] = []
  notifications: string[] = []
  permission = true
  hidden = false

  setWakeLock(on: boolean) {
    this.wakeLock.push(on)
  }
  notificationsSupported() {
    return true
  }
  async requestNotificationPermission() {
    return this.permission
  }
  notify(title: string) {
    this.notifications.push(title)
  }
  isHidden() {
    return this.hidden
  }
}

/** 테스트마다 저장된 설정·기록을 비운다. */
export function resetStores(settings: Partial<typeof DEFAULT_SETTINGS> = {}) {
  localStorage.clear()
  useSettings.setState({ ...DEFAULT_SETTINGS, ...settings })
  useHistory.setState({ sessions: [] })
}
