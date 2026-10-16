/// 호흡 한 구간의 종류. 원의 크기 변화가 달라진다.
enum BreathKind { inhale, hold, exhale, holdEmpty }

class BreathPhase {
  const BreathPhase(this.kind, this.seconds);

  final BreathKind kind;
  final int seconds;

  String get label => switch (kind) {
        BreathKind.inhale => '들이쉬기',
        BreathKind.hold => '멈추기',
        BreathKind.exhale => '내쉬기',
        BreathKind.holdEmpty => '멈추기',
      };
}

/// 호흡 가이드 패턴.
enum BreathingPattern {
  none('사용 안 함', []),
  relaxed('편안한 호흡 (4-6)', [
    BreathPhase(BreathKind.inhale, 4),
    BreathPhase(BreathKind.exhale, 6),
  ]),
  box('박스 호흡 (4-4-4-4)', [
    BreathPhase(BreathKind.inhale, 4),
    BreathPhase(BreathKind.hold, 4),
    BreathPhase(BreathKind.exhale, 4),
    BreathPhase(BreathKind.holdEmpty, 4),
  ]),
  fourSevenEight('4-7-8 호흡', [
    BreathPhase(BreathKind.inhale, 4),
    BreathPhase(BreathKind.hold, 7),
    BreathPhase(BreathKind.exhale, 8),
  ]);

  const BreathingPattern(this.label, this.phases);

  final String label;
  final List<BreathPhase> phases;

  int get cycleSeconds => phases.fold(0, (sum, p) => sum + p.seconds);
}

/// 특정 시점의 호흡 상태.
class BreathState {
  const BreathState(this.phase, this.phaseProgress, this.secondsLeft);

  final BreathPhase phase;

  /// 현재 구간 안에서의 진행률 0.0 ~ 1.0.
  final double phaseProgress;

  /// 현재 구간에서 남은 초 (올림).
  final int secondsLeft;

  /// 원의 크기 비율 (0.0 = 가장 작게, 1.0 = 가장 크게).
  double get size => switch (phase.kind) {
        BreathKind.inhale => phaseProgress,
        BreathKind.hold => 1,
        BreathKind.exhale => 1 - phaseProgress,
        BreathKind.holdEmpty => 0,
      };
}

/// 명상 시작 후 [elapsed]가 지났을 때의 호흡 상태를 계산한다.
BreathState breathStateAt(BreathingPattern pattern, Duration elapsed) {
  assert(pattern != BreathingPattern.none);
  final cycleMs = pattern.cycleSeconds * 1000;
  var t = elapsed.inMilliseconds % cycleMs;
  for (final phase in pattern.phases) {
    final phaseMs = phase.seconds * 1000;
    if (t < phaseMs) {
      return BreathState(phase, t / phaseMs, ((phaseMs - t) / 1000).ceil());
    }
    t -= phaseMs;
  }
  // 반올림 오차로 여기까지 오면 마지막 구간의 끝으로 본다.
  final last = pattern.phases.last;
  return BreathState(last, 1, 0);
}
