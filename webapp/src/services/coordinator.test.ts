import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest'
import { GUIDED_MEDITATIONS } from '../core/content'
import { TimerEngine } from '../core/timerEngine'
import { useHistory } from '../stores/history'
import { useSettings } from '../stores/settings'
import { FakeAudio, FakeDevice, resetStores } from '../test/fakes'
import { SessionCoordinator } from './coordinator'

describe('SessionCoordinator', () => {
  let audio: FakeAudio
  let device: FakeDevice
  let coordinator: SessionCoordinator | null = null

  beforeEach(() => {
    vi.useFakeTimers()
    resetStores({ prepSeconds: 0 })
    audio = new FakeAudio()
    device = new FakeDevice()
  })
  afterEach(() => {
    coordinator?.dispose()
    vi.useRealTimers()
  })

  const setup = (minutes = 1) => {
    const engine = new TimerEngine(minutes)
    coordinator = new SessionCoordinator(engine, audio, device)
    return engine
  }
  const sec = (n: number) => vi.advanceTimersByTime(n * 1000)

  test('시작과 끝에 종, 배경 소리, 화면 켜두기, 기록이 처리된다', () => {
    useSettings.getState().update({ ambientSound: 'rain' })
    const engine = setup()
    engine.start()
    expect(audio.bells).toEqual([1])
    expect(audio.ambient).toBe('rain')
    expect(device.wakeLock).toEqual([true])

    sec(60)
    expect(audio.bells).toEqual([1, 1]) // 완료 종
    expect(audio.ambient).toBeNull()
    expect(device.wakeLock).toEqual([true, false])
    expect(useHistory.getState().sessions).toHaveLength(1)
  })

  test('일시정지하면 배경 소리도 멈추고, 계속하면 다시 나온다', () => {
    useSettings.getState().update({ ambientSound: 'waves' })
    const engine = setup()
    engine.start()
    engine.pause()
    expect(audio.ambientPaused).toBe(true)
    engine.start()
    expect(audio.ambientPaused).toBe(false)
  })

  test('명상 중에 배경 소리를 바꾸면 바로 반영된다', () => {
    const engine = setup()
    engine.start()
    useSettings.getState().update({ ambientSound: 'brownNoise' })
    expect(audio.ambient).toBe('brownNoise')
  })

  test('중간 종은 작은 볼륨으로 울린다', () => {
    useSettings.getState().update({ intervalBellMinutes: 1 })
    const engine = setup(2)
    engine.start()
    sec(61)
    expect(audio.bells).toEqual([1, 0.5])
  })

  test('가이드 음성은 명상 진행에 맞춰 순서대로 읽는다', () => {
    useSettings.getState().update({ guided: 'breath' })
    const prompts = GUIDED_MEDITATIONS.breath.prompts
    const engine = setup(10)
    engine.start()
    sec(3)
    expect(audio.spoken).toEqual([]) // 시작 종과 겹치지 않게 잠시 기다린다
    sec(2)
    expect(audio.spoken).toEqual([prompts[0].text])
    sec(60) // 10% 지점
    expect(audio.spoken).toEqual([prompts[0].text, prompts[1].text])
  })

  test('다른 탭을 보고 있을 때 끝나면 알림도 보낸다', () => {
    const engine = setup()
    engine.start()
    device.hidden = true
    sec(60)
    expect(device.notifications).toEqual(['명상이 끝났습니다'])
  })

  test('1분 미만으로 하다 그만두면 기록하지 않는다', () => {
    const engine = setup()
    engine.start()
    sec(30)
    engine.reset()
    expect(useHistory.getState().sessions).toHaveLength(0)
  })

  test('리마인더는 권한이 있을 때만 켜지고, 정한 시각 이후 하루 한 번 알린다', async () => {
    vi.setSystemTime(new Date(2026, 9, 16, 7, 59, 0))
    setup()
    device.permission = false
    expect(await coordinator!.setReminder(true)).toBe(false)
    device.permission = true
    expect(await coordinator!.setReminder(true)).toBe(true)
    expect(useSettings.getState().reminderEnabled).toBe(true)

    sec(30)
    expect(device.notifications).toEqual([]) // 아직 08:00 전
    sec(60)
    expect(device.notifications).toEqual(['명상할 시간이에요'])
    sec(600)
    expect(device.notifications).toHaveLength(1) // 하루 한 번
  })
})
