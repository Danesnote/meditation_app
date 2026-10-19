import { useState } from 'react'
import { AMBIENT_SOUNDS, BREATHING_PATTERNS, GUIDED_MEDITATIONS } from '../core/content'
import { formatTime } from '../core/timerEngine'
import { useApp, useTimer } from '../hooks/useApp'
import { useSettings } from '../stores/settings'
import { BreathingGuide } from './BreathingGuide'
import { CustomDurationDialog } from './CustomDurationDialog'
import { ProgressRing } from './ProgressRing'
import { Chip, FilledButton, OutlinedButton, ScreenTitle } from './ui'

/** 선택할 수 있는 명상 시간(분). */
const DURATION_OPTIONS = [1, 3, 5, 10, 15, 20, 30]

export function TimerScreen() {
  const { engine, coordinator } = useApp()
  const timer = useTimer()
  const settings = useSettings()
  const [askingCustom, setAskingCustom] = useState(false)

  const selected = timer.durationMs / 60_000
  const isCustom = !DURATION_OPTIONS.includes(selected)
  const active = timer.status === 'preparing' || timer.status === 'running' || timer.status === 'paused'

  const selectDuration = (minutes: number) => {
    engine.setDuration(minutes)
    settings.update({ durationMinutes: minutes })
  }

  // 시작·계속·다시 시작은 사용자 클릭 안에서 소리 재생 권한을 얻는다.
  const withPrime = (action: () => void) => () => {
    coordinator.prime()
    action()
  }

  const [label, action] = {
    ready: ['시작', withPrime(() => engine.start())],
    preparing: ['취소', () => engine.reset()],
    running: ['일시정지', () => engine.pause()],
    paused: ['계속', withPrime(() => engine.start())],
    completed: ['다시 시작', withPrime(() => engine.restart())],
  }[timer.status] as [string, () => void]

  const summary = [
    settings.ambientSound !== 'none' && AMBIENT_SOUNDS[settings.ambientSound].label,
    settings.guided !== 'none' && GUIDED_MEDITATIONS[settings.guided].label,
    settings.breathing !== 'none' && BREATHING_PATTERNS[settings.breathing].label,
    settings.intervalBellMinutes > 0 && `${settings.intervalBellMinutes}분마다 종`,
  ].filter(Boolean)

  return (
    <section>
      <ScreenTitle>명상 타이머</ScreenTitle>

      <div className="flex flex-wrap justify-center gap-2" role="group" aria-label="명상 시간">
        {DURATION_OPTIONS.map((m) => (
          <Chip key={m} selected={selected === m} disabled={active} onClick={() => selectDuration(m)}>
            {m}분
          </Chip>
        ))}
        <Chip selected={isCustom} disabled={active} onClick={() => setAskingCustom(true)}>
          {isCustom ? `${selected}분` : '✎ 직접 입력'}
        </Chip>
      </div>

      <div className="mt-8">
        <ProgressRing progress={timer.progress}>
          {timer.status === 'preparing' ? (
            <>
              <div className="text-muted">자세를 편안하게</div>
              <div className="text-6xl tabular-nums">{timer.prepRemainingSec}</div>
            </>
          ) : timer.status === 'completed' ? (
            <div className="text-5xl">완료</div>
          ) : timer.status === 'running' && settings.breathing !== 'none' ? (
            <>
              <BreathingGuide pattern={settings.breathing} />
              <div className="pt-1 text-sm tabular-nums text-muted">{formatTime(timer.remainingSec)}</div>
            </>
          ) : (
            <div className="text-5xl tabular-nums" aria-label="남은 시간">
              {formatTime(timer.remainingSec)}
            </div>
          )}
        </ProgressRing>
      </div>

      {summary.length > 0 && <p className="mt-4 text-center text-sm text-muted">{summary.join(' · ')}</p>}

      <div className="mt-6 flex justify-center gap-4">
        <FilledButton onClick={action}>{label}</FilledButton>
        {timer.status !== 'preparing' && (
          <OutlinedButton onClick={() => engine.reset()}>
            {timer.status === 'running' || timer.status === 'paused' ? '그만하기' : '초기화'}
          </OutlinedButton>
        )}
      </div>

      {askingCustom && (
        <CustomDurationDialog
          onClose={(minutes) => {
            setAskingCustom(false)
            if (minutes) selectDuration(minutes)
          }}
        />
      )}
    </section>
  )
}
