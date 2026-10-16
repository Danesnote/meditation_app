import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/ambient_sounds.dart';
import '../data/guided_scripts.dart';
import '../models/history_model.dart';
import '../models/settings_model.dart';
import '../models/timer_model.dart';
import 'audio_service.dart';
import 'health_service.dart';
import 'notification_service.dart';

/// 타이머 이벤트를 받아 소리·알림·화면 켜두기·기록·건강 앱 연동을 처리한다.
///
/// [TimerModel]은 시간 계산만 하고, 바깥 세계와의 일은 모두 여기서 한다.
class SessionCoordinator extends TimerEvents with WidgetsBindingObserver {
  SessionCoordinator({
    required this.timer,
    required this.settings,
    required this.history,
    required this.audio,
    required this.notifications,
    required this.health,
    Future<void> Function(bool enable)? setWakelock,
  }) : _setWakelock = setWakelock ?? _toggleWakelock {
    timer.events = this;
    timer.addListener(_onTimerChanged);
    settings.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addObserver(this);
    _applyTimerSettings();
    _lastAmbient = (settings.ambientSound, settings.ambientVolume);
  }

  final TimerModel timer;
  final SettingsModel settings;
  final HistoryModel history;
  final AudioService audio;
  final NotificationService notifications;
  final HealthService health;
  final Future<void> Function(bool enable) _setWakelock;

  /// 시작 종과 첫 안내 음성이 겹치지 않게 두는 간격.
  static const _firstPromptDelay = Duration(seconds: 4);

  DateTime? _endsAt;
  bool _inBackground = false;
  bool _completionScheduled = false;
  bool _completionNotified = false;
  bool _askedNotificationPermission = false;
  GuidedMeditation _guided = GuidedMeditation.none;
  int _nextPrompt = 0;
  (AmbientSound, double)? _lastAmbient;

  /// 브라우저나 기기가 거부해도(예: 웹에서 권한 없음) 명상은 계속되도록 실패를 삼킨다.
  static Future<void> _toggleWakelock(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (e) {
      debugPrint('화면 켜두기 실패: $e');
    }
  }

  void dispose() {
    timer.removeListener(_onTimerChanged);
    settings.removeListener(_onSettingsChanged);
    WidgetsBinding.instance.removeObserver(this);
  }

  // 설정

  void _applyTimerSettings() {
    timer.prepTime = Duration(seconds: settings.prepSeconds);
    timer.intervalBell = Duration(minutes: settings.intervalBellMinutes);
  }

  void _onSettingsChanged() {
    _applyTimerSettings();
    final ambient = (settings.ambientSound, settings.ambientVolume);
    if (ambient != _lastAmbient) {
      _lastAmbient = ambient;
      if (timer.isRunning) audio.changeAmbient(ambient.$1, ambient.$2);
    }
  }

  /// 매일 리마인더를 켜거나 끈다. 권한이 거부되면 false.
  Future<bool> setReminder(bool enabled, {TimeOfDay? time}) async {
    if (time != null) settings.reminderTime = time;
    if (!enabled) {
      settings.reminderEnabled = false;
      await notifications.cancelDailyReminder();
      return true;
    }
    if (!await notifications.requestPermission()) return false;
    settings.reminderEnabled = true;
    await notifications.scheduleDailyReminder(settings.reminderTime);
    return true;
  }

  /// 건강 앱 기록을 켜거나 끈다. 권한이 거부되면 false.
  Future<bool> setHealthSync(bool enabled) async {
    if (enabled && !await health.requestPermission()) return false;
    settings.healthSync = enabled;
    return true;
  }

  // 타이머 이벤트

  @override
  void onMeditationStart(DateTime endsAt) {
    _endsAt = endsAt;
    _completionNotified = false;
    _guided = settings.guided;
    _nextPrompt = 0;
    if (settings.startBell) audio.playBell();
    audio.startAmbient(settings.ambientSound, settings.ambientVolume);
    if (settings.keepScreenOn) _setWakelock(true);
    if (!_askedNotificationPermission) {
      _askedNotificationPermission = true;
      notifications.requestPermission();
    }
  }

  @override
  void onPause() {
    audio.pauseAmbient();
    audio.stopSpeaking();
  }

  @override
  void onResume(DateTime endsAt) {
    _endsAt = endsAt;
    audio.resumeAmbient();
  }

  @override
  void onInterval() => audio.playBell(volume: 0.5);

  @override
  void onEnd(DateTime startedAt, Duration elapsed, {required bool completed}) {
    _endsAt = null;
    audio.stopAmbient();
    if (!completed) audio.stopSpeaking(); // 완료 때는 마지막 안내가 끝까지 나오게 둔다.
    _setWakelock(false);

    // 앱이 백그라운드에 있었다면 예약 알림이 이미 종을 울렸다.
    final notified = _completionNotified || (_inBackground && _completionScheduled);
    if (completed && !notified) audio.playBell();
    if (!completed || !_inBackground) {
      notifications.cancelCompletion();
      _completionScheduled = false;
    }

    history.add(SessionRecord(
      startedAt: startedAt,
      seconds: elapsed.inSeconds,
      completed: completed,
    ));
    if (settings.healthSync &&
        elapsed.inSeconds >= HistoryModel.minRecordSeconds) {
      health.recordMindfulness(startedAt, startedAt.add(elapsed));
    }
  }

  /// 명상 진행에 맞춰 가이드 문장을 읽는다.
  void _onTimerChanged() {
    if (!timer.isRunning || _guided == GuidedMeditation.none) return;
    final prompts = _guided.prompts;
    final elapsed = timer.elapsed;
    final total = timer.duration.inMilliseconds;
    while (_nextPrompt < prompts.length) {
      final prompt = prompts[_nextPrompt];
      var at = Duration(milliseconds: (prompt.at * total).round());
      if (settings.startBell && at < _firstPromptDelay) at = _firstPromptDelay;
      if (elapsed < at) break;
      _nextPrompt++;
      // 여러 문장이 한꺼번에 밀렸으면(백그라운드 복귀 등) 마지막 것만 읽는다.
      if (_nextPrompt == prompts.length ||
          elapsed < Duration(milliseconds: (prompts[_nextPrompt].at * total).round())) {
        audio.speak(prompt.text);
      }
    }
  }

  // 앱 생명주기

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        if (_inBackground) return;
        _inBackground = true;
        if (timer.isRunning && _endsAt != null) {
          _completionScheduled = true;
          notifications.scheduleCompletion(_endsAt!);
        }
      case AppLifecycleState.resumed:
        _inBackground = false;
        if (_completionScheduled && _endsAt != null &&
            !clock.now().isBefore(_endsAt!)) {
          _completionNotified = true;
        }
        if (_completionScheduled) {
          _completionScheduled = false;
          notifications.cancelCompletion();
        }
      default:
        break;
    }
  }
}
