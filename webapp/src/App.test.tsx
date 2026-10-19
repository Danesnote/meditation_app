import { act, render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest'
import { App } from './App'
import { createServices } from './services/createServices'
import type { AppServices } from './hooks/useApp'
import { useHistory } from './stores/history'
import { useSettings, type Settings } from './stores/settings'
import { FakeAudio, FakeDevice, resetStores } from './test/fakes'

let services: AppServices | null = null

function renderApp(settings: Partial<Settings> = { prepSeconds: 0 }) {
  resetStores(settings)
  const audio = new FakeAudio()
  services = createServices(audio, new FakeDevice())
  render(<App services={services} />)
  const user = userEvent.setup({ delay: null, advanceTimers: (ms) => vi.advanceTimersByTime(ms) })
  return { audio, user }
}

const sec = (n: number) => act(() => vi.advanceTimersByTime(n * 1000))
const button = (name: string) => screen.getByRole('button', { name })

describe('명상 앱 화면', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => {
    services?.coordinator.dispose()
    services?.engine.dispose()
    vi.useRealTimers()
  })

  test('시작하면 시간이 흐르고, 일시정지·그만하기가 동작한다', async () => {
    const { user, audio } = renderApp()
    expect(screen.getByText('05:00')).toBeInTheDocument()

    await user.click(button('시작'))
    expect(audio.unlocked).toBe(true) // 클릭 안에서 소리 재생 권한을 얻음
    await sec(3)
    expect(screen.getByText('04:57')).toBeInTheDocument()
    expect(screen.queryByRole('navigation')).not.toBeInTheDocument() // 명상 중에는 탭 숨김

    await user.click(button('일시정지'))
    await sec(5)
    expect(screen.getByText('04:57')).toBeInTheDocument()
    expect(button('계속')).toBeInTheDocument()

    await user.click(button('그만하기'))
    expect(screen.getByText('05:00')).toBeInTheDocument()
    expect(screen.getByRole('navigation')).toBeInTheDocument()
  })

  test('시간을 고르면 바뀌고, 다음에 열어도 기억한다', async () => {
    const { user } = renderApp()
    await user.click(button('10분'))
    expect(screen.getByText('10:00')).toBeInTheDocument()
    expect(useSettings.getState().durationMinutes).toBe(10)
  })

  test('직접 입력으로 원하는 시간을 정할 수 있다', async () => {
    const { user } = renderApp()
    await user.click(button('✎ 직접 입력'))
    await user.type(screen.getByLabelText('명상 시간(분)'), '45')
    await user.click(button('확인'))
    expect(screen.getByText('45:00')).toBeInTheDocument()
    expect(button('45분')).toHaveAttribute('aria-pressed', 'true')
  })

  test('준비 시간이 끝난 뒤 명상이 시작된다', async () => {
    const { user } = renderApp({ prepSeconds: 5 })
    await user.click(button('시작'))
    await sec(1)
    expect(screen.getByText('자세를 편안하게')).toBeInTheDocument()
    expect(screen.getByText('4')).toBeInTheDocument()
    await sec(5)
    expect(screen.getByText('04:59')).toBeInTheDocument()
  })

  test('완료되면 완료 화면, 종소리, 기록이 남는다', async () => {
    const { user, audio } = renderApp({ prepSeconds: 0, startBell: false })
    await user.click(button('1분'))
    await user.click(button('시작'))
    await sec(61)

    expect(screen.getByText('완료')).toBeInTheDocument()
    expect(button('다시 시작')).toBeInTheDocument()
    expect(audio.bells).toEqual([1])
    expect(useHistory.getState().sessions).toHaveLength(1)

    await user.click(button('기록'))
    expect(screen.getByText('1분 명상')).toBeInTheDocument()
    const streak = screen.getByText('연속 일수').parentElement!
    expect(within(streak).getByText('1일')).toBeInTheDocument()
  })

  test('호흡 가이드를 켜면 명상 중에 안내가 나온다', async () => {
    const { user } = renderApp({ prepSeconds: 0, breathing: 'box' })
    await user.click(button('시작'))
    await sec(1)
    expect(screen.getByText('들이쉬기')).toBeInTheDocument()
    await sec(4)
    expect(screen.getByText('멈추기')).toBeInTheDocument()
  })

  test('설정에서 다크 모드로 바꿀 수 있다', async () => {
    const { user } = renderApp()
    await user.click(button('설정'))
    await user.click(screen.getByRole('radio', { name: '다크' }))
    expect(useSettings.getState().themeMode).toBe('dark')
    expect(document.documentElement).toHaveClass('dark')
  })
})
