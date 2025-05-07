import 'package:flutter/foundation.dart';

class TimerModel extends ChangeNotifier {
  int _duration = 300; // 기본 5분
  int _remainingTime = 300;
  bool _isRunning = false;
  TimerStatus _status = TimerStatus.ready;

  int get duration => _duration;
  int get remainingTime => _remainingTime;
  bool get isRunning => _isRunning;
  TimerStatus get status => _status;

  void setDuration(int minutes) {
    _duration = minutes * 60;
    _remainingTime = _duration;
    notifyListeners();
  }

  void start() {
    _isRunning = true;
    _status = TimerStatus.running;
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    _status = TimerStatus.paused;
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _remainingTime = _duration;
    _status = TimerStatus.ready;
    notifyListeners();
  }

  void tick() {
    if (_remainingTime > 0) {
      _remainingTime--;
      notifyListeners();
    } else {
      _isRunning = false;
      _status = TimerStatus.completed;
      notifyListeners();
    }
  }
}

enum TimerStatus {
  ready,
  running,
  paused,
  completed,
} 