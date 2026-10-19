import { useState } from 'react'
import {
  currentStreak,
  formatMinutes,
  last7Days,
  longestStreak,
  minutesOn,
  totalMinutes,
  type SessionRecord,
} from '../core/stats'
import { useHistory } from '../stores/history'
import { ScreenTitle } from './ui'

const WEEKDAYS = ['일', '월', '화', '수', '목', '금', '토']
const CHART_HEIGHT = 120

export function StatsScreen() {
  const sessions = useHistory((s) => s.sessions)
  // 기록 탭을 열 때마다 새로 그려지므로, 그 시점의 날짜로 계산한다.
  const [now] = useState(() => new Date())

  const tiles = [
    ['연속 일수', `${currentStreak(sessions, now)}일`],
    ['오늘', formatMinutes(minutesOn(sessions, now))],
    ['총 명상 시간', formatMinutes(totalMinutes(sessions))],
    ['총 횟수', `${sessions.length}회`],
    ['최장 연속', `${longestStreak(sessions)}일`],
  ]

  return (
    <section>
      <ScreenTitle>명상 기록</ScreenTitle>

      <dl className="grid grid-cols-2 gap-3 sm:grid-cols-3">
        {tiles.map(([label, value]) => (
          <div key={label} className="rounded-xl bg-surface-2 p-4">
            <dt className="text-xs text-muted">{label}</dt>
            <dd className="mt-1 text-2xl">{value}</dd>
          </div>
        ))}
      </dl>

      <h2 className="mt-8 mb-3 font-medium">최근 7일</h2>
      <WeekChart sessions={sessions} now={now} />

      <h2 className="mt-8 font-medium">최근 기록</h2>
      {sessions.length === 0 ? (
        <p className="py-6 text-muted">아직 기록이 없어요. 첫 명상을 시작해 보세요.</p>
      ) : (
        <ul>
          {[...sessions]
            .reverse()
            .slice(0, 30)
            .map((s) => (
              <SessionItem key={s.startedAt} record={s} />
            ))}
        </ul>
      )}
    </section>
  )
}

/** 최근 7일 명상 시간 막대 그래프. 막대에 마우스를 올리거나 포커스하면 정확한 값이 나온다. */
function WeekChart({ sessions, now }: { sessions: SessionRecord[]; now: Date }) {
  const days = last7Days(now)
  const minutes = days.map((d) => minutesOn(sessions, d))
  const max = Math.max(0, ...minutes)
  const describe = (i: number) => `${days[i].getMonth() + 1}/${days[i].getDate()} · ${formatMinutes(minutes[i])}`

  return (
    <figure>
      <div className="flex items-end" role="list" aria-label="최근 7일 명상 시간">
        {days.map((day, i) => {
          const isToday = i === 6
          const height = max === 0 ? 2 : Math.max(2, (minutes[i] / max) * CHART_HEIGHT)
          return (
            <div key={i} role="listitem" tabIndex={0} aria-label={describe(i)} className="group relative flex-1 text-center outline-none">
              {/* 툴팁 */}
              <span className="pointer-events-none absolute -top-8 left-1/2 z-10 -translate-x-1/2 rounded-md bg-ink px-2 py-1 text-xs whitespace-nowrap text-bg opacity-0 transition group-hover:opacity-100 group-focus-visible:opacity-100">
                {describe(i)}
              </span>
              <div className="h-5 text-xs text-muted">{isToday ? formatMinutes(minutes[i]) : ''}</div>
              <div className="flex items-end justify-center" style={{ height: CHART_HEIGHT }}>
                <div
                  className={`w-5 rounded-t ${minutes[i] === 0 ? 'bg-track' : 'bg-primary'}`}
                  style={{ height }}
                />
              </div>
              <div className="mt-1.5 text-xs text-muted">{isToday ? '오늘' : WEEKDAYS[day.getDay()]}</div>
            </div>
          )
        })}
      </div>
    </figure>
  )
}

function SessionItem({ record }: { record: SessionRecord }) {
  const t = new Date(record.startedAt)
  const when = `${t.getMonth() + 1}/${t.getDate()} ${String(t.getHours()).padStart(2, '0')}:${String(t.getMinutes()).padStart(2, '0')}`
  const mins = Math.max(1, Math.round(record.seconds / 60))
  return (
    <li className="flex items-center gap-3 border-b border-line py-3 last:border-0">
      <span aria-hidden className="text-lg text-primary">
        {record.completed ? '✓' : '◔'}
      </span>
      <div>
        <div>{mins}분 명상</div>
        <div className="text-sm text-muted">
          {when} · {record.completed ? '완료' : '중간에 마침'}
        </div>
      </div>
    </li>
  )
}
