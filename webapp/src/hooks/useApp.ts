import { createContext, useContext, useSyncExternalStore } from 'react'
import type { TimerEngine } from '../core/timerEngine'
import type { SessionCoordinator } from '../services/coordinator'
import type { DevicePort } from '../services/device'

export interface AppServices {
  engine: TimerEngine
  coordinator: SessionCoordinator
  device: DevicePort
}

export const AppContext = createContext<AppServices | null>(null)

export function useApp() {
  const services = useContext(AppContext)
  if (!services) throw new Error('AppContext가 없습니다')
  return services
}

/** 타이머 상태를 구독한다. 남은 초가 바뀔 때만 다시 그린다. */
export function useTimer() {
  const { engine } = useApp()
  return useSyncExternalStore(engine.subscribe, engine.getSnapshot)
}
