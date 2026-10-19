/** 명상 한 번의 기록. */
export interface SessionRecord {
  /** 준비 시간 이후 실제로 시작한 시각 (ISO 문자열). */
  startedAt: string
  /** 실제로 명상한 시간(초). */
  seconds: number
  /** 끝까지 마쳤는지, 중간에 그만뒀는지. */
  completed: boolean
}

/** 이보다 짧게 하다 그만둔 명상은 기록하지 않는다. */
export const MIN_RECORD_SECONDS = 60

export const shouldRecord = (r: SessionRecord) => r.completed || r.seconds >= MIN_RECORD_SECONDS

/** 로컬 날짜 키 (YYYY-MM-DD). */
export function dayKey(date: Date) {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

function addDays(date: Date, days: number) {
  const d = new Date(date)
  d.setDate(d.getDate() + days)
  return d
}

export const totalMinutes = (sessions: SessionRecord[]) =>
  Math.floor(sessions.reduce((sum, s) => sum + s.seconds, 0) / 60)

/** 특정 날짜에 명상한 시간(분). */
export function minutesOn(sessions: SessionRecord[], day: Date) {
  const key = dayKey(day)
  return Math.floor(
    sessions.filter((s) => dayKey(new Date(s.startedAt)) === key).reduce((sum, s) => sum + s.seconds, 0) / 60,
  )
}

/** 오늘부터 거슬러 올라간 최근 7일 (오래된 날짜가 먼저). */
export function last7Days(now: Date) {
  return Array.from({ length: 7 }, (_, i) => addDays(now, i - 6))
}

/**
 * 연속으로 명상한 날 수.
 * 오늘 아직 안 했어도 어제까지 이어졌다면 연속 기록이 유지된다.
 */
export function currentStreak(sessions: SessionRecord[], now: Date) {
  const days = new Set(sessions.map((s) => dayKey(new Date(s.startedAt))))
  let day = days.has(dayKey(now)) ? now : addDays(now, -1)
  let streak = 0
  while (days.has(dayKey(day))) {
    streak++
    day = addDays(day, -1)
  }
  return streak
}

/** 가장 길게 이어졌던 연속 기록. */
export function longestStreak(sessions: SessionRecord[]) {
  const days = [...new Set(sessions.map((s) => dayKey(new Date(s.startedAt))))].sort()
  let best = 0
  let run = 0
  let prev: string | null = null
  for (const key of days) {
    run = prev !== null && dayKey(addDays(new Date(`${prev}T12:00:00`), 1)) === key ? run + 1 : 1
    best = Math.max(best, run)
    prev = key
  }
  return best
}

export function formatMinutes(minutes: number) {
  if (minutes < 60) return `${minutes}분`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return m === 0 ? `${h}시간` : `${h}시간 ${m}분`
}
