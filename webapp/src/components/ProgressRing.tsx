import type { ReactNode } from 'react'

const SIZE = 260
const STROKE = 6
const R = (SIZE - STROKE) / 2
const CIRCUMFERENCE = 2 * Math.PI * R

/** 시간 주위에 진행률을 그리는 원. */
export function ProgressRing({ progress, children }: { progress: number; children: ReactNode }) {
  return (
    <div className="relative mx-auto aspect-square w-full max-w-[260px]">
      <svg viewBox={`0 0 ${SIZE} ${SIZE}`} className="absolute inset-0 -rotate-90" aria-hidden>
        <circle cx={SIZE / 2} cy={SIZE / 2} r={R} fill="none" strokeWidth={STROKE} className="stroke-track" />
        <circle
          cx={SIZE / 2}
          cy={SIZE / 2}
          r={R}
          fill="none"
          strokeWidth={STROKE}
          strokeLinecap="round"
          className="stroke-primary transition-[stroke-dashoffset] duration-300"
          strokeDasharray={CIRCUMFERENCE}
          strokeDashoffset={CIRCUMFERENCE * (1 - progress)}
        />
      </svg>
      <div
        className="absolute inset-4 flex flex-col items-center justify-center"
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={Math.round(progress * 100)}
      >
        {children}
      </div>
    </div>
  )
}
