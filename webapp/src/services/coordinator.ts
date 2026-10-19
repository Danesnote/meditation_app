import { GUIDED_MEDITATIONS, type GuidedMeditation } from '../core/content'
import { dayKey } from '../core/stats'
import type { TimerEngine, TimerEvents } from '../core/timerEngine'
import { useHistory } from '../stores/history'
import { useSettings } from '../stores/settings'
import type { AudioPort } from './audio'
import type { DevicePort } from './device'

/** 시작 종과 첫 안내 음성이 겹치지 않게 두는 간격. */
const FIRST_PROMPT_DELAY_MS = 4000
const REMINDER_CHECK_MS = 30_000
const LAST_REMINDER_KEY = 'meditation-last-reminder'

/**
 * 타이머 이벤트를 받아 소리·알림·화면 켜두기·기록을 처리한다.
 * TimerEngine은 시간 계산만 하고, 바깥 세계와의 일은 모두 여기서 한다.
 */
export class SessionCoordinator implements TimerEvents {
  private guided: GuidedMeditation = 'none'
  private nextPrompt = 0
  private askedPermission = false
  private reminderTimer: ReturnType<typeof setInterval> | null = null
  private cleanups: (() => void)[] = []
  private readonly engine: TimerEngine
  private readonly audio: AudioPort
  private readonly device: DevicePort

  constructor(engine: TimerEngine, audio: AudioPort, device: DevicePort) {
    this.engine = engine
    this.audio = audio
    this.device = device
    engine.events = this
    this.applyTimerSettings()

    let prev = useSettings.getState()
    this.cleanups.push(
      useSettings.subscribe((s) => {
        this.applyTimerSettings()
        if ((s.ambientSound !== prev.ambientSound || s.ambientVolume !== prev.ambientVolume) && engine.isRunning) {
          audio.changeAmbient(s.ambientSound, s.ambientVolume)
        }
        prev = s
      }),
      engine.subscribe(() => this.speakDuePrompts()),
    )
    this.reminderTimer = setInterval(() => this.checkReminder(), REMINDER_CHECK_MS)
  }

  dispose() {
    this.cleanups.forEach((c) => c())
    if (this.reminderTimer !== null) clearInterval(this.reminderTimer)
  }

  /** 시작 버튼 클릭 안에서 호출한다. 브라우저는 사용자 동작 안에서만 소리·알림 권한을 허락한다. */
  prime() {
    this.audio.unlock()
    if (!this.askedPermission && this.device.notificationsSupported()) {
      this.askedPermission = true
      void this.device.requestNotificationPermission()
    }
  }

  /** 매일 리마인더를 켜거나 끈다. 알림 권한이 거부되면 false. */
  async setReminder(enabled: boolean): Promise<boolean> {
    if (enabled && !(await this.device.requestNotificationPermission())) return false
    useSettings.getState().update({ reminderEnabled: enabled })
    return true
  }

  private applyTimerSettings() {
    const s = useSettings.getState()
    this.engine.prepMs = s.prepSeconds * 1000
    this.engine.intervalMs = s.intervalBellMinutes * 60_000
  }

  // 타이머 이벤트

  onMeditationStart() {
    const s = useSettings.getState()
    this.guided = s.guided
    this.nextPrompt = 0
    if (s.startBell) this.audio.playBell()
    this.audio.startAmbient(s.ambientSound, s.ambientVolume)
    if (s.keepScreenOn) this.device.setWakeLock(true)
  }

  onPause() {
    this.audio.pauseAmbient()
    this.audio.stopSpeaking()
  }

  onResume() {
    this.audio.resumeAmbient()
  }

  onInterval() {
    this.audio.playBell(0.5)
  }

  onEnd(startedAt: number, elapsedMs: number, completed: boolean) {
    this.audio.stopAmbient()
    if (!completed) this.audio.stopSpeaking() // 완료 때는 마지막 안내가 끝까지 나오게 둔다.
    this.device.setWakeLock(false)
    if (completed) {
      this.audio.playBell()
      // 다른 탭을 보고 있으면 알림으로도 알려준다.
      if (this.device.isHidden()) {
        this.device.notify('명상이 끝났습니다', '천천히 눈을 뜨고, 지금의 느낌을 잠시 머금어 보세요.')
      }
    }
    useHistory.getState().add({
      startedAt: new Date(startedAt).toISOString(),
      seconds: Math.round(elapsedMs / 1000),
      completed,
    })
  }

  /** 명상 진행에 맞춰 가이드 문장을 읽는다. */
  private speakDuePrompts() {
    if (!this.engine.isRunning || this.guided === 'none') return
    const prompts = GUIDED_MEDITATIONS[this.guided].prompts
    const elapsed = this.engine.elapsedMs()
    const total = this.engine.getSnapshot().durationMs
    const startBell = useSettings.getState().startBell
    while (this.nextPrompt < prompts.length) {
      let at = prompts[this.nextPrompt].at * total
      if (startBell && at < FIRST_PROMPT_DELAY_MS) at = FIRST_PROMPT_DELAY_MS
      if (elapsed < at) break
      const prompt = prompts[this.nextPrompt++]
      // 여러 문장이 한꺼번에 밀렸으면(탭 복귀 등) 마지막 것만 읽는다.
      const next = prompts[this.nextPrompt]
      if (!next || elapsed < next.at * total) this.audio.speak(prompt.text)
    }
  }

  /** 앱(탭)이 열려 있는 동안, 정한 시각이 되면 하루 한 번 알린다. */
  private checkReminder() {
    const s = useSettings.getState()
    if (!s.reminderEnabled || this.engine.isActive) return
    const now = new Date()
    const hhmm = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    if (hhmm < s.reminderTime) return
    const today = dayKey(now)
    // 오늘 이미 명상했으면 알리지 않는다.
    if (useHistory.getState().sessions.some((r) => dayKey(new Date(r.startedAt)) === today)) return
    try {
      if (localStorage.getItem(LAST_REMINDER_KEY) === today) return
      localStorage.setItem(LAST_REMINDER_KEY, today)
    } catch {
      return
    }
    this.device.notify('명상할 시간이에요', '잠시 멈추고, 몇 분만 숨에 집중해 볼까요?')
  }
}
