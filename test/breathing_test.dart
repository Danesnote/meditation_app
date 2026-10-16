import 'package:flutter_test/flutter_test.dart';
import 'package:meditation_app/data/breathing_patterns.dart';

void main() {
  test('박스 호흡: 4초 들숨 → 4초 멈춤 → 4초 날숨 → 4초 멈춤', () {
    BreathState at(int ms) =>
        breathStateAt(BreathingPattern.box, Duration(milliseconds: ms));

    expect(at(0).phase.kind, BreathKind.inhale);
    expect(at(2000).size, closeTo(0.5, 0.01));
    expect(at(5000).phase.kind, BreathKind.hold);
    expect(at(5000).secondsLeft, 3);
    expect(at(10000).phase.kind, BreathKind.exhale);
    expect(at(14000).phase.kind, BreathKind.holdEmpty);
    expect(at(16000).phase.kind, BreathKind.inhale); // 다음 주기
  });

  test('4-7-8 호흡 주기는 19초', () {
    expect(BreathingPattern.fourSevenEight.cycleSeconds, 19);
  });
}
