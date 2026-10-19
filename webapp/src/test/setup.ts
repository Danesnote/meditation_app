import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach, vi } from 'vitest'

// vitest globals를 켜지 않았으므로 테스트마다 화면을 직접 정리한다.
afterEach(cleanup)

// Testing Library는 가짜 타이머를 쓸 때 `jest.advanceTimersByTime`으로 시간을 넘긴다.
// vitest에는 jest 전역이 없어서 그 자리를 채워 준다 (없으면 클릭이 끝나지 않고 멈춘다).
Object.assign(globalThis, { jest: { advanceTimersByTime: (ms: number) => vi.advanceTimersByTime(ms) } })

// jsdom에는 <dialog>의 모달 API가 없다.
HTMLDialogElement.prototype.showModal ??= function (this: HTMLDialogElement) {
  this.open = true
}
HTMLDialogElement.prototype.close ??= function (this: HTMLDialogElement) {
  this.open = false
}
