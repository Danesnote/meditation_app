// 배경 소리, 가이드 명상 문장, 호흡 패턴 정의.

export type AmbientSound = 'none' | 'rain' | 'waves' | 'whiteNoise' | 'brownNoise'

export const AMBIENT_SOUNDS: Record<AmbientSound, { label: string; file: string | null }> = {
  none: { label: '없음', file: null },
  rain: { label: '빗소리', file: 'rain.wav' },
  waves: { label: '파도', file: 'waves.wav' },
  whiteNoise: { label: '화이트 노이즈', file: 'white_noise.wav' },
  brownNoise: { label: '브라운 노이즈', file: 'brown_noise.wav' },
}

/** 가이드 문장 하나. at은 명상 전체 길이 중 읽기 시작할 위치(0 ~ 1). */
export interface GuidedPrompt {
  at: number
  text: string
}

export type GuidedMeditation = 'none' | 'breath' | 'bodyScan' | 'lovingKindness'

/**
 * 음성으로 읽어 주는 가이드 명상.
 * 문장 위치를 비율로 정해 두어서, 3분이든 30분이든 같은 흐름으로 진행된다.
 */
export const GUIDED_MEDITATIONS: Record<GuidedMeditation, { label: string; prompts: GuidedPrompt[] }> = {
  none: { label: '사용 안 함', prompts: [] },
  breath: {
    label: '호흡 알아차림',
    prompts: [
      { at: 0, text: '편안하게 앉아 눈을 감습니다. 어깨의 힘을 빼고, 자연스럽게 숨을 쉽니다.' },
      { at: 0.1, text: '코끝으로 들어오고 나가는 숨에 주의를 둡니다. 숨을 조절하지 않고, 그대로 바라봅니다.' },
      { at: 0.35, text: '생각이 떠오르면, 떠올랐다는 것만 알아차리고 다시 숨으로 돌아옵니다.' },
      { at: 0.6, text: '들숨과 날숨 사이의 작은 멈춤도 느껴 봅니다.' },
      { at: 0.85, text: '지금 이 순간, 숨 쉬고 있는 나를 그대로 느낍니다.' },
      { at: 0.96, text: '천천히 주의를 몸 전체로 넓히고, 준비가 되면 눈을 뜹니다.' },
    ],
  },
  bodyScan: {
    label: '바디 스캔',
    prompts: [
      { at: 0, text: '편안한 자세로 눈을 감고, 몸이 바닥에 닿는 느낌을 느껴 봅니다.' },
      { at: 0.08, text: '주의를 발끝으로 가져갑니다. 발가락, 발바닥, 발등의 감각을 느껴 봅니다.' },
      { at: 0.22, text: '주의를 종아리와 무릎, 허벅지로 천천히 옮깁니다.' },
      { at: 0.38, text: '골반과 배를 느껴 봅니다. 숨 쉴 때 배가 오르내리는 것을 바라봅니다.' },
      { at: 0.52, text: '가슴과 등, 어깨로 주의를 옮깁니다. 긴장이 있다면 숨과 함께 내려놓습니다.' },
      { at: 0.66, text: '팔과 손, 손가락 끝까지 느껴 봅니다.' },
      { at: 0.78, text: '목과 얼굴, 턱과 눈 주변의 힘을 풀어 줍니다.' },
      { at: 0.88, text: '이제 몸 전체를 하나로 느껴 봅니다.' },
      { at: 0.96, text: '손가락과 발가락을 살짝 움직이고, 준비가 되면 눈을 뜹니다.' },
    ],
  },
  lovingKindness: {
    label: '자애 명상',
    prompts: [
      { at: 0, text: '편안하게 앉아 눈을 감고, 몇 번 깊게 숨을 쉽니다.' },
      { at: 0.1, text: '마음속으로 나에게 말해 봅니다. 내가 평안하기를. 내가 건강하기를. 내가 행복하기를.' },
      { at: 0.3, text: '소중한 사람 한 명을 떠올립니다. 당신이 평안하기를. 당신이 행복하기를.' },
      { at: 0.5, text: '잘 알지 못하는 사람을 떠올립니다. 그 사람도 평안하고 행복하기를 바랍니다.' },
      { at: 0.7, text: '어려운 관계의 사람을 떠올려 봅니다. 할 수 있는 만큼만, 그 사람도 평안하기를 바랍니다.' },
      { at: 0.85, text: '이제 모든 존재에게 마음을 넓힙니다. 모든 존재가 평안하고 행복하기를.' },
      { at: 0.96, text: '따뜻한 마음을 간직한 채, 준비가 되면 눈을 뜹니다.' },
    ],
  },
}

// 호흡

export type BreathKind = 'inhale' | 'hold' | 'exhale' | 'holdEmpty'

export interface BreathPhase {
  kind: BreathKind
  seconds: number
}

export type BreathingPattern = 'none' | 'relaxed' | 'box' | 'fourSevenEight'

export const BREATHING_PATTERNS: Record<BreathingPattern, { label: string; phases: BreathPhase[] }> = {
  none: { label: '사용 안 함', phases: [] },
  relaxed: {
    label: '편안한 호흡 (4-6)',
    phases: [
      { kind: 'inhale', seconds: 4 },
      { kind: 'exhale', seconds: 6 },
    ],
  },
  box: {
    label: '박스 호흡 (4-4-4-4)',
    phases: [
      { kind: 'inhale', seconds: 4 },
      { kind: 'hold', seconds: 4 },
      { kind: 'exhale', seconds: 4 },
      { kind: 'holdEmpty', seconds: 4 },
    ],
  },
  fourSevenEight: {
    label: '4-7-8 호흡',
    phases: [
      { kind: 'inhale', seconds: 4 },
      { kind: 'hold', seconds: 7 },
      { kind: 'exhale', seconds: 8 },
    ],
  },
}

export const BREATH_LABEL: Record<BreathKind, string> = {
  inhale: '들이쉬기',
  hold: '멈추기',
  exhale: '내쉬기',
  holdEmpty: '멈추기',
}

export interface BreathState {
  phase: BreathPhase
  /** 현재 구간 안에서의 진행률 0 ~ 1. */
  phaseProgress: number
  /** 현재 구간에서 남은 초 (올림). */
  secondsLeft: number
  /** 원의 크기 비율 (0 = 가장 작게, 1 = 가장 크게). */
  size: number
}

/** 명상 시작 후 elapsedMs가 지났을 때의 호흡 상태. */
export function breathStateAt(pattern: Exclude<BreathingPattern, 'none'>, elapsedMs: number): BreathState {
  const { phases } = BREATHING_PATTERNS[pattern]
  const cycleMs = phases.reduce((sum, p) => sum + p.seconds, 0) * 1000
  let t = elapsedMs % cycleMs
  for (const phase of phases) {
    const phaseMs = phase.seconds * 1000
    if (t < phaseMs) {
      const p = t / phaseMs
      return { phase, phaseProgress: p, secondsLeft: Math.ceil((phaseMs - t) / 1000), size: sizeOf(phase.kind, p) }
    }
    t -= phaseMs
  }
  const last = phases[phases.length - 1]
  return { phase: last, phaseProgress: 1, secondsLeft: 0, size: sizeOf(last.kind, 1) }
}

function sizeOf(kind: BreathKind, progress: number) {
  switch (kind) {
    case 'inhale':
      return progress
    case 'hold':
      return 1
    case 'exhale':
      return 1 - progress
    case 'holdEmpty':
      return 0
  }
}
