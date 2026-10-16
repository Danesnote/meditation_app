import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ambient_sounds.dart';
import '../data/breathing_patterns.dart';
import '../data/guided_scripts.dart';

/// 사용자 설정. 바뀔 때마다 기기에 저장된다.
class SettingsModel extends ChangeNotifier {
  SettingsModel(this._prefs);

  final SharedPreferences _prefs;

  T _enum<T extends Enum>(String key, List<T> values, T fallback) {
    final name = _prefs.getString(key);
    return values.where((v) => v.name == name).firstOrNull ?? fallback;
  }

  Future<void> _save(String key, Object value) async {
    // set 호출 시점에 메모리 캐시가 바로 바뀌므로, 저장 완료를 기다리기 전에 알린다.
    final saved = switch (value) {
      bool v => _prefs.setBool(key, v),
      int v => _prefs.setInt(key, v),
      double v => _prefs.setDouble(key, v),
      Enum v => _prefs.setString(key, v.name),
      _ => throw ArgumentError.value(value, key),
    };
    notifyListeners();
    await saved;
  }

  // 타이머

  /// 마지막으로 고른 명상 시간(분).
  int get durationMinutes => _prefs.getInt('durationMinutes') ?? 5;
  set durationMinutes(int v) => _save('durationMinutes', v);

  /// 시작 전 준비 시간(초). 0이면 바로 시작.
  int get prepSeconds => _prefs.getInt('prepSeconds') ?? 10;
  set prepSeconds(int v) => _save('prepSeconds', v);

  bool get startBell => _prefs.getBool('startBell') ?? true;
  set startBell(bool v) => _save('startBell', v);

  /// 중간 종 간격(분). 0이면 사용 안 함.
  int get intervalBellMinutes => _prefs.getInt('intervalBellMinutes') ?? 0;
  set intervalBellMinutes(int v) => _save('intervalBellMinutes', v);

  bool get keepScreenOn => _prefs.getBool('keepScreenOn') ?? true;
  set keepScreenOn(bool v) => _save('keepScreenOn', v);

  // 소리와 가이드

  AmbientSound get ambientSound =>
      _enum('ambientSound', AmbientSound.values, AmbientSound.none);
  set ambientSound(AmbientSound v) => _save('ambientSound', v);

  double get ambientVolume => _prefs.getDouble('ambientVolume') ?? 0.5;
  set ambientVolume(double v) => _save('ambientVolume', v);

  GuidedMeditation get guided =>
      _enum('guided', GuidedMeditation.values, GuidedMeditation.none);
  set guided(GuidedMeditation v) => _save('guided', v);

  BreathingPattern get breathing =>
      _enum('breathing', BreathingPattern.values, BreathingPattern.none);
  set breathing(BreathingPattern v) => _save('breathing', v);

  // 알림과 연동

  bool get reminderEnabled => _prefs.getBool('reminderEnabled') ?? false;
  set reminderEnabled(bool v) => _save('reminderEnabled', v);

  TimeOfDay get reminderTime => TimeOfDay(
        hour: _prefs.getInt('reminderHour') ?? 8,
        minute: _prefs.getInt('reminderMinute') ?? 0,
      );
  set reminderTime(TimeOfDay v) {
    _prefs.setInt('reminderHour', v.hour);
    _save('reminderMinute', v.minute);
  }

  /// Apple 건강 앱에 마음챙김 시간 기록 (iOS 전용).
  bool get healthSync => _prefs.getBool('healthSync') ?? false;
  set healthSync(bool v) => _save('healthSync', v);

  // 화면

  ThemeMode get themeMode =>
      _enum('themeMode', ThemeMode.values, ThemeMode.system);
  set themeMode(ThemeMode v) => _save('themeMode', v);
}
