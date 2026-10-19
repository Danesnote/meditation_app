/** 화면 켜두기와 알림. 브라우저마다 지원 여부가 달라서 실패해도 명상은 계속된다. */
export interface DevicePort {
  setWakeLock(on: boolean): void
  notificationsSupported(): boolean
  requestNotificationPermission(): Promise<boolean>
  notify(title: string, body: string): void
  isHidden(): boolean
}

export class BrowserDevice implements DevicePort {
  private wakeLock: WakeLockSentinel | null = null
  private wantWakeLock = false

  constructor() {
    // 탭을 벗어나면 브라우저가 Wake Lock을 풀기 때문에, 돌아오면 다시 잡는다.
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible' && this.wantWakeLock) void this.acquire()
    })
  }

  setWakeLock(on: boolean) {
    this.wantWakeLock = on
    if (on) void this.acquire()
    else {
      void this.wakeLock?.release().catch(() => {})
      this.wakeLock = null
    }
  }

  private async acquire() {
    if (!('wakeLock' in navigator) || this.wakeLock) return
    try {
      this.wakeLock = await navigator.wakeLock.request('screen')
      this.wakeLock.addEventListener('release', () => (this.wakeLock = null))
    } catch (e) {
      console.info('화면 켜두기를 사용할 수 없습니다:', e)
    }
  }

  notificationsSupported() {
    return 'Notification' in window
  }

  async requestNotificationPermission() {
    if (!this.notificationsSupported()) return false
    if (Notification.permission === 'granted') return true
    if (Notification.permission === 'denied') return false
    return (await Notification.requestPermission()) === 'granted'
  }

  notify(title: string, body: string) {
    if (!this.notificationsSupported() || Notification.permission !== 'granted') return
    const options: NotificationOptions = { body, icon: `${import.meta.env.BASE_URL}icon-192.png`, tag: title }
    // 모바일 Chrome은 new Notification()을 막고 서비스 워커를 통한 알림만 허용한다.
    const fallback = () => void new Notification(title, options)
    if (!navigator.serviceWorker) return fallback()
    navigator.serviceWorker.getRegistration().then(
      (reg) => (reg ? reg.showNotification(title, options) : fallback()),
      fallback,
    )
  }

  isHidden() {
    return document.visibilityState === 'hidden'
  }
}
