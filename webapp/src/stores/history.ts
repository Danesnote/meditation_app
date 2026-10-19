import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { shouldRecord, type SessionRecord } from '../core/stats'

interface HistoryStore {
  /** 오래된 기록이 먼저. */
  sessions: SessionRecord[]
  add(record: SessionRecord): void
}

/** 명상 기록. 브라우저(localStorage)에 저장된다. */
export const useHistory = create<HistoryStore>()(
  persist(
    (set) => ({
      sessions: [],
      add: (record) => {
        if (!shouldRecord(record)) return
        set((s) => ({ sessions: [...s.sessions, record] }))
      },
    }),
    { name: 'meditation-history' },
  ),
)
