import { useEffect, useState } from 'react'
import { AppContext, useTimer, type AppServices } from './hooks/useApp'
import { SettingsScreen } from './components/SettingsScreen'
import { StatsScreen } from './components/StatsScreen'
import { TimerScreen } from './components/TimerScreen'
import { useSettings, type ThemeMode } from './stores/settings'

type Tab = 'timer' | 'stats' | 'settings'

const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: 'timer', label: '명상', icon: '◎' },
  { id: 'stats', label: '기록', icon: '▥' },
  { id: 'settings', label: '설정', icon: '⚙' },
]

export function App({ services }: { services: AppServices }) {
  return (
    <AppContext.Provider value={services}>
      <Shell />
    </AppContext.Provider>
  )
}

function Shell() {
  const [tab, setTab] = useState<Tab>('timer')
  const status = useTimer().status
  // 명상 중에는 다른 탭으로 가지 않게 해서 집중을 돕는다.
  const focusMode = status === 'preparing' || status === 'running' || status === 'paused'
  useTheme(useSettings((s) => s.themeMode))

  return (
    <div className="mx-auto min-h-dvh max-w-xl px-4 pb-28">
      <main>
        {/* 탭을 옮겨도 화면 상태가 유지되도록 숨기기만 한다. */}
        <div hidden={tab !== 'timer'}>
          <TimerScreen />
        </div>
        <div hidden={tab !== 'stats'}>{tab === 'stats' && <StatsScreen />}</div>
        <div hidden={tab !== 'settings'}>
          <SettingsScreen />
        </div>
      </main>

      {!focusMode && (
        <nav
          aria-label="메뉴"
          className="fixed inset-x-0 bottom-0 border-t border-line bg-surface pb-[env(safe-area-inset-bottom)]"
        >
          <ul className="mx-auto grid max-w-xl grid-cols-3">
            {TABS.map((t) => (
              <li key={t.id}>
                <button
                  onClick={() => setTab(t.id)}
                  aria-current={tab === t.id ? 'page' : undefined}
                  className="flex w-full flex-col items-center gap-1 py-2.5 text-xs focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-primary"
                >
                  <span
                    aria-hidden
                    className={`rounded-full px-5 py-0.5 text-lg leading-6 ${tab === t.id ? 'bg-primary-soft' : ''}`}
                  >
                    {t.icon}
                  </span>
                  <span className={tab === t.id ? 'font-medium' : 'text-muted'}>{t.label}</span>
                </button>
              </li>
            ))}
          </ul>
        </nav>
      )}
    </div>
  )
}

/** 시스템 / 라이트 / 다크 설정을 <html class="dark">에 반영한다. */
function useTheme(mode: ThemeMode) {
  useEffect(() => {
    const media = window.matchMedia?.('(prefers-color-scheme: dark)')
    const apply = () => {
      const dark = mode === 'dark' || (mode === 'system' && !!media?.matches)
      document.documentElement.classList.toggle('dark', dark)
      document.querySelector('meta[name="theme-color"]')?.setAttribute('content', dark ? '#0f1617' : '#f4f8f8')
    }
    apply()
    media?.addEventListener('change', apply)
    return () => media?.removeEventListener('change', apply)
  }, [mode])
}
