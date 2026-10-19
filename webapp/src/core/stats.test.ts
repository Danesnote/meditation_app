import { describe, expect, test } from 'vitest'
import { currentStreak, last7Days, longestStreak, minutesOn, shouldRecord, totalMinutes, type SessionRecord } from './stats'

const now = new Date(2026, 9, 16, 21, 0)
const daysAgo = (n: number, minutes = 10): SessionRecord => {
  const d = new Date(now)
  d.setDate(d.getDate() - n)
  return { startedAt: d.toISOString(), seconds: minutes * 60, completed: true }
}

describe('통계', () => {
  test('1분 미만으로 하다 그만둔 명상은 기록하지 않는다', () => {
    expect(shouldRecord({ startedAt: '', seconds: 30, completed: false })).toBe(false)
    expect(shouldRecord({ startedAt: '', seconds: 30, completed: true })).toBe(true)
  })

  test('연속 일수: 오늘 아직 안 했어도 어제까지 이어지면 유지된다', () => {
    const sessions = [1, 2, 3, 5, 6].map((n) => daysAgo(n))
    expect(currentStreak(sessions, now)).toBe(3)
    expect(longestStreak(sessions)).toBe(3)
  })

  test('연속 일수: 이틀 이상 쉬면 0으로 돌아간다', () => {
    expect(currentStreak([daysAgo(2)], now)).toBe(0)
  })

  test('최근 7일은 오늘로 끝나고, 날짜별 시간을 합산한다', () => {
    const sessions = [daysAgo(0, 5), daysAgo(0, 15), daysAgo(1, 7)]
    const days = last7Days(now)
    expect(days).toHaveLength(7)
    expect(minutesOn(sessions, days[6])).toBe(20)
    expect(minutesOn(sessions, days[5])).toBe(7)
    expect(totalMinutes(sessions)).toBe(27)
  })
})
