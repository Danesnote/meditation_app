import { AMBIENT_SOUNDS, type AmbientSound } from '../core/content'

/** 종소리, 배경 소리, 가이드 음성. 테스트에서는 가짜 구현으로 바꿔 끼운다. */
export interface AudioPort {
  /** 사용자 클릭 안에서 호출해야 브라우저가 소리 재생을 허락한다. */
  unlock(): void
  playBell(volume?: number): void
  startAmbient(sound: AmbientSound, volume: number): void
  changeAmbient(sound: AmbientSound, volume: number): void
  pauseAmbient(): void
  resumeAmbient(): void
  stopAmbient(): void
  speak(text: string): void
  stopSpeaking(): void
}

const soundUrl = (file: string) => `${import.meta.env.BASE_URL}sounds/${file}`
const FADE_S = 0.6

/**
 * Web Audio API로 소리를 낸다.
 * <audio loop>는 반복할 때 틈이 생겨서, 배경 소리는 AudioBufferSourceNode로 이음매 없이 반복한다.
 */
export class WebAudio implements AudioPort {
  private ctx: AudioContext | null = null
  private buffers = new Map<string, Promise<AudioBuffer>>()
  private ambientSource: AudioBufferSourceNode | null = null
  private ambientGain: GainNode | null = null
  private ambientSound: AmbientSound = 'none'
  private ambientVolume = 0.5
  private koreanVoice: SpeechSynthesisVoice | null | undefined

  unlock() {
    if (!this.ctx) this.ctx = new AudioContext()
    if (this.ctx.state === 'suspended') void this.ctx.resume()
    // 첫 재생 전에 미리 불러 둔다.
    void this.load('bell.wav')
  }

  private load(file: string) {
    let buffer = this.buffers.get(file)
    if (!buffer) {
      buffer = fetch(soundUrl(file))
        .then((res) => res.arrayBuffer())
        .then((data) => this.ctx!.decodeAudioData(data))
      buffer.catch((e) => console.warn('소리 파일을 불러오지 못했습니다', file, e))
      this.buffers.set(file, buffer)
    }
    return buffer
  }

  playBell(volume = 1) {
    const ctx = this.ctx
    if (!ctx) return
    void this.load('bell.wav').then((buffer) => {
      const gain = ctx.createGain()
      gain.gain.value = volume
      const source = ctx.createBufferSource()
      source.buffer = buffer
      source.connect(gain).connect(ctx.destination)
      source.start()
    })
  }

  startAmbient(sound: AmbientSound, volume: number) {
    this.stopAmbient()
    this.ambientSound = sound
    this.ambientVolume = volume
    const file = AMBIENT_SOUNDS[sound].file
    const ctx = this.ctx
    if (!file || !ctx) return
    void this.load(file).then((buffer) => {
      if (this.ambientSound !== sound) return // 불러오는 사이 다른 소리로 바뀜
      const gain = ctx.createGain()
      gain.gain.setValueAtTime(0, ctx.currentTime)
      gain.gain.linearRampToValueAtTime(volume, ctx.currentTime + FADE_S)
      const source = ctx.createBufferSource()
      source.buffer = buffer
      source.loop = true
      source.connect(gain).connect(ctx.destination)
      source.start()
      this.ambientSource = source
      this.ambientGain = gain
    })
  }

  /** 명상 중에 배경 소리 설정이 바뀌면 바로 반영한다. */
  changeAmbient(sound: AmbientSound, volume: number) {
    if (sound !== this.ambientSound) return this.startAmbient(sound, volume)
    this.ambientVolume = volume
    this.rampAmbient(volume)
  }

  pauseAmbient() {
    this.rampAmbient(0)
  }

  resumeAmbient() {
    this.rampAmbient(this.ambientVolume)
  }

  stopAmbient() {
    this.ambientSound = 'none'
    const source = this.ambientSource
    if (source && this.ctx) {
      this.rampAmbient(0)
      source.stop(this.ctx.currentTime + FADE_S)
    }
    this.ambientSource = null
    this.ambientGain = null
  }

  private rampAmbient(volume: number) {
    if (!this.ctx || !this.ambientGain) return
    const g = this.ambientGain.gain
    g.cancelScheduledValues(this.ctx.currentTime)
    g.setValueAtTime(g.value, this.ctx.currentTime)
    g.linearRampToValueAtTime(volume, this.ctx.currentTime + FADE_S)
  }

  speak(text: string) {
    if (!('speechSynthesis' in window)) return
    if (this.koreanVoice === undefined) {
      this.koreanVoice = speechSynthesis.getVoices().find((v) => v.lang.startsWith('ko')) ?? null
    }
    const utterance = new SpeechSynthesisUtterance(text)
    utterance.lang = 'ko-KR'
    utterance.rate = 0.85 // 차분하게
    utterance.pitch = 0.95
    if (this.koreanVoice) utterance.voice = this.koreanVoice
    speechSynthesis.speak(utterance)
  }

  stopSpeaking() {
    if ('speechSynthesis' in window) speechSynthesis.cancel()
  }
}
