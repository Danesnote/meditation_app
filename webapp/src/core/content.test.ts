import { expect, test } from 'vitest'
import { BREATHING_PATTERNS, breathStateAt } from './content'

test('박스 호흡: 4초 들숨 → 4초 멈춤 → 4초 날숨 → 4초 멈춤', () => {
  const at = (ms: number) => breathStateAt('box', ms)
  expect(at(0).phase.kind).toBe('inhale')
  expect(at(2000).size).toBeCloseTo(0.5)
  expect(at(5000).phase.kind).toBe('hold')
  expect(at(5000).secondsLeft).toBe(3)
  expect(at(10000).phase.kind).toBe('exhale')
  expect(at(14000).phase.kind).toBe('holdEmpty')
  expect(at(16000).phase.kind).toBe('inhale') // 다음 주기
})

test('4-7-8 호흡 주기는 19초', () => {
  const total = BREATHING_PATTERNS.fourSevenEight.phases.reduce((s, p) => s + p.seconds, 0)
  expect(total).toBe(19)
})
