import { TimerEngine } from '../core/timerEngine'
import type { AppServices } from '../hooks/useApp'
import { useSettings } from '../stores/settings'
import type { AudioPort } from './audio'
import { SessionCoordinator } from './coordinator'
import type { DevicePort } from './device'

/** 타이머·코디네이터를 만든다. 테스트에서는 가짜 오디오·기기를 넣는다. */
export function createServices(audio: AudioPort, device: DevicePort): AppServices {
  const engine = new TimerEngine(useSettings.getState().durationMinutes)
  const coordinator = new SessionCoordinator(engine, audio, device)
  return { engine, coordinator, device }
}
