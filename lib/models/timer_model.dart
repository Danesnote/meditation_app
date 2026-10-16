import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

/// 타이머에서 일어나는 일을 바깥(소리, 알림, 기록 등)에 알리는 통로.
/// 필요한 것만 골라 override 하면 된다.
abstract class TimerEvents {
  /// 준비 시간이 끝나고 실제 명상이 시작됨. [endsAt]은 끝나는 시각.
  void onMeditationStart(DateTime endsAt) {}
  void onPause() {}
  void onResume(DateTime endsAt) {}

  /// 중간 종 간격마다 호출.
  void onInterval() {}

  /// 명상이 끝나거나 중간에 그만뒀을 때 한 번 호출.
  /// [startedAt]은 준비 시간 이후 실제로 시작한 시각, [elapsed]는 실제 명상 시간.
  void onEnd(DateTime startedAt, Duration elapsed, {required bool completed}) {}
}

/// 명상 타이머 상태.
///
/// 1초마다 숫자를 깎는 대신 "끝나는 시각"을 저장해 두고 남은 시간을 매번 계산한다.
/// 앱이 백그라운드에 있다가 돌아와도 실제 경과 시간이 그대로 반영된다.
class TimerModel extends ChangeNotifier {
  TimerModel({this.events, int minutes = 5})
      : _duration = Duration(minutes: minutes),
        _remaining = Duration(minutes: minutes);

  TimerEvents? events;

  static const _tickInterval = Duration(milliseconds: 200);

  /// 시작 전 준비 시간. 0이면 바로 시작.
  Duration prepTime = Duration.zero;

  /// 중간 종 간격. 0이면 사용 안 함.
  Duration intervalBell = Duration.zero;

  Duration _duration;
  Duration _remaining;
  DateTime? _endTime;
  DateTime? _prepEndTime;
  DateTime? _startedAt;
  int _intervalsRung = 0;
  Timer? _ticker;
  TimerStatus _status = TimerStatus.ready;

  Duration get duration => _duration;
  TimerStatus get status => _status;
  bool get isRunning => _status == TimerStatus.running;

  /// 준비 중이거나 명상 중이거나 일시정지 중 (= 세션이 진행 중).
  bool get isActive =>
      _status == TimerStatus.preparing ||
      _status == TimerStatus.running ||
      _status == TimerStatus.paused;

  /// 화면에 표시할 남은 시간(초). 올림 처리해서 시작 직후에도 05:00으로 보인다.
  int get remainingTime => _ceilSeconds(_remaining);

  /// 준비 시간 중 남은 초.
  int get prepRemaining => _prepEndTime == null
      ? 0
      : _ceilSeconds(_nonNegative(_prepEndTime!.difference(clock.now())));

  /// 실제 명상한 시간. 실행 중이면 지금 시각 기준으로 계산한다.
  Duration get elapsed {
    final remaining = isRunning
        ? _nonNegative(_endTime!.difference(clock.now()))
        : _remaining;
    return _duration - remaining;
  }

  /// 0.0(시작) ~ 1.0(완료) 진행률.
  double get progress => _duration.inMilliseconds == 0
      ? 0
      : 1 - _remaining.inMilliseconds / _duration.inMilliseconds;

  /// 진행 중이 아닐 때만 시간을 바꿀 수 있다.
  void setDuration(int minutes) {
    if (isActive) return;
    _duration = Duration(minutes: minutes);
    _resetState();
    notifyListeners();
  }

  void start() {
    switch (_status) {
      case TimerStatus.preparing || TimerStatus.running:
        return; // 중복 시작 방지
      case TimerStatus.paused:
        _endTime = clock.now().add(_remaining);
        _status = TimerStatus.running;
        _startTicker();
        events?.onResume(_endTime!);
      case TimerStatus.ready || TimerStatus.completed:
        _resetState();
        if (prepTime > Duration.zero) {
          _prepEndTime = clock.now().add(prepTime);
          _status = TimerStatus.preparing;
          _startTicker();
        } else {
          _beginMeditation();
        }
    }
    notifyListeners();
  }

  void pause() {
    if (_status == TimerStatus.preparing) return reset();
    if (!isRunning) return;
    _remaining = _nonNegative(_endTime!.difference(clock.now()));
    _ticker?.cancel();
    _status = TimerStatus.paused;
    events?.onPause();
    notifyListeners();
  }

  /// 처음 상태로 돌린다. 명상 중이었다면 중단으로 기록된다.
  void reset() {
    _endEarlyIfNeeded();
    _resetState();
    notifyListeners();
  }

  /// 완료 후 같은 시간으로 바로 다시 시작한다.
  void restart() {
    _endEarlyIfNeeded();
    _resetState();
    start();
  }

  void _beginMeditation() {
    _prepEndTime = null;
    _startedAt = clock.now();
    _endTime = _startedAt!.add(_remaining);
    _status = TimerStatus.running;
    _startTicker();
    events?.onMeditationStart(_endTime!);
  }

  void _endEarlyIfNeeded() {
    if (_status != TimerStatus.running && _status != TimerStatus.paused) return;
    final spent = elapsed;
    _ticker?.cancel();
    events?.onEnd(_startedAt!, spent, completed: false);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickInterval, (_) => _tick());
  }

  void _resetState() {
    _ticker?.cancel();
    _endTime = null;
    _prepEndTime = null;
    _startedAt = null;
    _intervalsRung = 0;
    _remaining = _duration;
    _status = TimerStatus.ready;
  }

  void _tick() {
    if (_status == TimerStatus.preparing) {
      final before = prepRemaining;
      if (!clock.now().isBefore(_prepEndTime!)) {
        _beginMeditation();
        notifyListeners();
      } else if (prepRemaining != before) {
        notifyListeners();
      }
      return;
    }

    final before = remainingTime;
    _remaining = _nonNegative(_endTime!.difference(clock.now()));

    if (_remaining == Duration.zero) {
      _ticker?.cancel();
      _status = TimerStatus.completed;
      notifyListeners();
      events?.onEnd(_startedAt!, _duration, completed: true);
      return;
    }

    if (intervalBell > Duration.zero) {
      final due = elapsed.inMilliseconds ~/ intervalBell.inMilliseconds;
      if (due > _intervalsRung) {
        _intervalsRung = due;
        events?.onInterval();
      }
    }

    if (remainingTime != before) notifyListeners();
  }

  static int _ceilSeconds(Duration d) => (d.inMilliseconds / 1000).ceil();
  static Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

enum TimerStatus {
  ready,
  preparing,
  running,
  paused,
  completed,
}
