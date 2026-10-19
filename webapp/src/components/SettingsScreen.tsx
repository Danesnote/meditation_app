import { useState, type ReactNode } from 'react'
import {
  AMBIENT_SOUNDS,
  BREATHING_PATTERNS,
  GUIDED_MEDITATIONS,
  type AmbientSound,
  type BreathingPattern,
  type GuidedMeditation,
} from '../core/content'
import { useApp } from '../hooks/useApp'
import { useSettings, type ThemeMode } from '../stores/settings'
import { ScreenTitle, Switch } from './ui'

export function SettingsScreen() {
  const s = useSettings()
  const { coordinator, device } = useApp()
  const [message, setMessage] = useState<string | null>(null)

  return (
    <section>
      <ScreenTitle>설정</ScreenTitle>

      <Group title="타이머">
        <Row title="준비 시간">
          <Select
            label="준비 시간"
            value={s.prepSeconds}
            options={{ 0: '없음', 5: '5초', 10: '10초', 15: '15초', 30: '30초' }}
            onChange={(v) => s.update({ prepSeconds: Number(v) })}
          />
        </Row>
        <Row title="시작 종" subtitle="명상을 시작할 때 종을 울립니다">
          <Switch label="시작 종" checked={s.startBell} onChange={(v) => s.update({ startBell: v })} />
        </Row>
        <Row title="중간 종" subtitle="정해진 간격마다 작게 종을 울립니다">
          <Select
            label="중간 종"
            value={s.intervalBellMinutes}
            options={{ 0: '없음', 1: '1분', 2: '2분', 5: '5분', 10: '10분' }}
            onChange={(v) => s.update({ intervalBellMinutes: Number(v) })}
          />
        </Row>
        <Row title="화면 켜두기" subtitle="명상 중에 화면이 꺼지지 않게 합니다">
          <Switch label="화면 켜두기" checked={s.keepScreenOn} onChange={(v) => s.update({ keepScreenOn: v })} />
        </Row>
      </Group>

      <Group title="소리와 가이드">
        <Row title="배경 소리">
          <Select
            label="배경 소리"
            value={s.ambientSound}
            options={labels(AMBIENT_SOUNDS)}
            onChange={(v) => s.update({ ambientSound: v as AmbientSound })}
          />
        </Row>
        {s.ambientSound !== 'none' && (
          <Row title="배경 소리 볼륨">
            <input
              type="range"
              min={0}
              max={1}
              step={0.1}
              value={s.ambientVolume}
              aria-label="배경 소리 볼륨"
              onChange={(e) => s.update({ ambientVolume: Number(e.target.value) })}
              className="w-36 accent-primary"
            />
          </Row>
        )}
        <Row title="가이드 음성" subtitle="명상 흐름에 맞춰 안내 문장을 읽어 줍니다">
          <Select
            label="가이드 음성"
            value={s.guided}
            options={labels(GUIDED_MEDITATIONS)}
            onChange={(v) => s.update({ guided: v as GuidedMeditation })}
          />
        </Row>
        <Row title="호흡 가이드" subtitle="원의 크기로 들숨과 날숨을 안내합니다">
          <Select
            label="호흡 가이드"
            value={s.breathing}
            options={labels(BREATHING_PATTERNS)}
            onChange={(v) => s.update({ breathing: v as BreathingPattern })}
          />
        </Row>
      </Group>

      <Group title="알림">
        <Row
          title="매일 명상 리마인더"
          subtitle={
            device.notificationsSupported()
              ? `앱을 열어 둔 동안 매일 ${s.reminderTime}에 알려드려요`
              : '이 브라우저는 알림을 지원하지 않아요'
          }
        >
          <Switch
            label="매일 명상 리마인더"
            checked={s.reminderEnabled}
            disabled={!device.notificationsSupported()}
            onChange={async (v) => {
              const ok = await coordinator.setReminder(v)
              setMessage(ok ? null : '알림 권한이 없어요. 브라우저 설정에서 허용해 주세요.')
            }}
          />
        </Row>
        {s.reminderEnabled && (
          <Row title="리마인더 시간">
            <input
              type="time"
              value={s.reminderTime}
              aria-label="리마인더 시간"
              onChange={(e) => e.target.value && s.update({ reminderTime: e.target.value })}
              className="rounded-lg border border-line bg-bg px-2 py-1"
            />
          </Row>
        )}
        {message && (
          <p role="alert" className="px-4 pb-2 text-sm text-primary">
            {message}
          </p>
        )}
      </Group>

      <Group title="화면">
        <div className="px-4 py-3">
          <div className="grid grid-cols-3 overflow-hidden rounded-full border border-line" role="radiogroup" aria-label="테마">
            {(
              [
                ['system', '시스템'],
                ['light', '라이트'],
                ['dark', '다크'],
              ] as [ThemeMode, string][]
            ).map(([mode, label]) => (
              <button
                key={mode}
                role="radio"
                aria-checked={s.themeMode === mode}
                onClick={() => s.update({ themeMode: mode })}
                className={`py-2 text-sm transition focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-primary ${
                  s.themeMode === mode ? 'bg-primary-soft font-medium' : 'hover:bg-surface-2'
                }`}
              >
                {s.themeMode === mode && '✓ '}
                {label}
              </button>
            ))}
          </div>
        </div>
      </Group>
    </section>
  )
}

const labels = <K extends string>(record: Record<K, { label: string }>) =>
  Object.fromEntries(Object.entries<{ label: string }>(record).map(([k, v]) => [k, v.label])) as Record<K, string>

function Group({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="mb-4">
      <h2 className="px-4 pt-4 pb-1 text-sm font-medium text-primary">{title}</h2>
      <div className="rounded-xl bg-surface">{children}</div>
    </div>
  )
}

function Row({ title, subtitle, children }: { title: string; subtitle?: string; children: ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-line px-4 py-3 last:border-0">
      <div>
        <div>{title}</div>
        {subtitle && <div className="text-sm text-muted">{subtitle}</div>}
      </div>
      {children}
    </div>
  )
}

function Select<K extends string | number>({
  label,
  value,
  options,
  onChange,
}: {
  label: string
  value: K
  options: Record<K, string>
  onChange: (value: string) => void
}) {
  return (
    <select
      aria-label={label}
      value={String(value)}
      onChange={(e) => onChange(e.target.value)}
      className="shrink-0 rounded-lg border border-line bg-bg px-2 py-1.5"
    >
      {Object.entries<string>(options).map(([k, v]) => (
        <option key={k} value={k}>
          {v}
        </option>
      ))}
    </select>
  )
}
