import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest'
import { TimerEngine, type TimerEvents } from './timerEngine'

/** 타이머 이벤트를 기록만 하는 가짜. */
function recorder() {
  const log: string[] = []
  let endElapsed = 0
  const events: TimerEvents = {
    onMeditationStart: () => log.push('start'),
    onPause: () => log.push('pause'),
    onResume: () => log.push('resume'),
    onInterval: () => log.push('interval'),
    onEnd: (_s, elapsed, completed) => {
      endElapsed = elapsed
      log.push(completed ? 'complete' : 'stop')
    },
  }
  return { log, events, endElapsed: () => endElapsed }
}

describe('TimerEngine', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => vi.useRealTimers())

  const sec = (n: number) => vi.advanceTimersByTime(n * 1000)

  test('기본값은 5분, 대기 상태', () => {
    const t = new TimerEngine()
    expect(t.getSnapshot()).toMatchObject({ status: 'ready', remainingSec: 300 })
  })

  test('실제 경과 시간만큼 남은 시간이 줄어든다', () => {
    const t = new TimerEngine()
    t.start()
    sec(10)
    expect(t.getSnapshot().remainingSec).toBe(290)
    expect(t.elapsedMs()).toBe(10_000)
  })

  test('일시정지 중에는 시간이 흐르지 않고, 계속하면 이어서 진행된다', () => {
    const r = recorder()
    const t = new TimerEngine()
    t.events = r.events
    t.start()
    sec(30)
    t.pause()
    sec(60)
    expect(t.getSnapshot()).toMatchObject({ status: 'paused', remainingSec: 270 })
    t.start()
    sec(20)
    expect(t.getSnapshot().remainingSec).toBe(250)
    expect(r.log).toEqual(['start', 'pause', 'resume'])
  })

  test('중복 시작해도 두 배로 빨라지지 않는다', () => {
    const t = new TimerEngine()
    t.start()
    t.start()
    sec(10)
    expect(t.getSnapshot().remainingSec).toBe(290)
  })

  test('끝나면 완료 상태가 되고 onEnd가 한 번만 호출된다', () => {
    const r = recorder()
    const t = new TimerEngine(1)
    t.events = r.events
    t.start()
    sec(60)
    expect(t.getSnapshot()).toMatchObject({ status: 'completed', remainingSec: 0 })
    sec(60)
    expect(r.log).toEqual(['start', 'complete'])
    expect(r.endElapsed()).toBe(60_000)
    expect(vi.getTimerCount()).toBe(0) // 완료 후 타이머가 정리됨
  })

  test('중간에 그만두면 실제 명상 시간과 함께 중단으로 알린다', () => {
    const r = recorder()
    const t = new TimerEngine()
    t.events = r.events
    t.start()
    sec(90)
    t.reset()
    expect(r.log).toEqual(['start', 'stop'])
    expect(r.endElapsed()).toBe(90_000)
    expect(t.getSnapshot().status).toBe('ready')
  })

  test('restart는 완료 후 같은 시간으로 다시 시작한다', () => {
    const t = new TimerEngine(1)
    t.start()
    sec(120)
    t.restart()
    expect(t.getSnapshot().status).toBe('running')
    sec(15)
    expect(t.getSnapshot().remainingSec).toBe(45)
  })

  test('진행 중에는 시간을 바꿀 수 없다', () => {
    const t = new TimerEngine()
    t.start()
    t.setDuration(10)
    expect(t.getSnapshot().durationMs).toBe(5 * 60_000)
  })

  test('준비 시간이 지나야 명상이 시작되고, 명상 시간에서 빠지지 않는다', () => {
    const r = recorder()
    const t = new TimerEngine()
    t.events = r.events
    t.prepMs = 10_000
    t.start()
    expect(t.getSnapshot().status).toBe('preparing')
    sec(3)
    expect(t.getSnapshot().prepRemainingSec).toBe(7)
    expect(r.log).toEqual([])
    sec(7)
    expect(t.getSnapshot()).toMatchObject({ status: 'running', remainingSec: 300 })
    expect(r.log).toEqual(['start'])
    sec(5)
    expect(t.getSnapshot().remainingSec).toBe(295)
  })

  test('준비 중에 멈추면 기록 없이 처음으로 돌아간다', () => {
    const r = recorder()
    const t = new TimerEngine()
    t.events = r.events
    t.prepMs = 10_000
    t.start()
    sec(3)
    t.pause()
    expect(t.getSnapshot().status).toBe('ready')
    expect(r.log).toEqual([])
  })

  test('중간 종은 간격마다 울리고, 끝나는 순간에는 울리지 않는다', () => {
    const r = recorder()
    const t = new TimerEngine(3)
    t.events = r.events
    t.intervalMs = 60_000
    t.start()
    sec(180)
    expect(r.log).toEqual(['start', 'interval', 'interval', 'complete'])
  })
})
