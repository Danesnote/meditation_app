import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

/// 명상 타이머 상태.
///
/// 1초마다 숫자를 깎는 대신 "끝나는 시각"을 저장해 두고 남은 시간을 매번 계산한다.
/// 앱이 백그라운드에 있다가 돌아와도 실제 경과 시간이 그대로 반영된다.
class TimerModel extends ChangeNotifier {
  TimerModel({this.onComplete});

  /// 타이머가 끝났을 때 한 번 호출된다 (알림음 재생 등).
  final VoidCallback? onComplete;

  static const _tickInterval = Duration(milliseconds: 200);

  Duration _duration = const Duration(minutes: 5); // 기본 5분
  Duration _remaining = const Duration(minutes: 5);
  DateTime? _endTime;
  Timer? _ticker;
  TimerStatus _status = TimerStatus.ready;

  Duration get duration => _duration;
  TimerStatus get status => _status;
  bool get isRunning => _status == TimerStatus.running;

  /// 화면에 표시할 남은 시간(초). 올림 처리해서 시작 직후에도 05:00으로 보인다.
  int get remainingTime => (_remaining.inMilliseconds / 1000).ceil();

  /// 0.0(시작) ~ 1.0(완료) 진행률.
  double get progress => _duration.inMilliseconds == 0
      ? 0
      : 1 - _remaining.inMilliseconds / _duration.inMilliseconds;

  /// 실행 중이 아닐 때만 시간을 바꿀 수 있다.
  void setDuration(int minutes) {
    if (isRunning) return;
    _duration = Duration(minutes: minutes);
    _resetState();
    notifyListeners();
  }

  void start() {
    if (isRunning) return; // 중복 시작 방지
    if (_status == TimerStatus.completed) _remaining = _duration;
    _endTime = clock.now().add(_remaining);
    _status = TimerStatus.running;
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickInterval, (_) => _tick());
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;
    _updateRemaining();
    _ticker?.cancel();
    _status = TimerStatus.paused;
    notifyListeners();
  }

  void reset() {
    _resetState();
    notifyListeners();
  }

  /// 완료 후 같은 시간으로 바로 다시 시작한다.
  void restart() {
    _resetState();
    start();
  }

  void _resetState() {
    _ticker?.cancel();
    _endTime = null;
    _remaining = _duration;
    _status = TimerStatus.ready;
  }

  void _updateRemaining() {
    final left = _endTime!.difference(clock.now());
    _remaining = left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    final before = remainingTime;
    _updateRemaining();
    if (_remaining == Duration.zero) {
      _ticker?.cancel();
      _status = TimerStatus.completed;
      notifyListeners();
      onComplete?.call();
    } else if (remainingTime != before) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

enum TimerStatus {
  ready,
  running,
  paused,
  completed,
}
