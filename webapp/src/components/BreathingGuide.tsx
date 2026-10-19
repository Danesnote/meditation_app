import { useEffect, useState } from 'react'
import { BREATH_LABEL, breathStateAt, type BreathingPattern } from '../core/content'
import { useApp } from '../hooks/useApp'

/**
 * 원이 커졌다 작아지며 호흡을 안내한다.
 * 타이머의 경과 시간에 맞춰 움직여서 일시정지하면 함께 멈춘다.
 */
export function BreathingGuide({ pattern }: { pattern: Exclude<BreathingPattern, 'none'> }) {
  const { engine } = useApp()
  const [elapsed, setElapsed] = useState(() => engine.elapsedMs())

  useEffect(() => {
    let frame = requestAnimationFrame(function loop() {
      setElapsed(engine.elapsedMs())
      frame = requestAnimationFrame(loop)
    })
    return () => cancelAnimationFrame(frame)
  }, [engine])

  const state = breathStateAt(pattern, elapsed)
  // ease-in-out
  const eased = state.size < 0.5 ? 2 * state.size ** 2 : 1 - (-2 * state.size + 2) ** 2 / 2
  const scale = 0.5 + 0.45 * eased

  return (
    <div className="relative flex min-h-0 w-full flex-1 items-center justify-center">
      <div
        className="absolute aspect-square h-full max-w-full rounded-full bg-primary-soft"
        style={{ transform: `scale(${scale})` }}
      />
      <div className="relative text-center">
        <div className="text-xl font-medium">{BREATH_LABEL[state.phase.kind]}</div>
        <div className="text-3xl tabular-nums">{state.secondsLeft}</div>
      </div>
    </div>
  )
}
