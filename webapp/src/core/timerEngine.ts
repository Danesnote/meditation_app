export type TimerStatus = 'ready' | 'preparing' | 'running' | 'paused' | 'completed'

/** 타이머에서 일어나는 일을 바깥(소리, 알림, 기록 등)에 알리는 통로. */
export interface TimerEvents {
  /** 준비 시간이 끝나고 실제 명상이 시작됨. endsAt은 끝나는 시각(ms). */
  onMeditationStart?(endsAt: number): void
  onPause?(): void
  onResume?(endsAt: number): void
  /** 중간 종 간격마다 호출. */
  onInterval?(): void
  /** 명상이 끝나거나 중간에 그만뒀을 때 한 번 호출. elapsedMs는 실제 명상 시간. */
  onEnd?(startedAt: number, elapsedMs: number, completed: boolean): void
}

/** 화면이 그리는 데 필요한 값. 바뀔 때마다 새 객체가 만들어진다. */
export interface TimerSnapshot {
  status: TimerStatus
  durationMs: number
  /** 남은 시간(초). 올림 처리해서 시작 직후에도 05:00으로 보인다. */
  remainingSec: number
  /** 준비 시간 중 남은 초. */
  prepRemainingSec: number
  /** 0(시작) ~ 1(완료). */
  progress: number
}

const TICK_MS = 200
const ceilSec = (ms: number) => Math.ceil(ms / 1000)

/**
 * 명상 타이머.
 *
 * 1초마다 숫자를 깎는 대신 "끝나는 시각"을 저장해 두고 남은 시간을 매번 계산한다.
 * 탭이 백그라운드에 있다가 돌아와도 실제 경과 시간이 그대로 반영된다.
 */
export class TimerEngine {
  events: TimerEvents = {}
  /** 시작 전 준비 시간(ms). 0이면 바로 시작. */
  prepMs = 0
  /** 중간 종 간격(ms). 0이면 사용 안 함. */
  intervalMs = 0

  private durationMs: number
  private remainingMs: number
  private status: TimerStatus = 'ready'
  private endTime: number | null = null
  private prepEndTime: number | null = null
  private startedAt: number | null = null
  private intervalsRung = 0
  private ticker: ReturnType<typeof setInterval> | null = null
  private listeners = new Set<() => void>()
  private snapshot: TimerSnapshot

  constructor(minutes = 5) {
    this.durationMs = minutes * 60_000
    this.remainingMs = this.durationMs
    this.snapshot = this.makeSnapshot()
  }

  // useSyncExternalStore 용

  subscribe = (listener: () => void) => {
    this.listeners.add(listener)
    return () => this.listeners.delete(listener)
  }

  getSnapshot = () => this.snapshot

  get isActive() {
    return this.status === 'preparing' || this.status === 'running' || this.status === 'paused'
  }

  get isRunning() {
    return this.status === 'running'
  }

  /** 실제 명상한 시간(ms). 실행 중이면 지금 시각 기준으로 계산한다. */
  elapsedMs(): number {
    const remaining = this.isRunning ? Math.max(0, this.endTime! - Date.now()) : this.remainingMs
    return this.durationMs - remaining
  }

  /** 진행 중이 아닐 때만 시간을 바꿀 수 있다. */
  setDuration(minutes: number) {
    if (this.isActive) return
    this.durationMs = minutes * 60_000
    this.resetState()
    this.notify()
  }

  start() {
    switch (this.status) {
      case 'preparing':
      case 'running':
        return // 중복 시작 방지
      case 'paused':
        this.endTime = Date.now() + this.remainingMs
        this.status = 'running'
        this.startTicker()
        this.events.onResume?.(this.endTime)
        break
      case 'ready':
      case 'completed':
        this.resetState()
        if (this.prepMs > 0) {
          this.prepEndTime = Date.now() + this.prepMs
          this.status = 'preparing'
          this.startTicker()
        } else {
          this.beginMeditation()
        }
    }
    this.notify()
  }

  pause() {
    if (this.status === 'preparing') return this.reset()
    if (!this.isRunning) return
    this.remainingMs = Math.max(0, this.endTime! - Date.now())
    this.stopTicker()
    this.status = 'paused'
    this.events.onPause?.()
    this.notify()
  }

  /** 처음 상태로 돌린다. 명상 중이었다면 중단으로 알린다. */
  reset() {
    this.endEarlyIfNeeded()
    this.resetState()
    this.notify()
  }

  /** 완료 후 같은 시간으로 바로 다시 시작한다. */
  restart() {
    this.endEarlyIfNeeded()
    this.resetState()
    this.start()
  }

  dispose() {
    this.stopTicker()
    this.listeners.clear()
  }

  private beginMeditation() {
    this.prepEndTime = null
    this.startedAt = Date.now()
    this.endTime = this.startedAt + this.remainingMs
    this.status = 'running'
    this.startTicker()
    this.events.onMeditationStart?.(this.endTime)
  }

  private endEarlyIfNeeded() {
    if (this.status !== 'running' && this.status !== 'paused') return
    const spent = this.elapsedMs()
    this.stopTicker()
    this.events.onEnd?.(this.startedAt!, spent, false)
  }

  private startTicker() {
    this.stopTicker()
    this.ticker = setInterval(() => this.tick(), TICK_MS)
  }

  private stopTicker() {
    if (this.ticker !== null) clearInterval(this.ticker)
    this.ticker = null
  }

  private resetState() {
    this.stopTicker()
    this.endTime = null
    this.prepEndTime = null
    this.startedAt = null
    this.intervalsRung = 0
    this.remainingMs = this.durationMs
    this.status = 'ready'
  }

  private tick() {
    const now = Date.now()

    if (this.status === 'preparing') {
      if (now >= this.prepEndTime!) {
        this.beginMeditation()
        this.notify()
      } else if (ceilSec(this.prepEndTime! - now) !== this.snapshot.prepRemainingSec) {
        this.notify()
      }
      return
    }

    this.remainingMs = Math.max(0, this.endTime! - now)

    if (this.remainingMs === 0) {
      this.stopTicker()
      this.status = 'completed'
      this.notify()
      this.events.onEnd?.(this.startedAt!, this.durationMs, true)
      return
    }

    if (this.intervalMs > 0) {
      const due = Math.floor(this.elapsedMs() / this.intervalMs)
      if (due > this.intervalsRung) {
        this.intervalsRung = due
        this.events.onInterval?.()
      }
    }

    if (ceilSec(this.remainingMs) !== this.snapshot.remainingSec) this.notify()
  }

  private makeSnapshot(): TimerSnapshot {
    return {
      status: this.status,
      durationMs: this.durationMs,
      remainingSec: ceilSec(this.remainingMs),
      prepRemainingSec: this.prepEndTime === null ? 0 : ceilSec(Math.max(0, this.prepEndTime - Date.now())),
      progress: this.durationMs === 0 ? 0 : 1 - this.remainingMs / this.durationMs,
    }
  }

  private notify() {
    this.snapshot = this.makeSnapshot()
    for (const listener of this.listeners) listener()
  }
}

export function formatTime(seconds: number) {
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}
