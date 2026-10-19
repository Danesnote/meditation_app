import { useEffect, useRef, useState } from 'react'
import { FilledButton, OutlinedButton } from './ui'

/** 직접 입력할 수 있는 최대 시간(분). */
export const MAX_CUSTOM_MINUTES = 180

/** 명상 시간을 분 단위로 직접 입력받는 대화상자. */
export function CustomDurationDialog({ onClose }: { onClose: (minutes: number | null) => void }) {
  const dialog = useRef<HTMLDialogElement>(null)
  const [value, setValue] = useState('')
  const minutes = Number(value)
  const valid = Number.isInteger(minutes) && minutes >= 1 && minutes <= MAX_CUSTOM_MINUTES

  useEffect(() => {
    const d = dialog.current
    if (d && !d.open) d.showModal?.()
  }, [])

  return (
    <dialog
      ref={dialog}
      aria-labelledby="custom-duration-title"
      onCancel={() => onClose(null)}
      className="m-auto w-[min(90vw,22rem)] rounded-2xl bg-surface p-6 text-ink backdrop:bg-black/40"
    >
      <form
        method="dialog"
        onSubmit={(e) => {
          e.preventDefault()
          if (valid) onClose(minutes)
        }}
      >
        <h2 id="custom-duration-title" className="text-lg font-medium">
          명상 시간 직접 입력
        </h2>
        <label className="mt-4 flex items-center gap-2">
          <input
            autoFocus
            inputMode="numeric"
            pattern="[0-9]*"
            value={value}
            onChange={(e) => setValue(e.target.value.replace(/\D/g, ''))}
            aria-label="명상 시간(분)"
            className="w-full rounded-lg border border-line bg-bg px-3 py-2 text-lg tabular-nums outline-primary"
          />
          <span>분</span>
        </label>
        <p className="mt-1 text-sm text-muted">1 ~ {MAX_CUSTOM_MINUTES}분</p>
        <div className="mt-6 flex justify-end gap-2">
          <OutlinedButton type="button" onClick={() => onClose(null)}>
            취소
          </OutlinedButton>
          <FilledButton type="submit" disabled={!valid}>
            확인
          </FilledButton>
        </div>
      </form>
    </dialog>
  )
}
