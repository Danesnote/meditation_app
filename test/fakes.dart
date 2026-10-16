import 'package:flutter/material.dart';
import 'package:meditation_app/data/ambient_sounds.dart';
import 'package:meditation_app/services/audio_service.dart';
import 'package:meditation_app/services/health_service.dart';
import 'package:meditation_app/services/notification_service.dart';

/// 실제 소리를 내지 않고 호출 기록만 남긴다.
class FakeAudio implements AudioService {
  final bells = <double>[];
  final spoken = <String>[];
  AmbientSound? ambient;
  bool ambientPaused = false;

  @override
  Future<void> playBell({double volume = 1}) async => bells.add(volume);
  @override
  Future<void> startAmbient(AmbientSound sound, double volume) async {
    ambient = sound;
    ambientPaused = false;
  }
  @override
  Future<void> changeAmbient(AmbientSound sound, double volume) async =>
      ambient = sound;
  @override
  Future<void> setAmbientVolume(double volume) async {}
  @override
  Future<void> pauseAmbient() async => ambientPaused = true;
  @override
  Future<void> resumeAmbient() async => ambientPaused = false;
  @override
  Future<void> stopAmbient() async => ambient = null;
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> stopSpeaking() async {}
}

class FakeNotifications implements NotificationService {
  DateTime? scheduledCompletion;
  TimeOfDay? reminder;
  bool permission = true;

  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<void> scheduleCompletion(DateTime endsAt) async =>
      scheduledCompletion = endsAt;
  @override
  Future<void> cancelCompletion() async => scheduledCompletion = null;
  @override
  Future<void> scheduleDailyReminder(TimeOfDay time) async => reminder = time;
  @override
  Future<void> cancelDailyReminder() async => reminder = null;
}

class FakeHealth implements HealthService {
  final records = <(DateTime, DateTime)>[];
  bool permission = true;

  @override
  bool get isSupported => true;
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<void> recordMindfulness(DateTime start, DateTime end) async =>
      records.add((start, end));
}
