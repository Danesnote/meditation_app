import type { ButtonHTMLAttributes, ReactNode } from 'react'

export function FilledButton(props: ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      {...props}
      className="min-w-24 rounded-full bg-primary px-6 py-2.5 font-medium text-on-primary transition hover:opacity-90 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:opacity-40"
    />
  )
}

export function OutlinedButton(props: ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      {...props}
      className="min-w-24 rounded-full border border-line px-6 py-2.5 font-medium text-primary transition hover:bg-surface-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
    />
  )
}

export function Chip({
  selected,
  disabled,
  onClick,
  children,
}: {
  selected: boolean
  disabled?: boolean
  onClick: () => void
  children: ReactNode
}) {
  return (
    <button
      type="button"
      aria-pressed={selected}
      disabled={disabled}
      onClick={onClick}
      className={`rounded-lg border px-3 py-1.5 text-sm transition focus-visible:outline-2 focus-visible:outline-primary disabled:opacity-40 ${
        selected ? 'border-transparent bg-primary-soft font-medium' : 'border-line hover:bg-surface-2'
      }`}
    >
      {selected && <span aria-hidden>✓ </span>}
      {children}
    </button>
  )
}

export function Switch({
  checked,
  disabled,
  onChange,
  label,
}: {
  checked: boolean
  disabled?: boolean
  onChange: (checked: boolean) => void
  label: string
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`relative h-7 w-12 shrink-0 rounded-full transition focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:opacity-40 ${
        checked ? 'bg-primary' : 'bg-track'
      }`}
    >
      <span
        className={`absolute top-1 left-1 h-5 w-5 rounded-full shadow transition ${
          checked ? 'translate-x-5 bg-on-primary' : 'bg-muted'
        }`}
      />
    </button>
  )
}

export function ScreenTitle({ children }: { children: ReactNode }) {
  return <h1 className="py-4 text-center text-lg font-medium">{children}</h1>
}
