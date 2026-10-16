import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditation_app/data/ambient_sounds.dart';
import 'package:meditation_app/data/guided_scripts.dart';
import 'package:meditation_app/models/history_model.dart';
import 'package:meditation_app/models/settings_model.dart';
import 'package:meditation_app/models/timer_model.dart';
import 'package:meditation_app/services/session_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeAudio audio;
  late FakeNotifications notifications;
  late FakeHealth health;
  late List<bool> wakelock;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'prepSeconds': 0});
    prefs = await SharedPreferences.getInstance();
    audio = FakeAudio();
    notifications = FakeNotifications();
    health = FakeHealth();
    wakelock = [];
  });

  ({TimerModel timer, SettingsModel settings, HistoryModel history,
      SessionCoordinator coordinator}) build({int minutes = 1}) {
    final settings = SettingsModel(prefs);
    final history = HistoryModel(prefs);
    final timer = TimerModel(minutes: minutes);
    final coordinator = SessionCoordinator(
      timer: timer,
      settings: settings,
      history: history,
      audio: audio,
      notifications: notifications,
      health: health,
      setWakelock: (on) async => wakelock.add(on),
    );
    return (
      timer: timer,
      settings: settings,
      history: history,
      coordinator: coordinator
    );
  }

  test('시작과 끝에 종, 배경 소리, 화면 켜두기, 기록이 처리된다', () {
    fakeAsync((async) {
      final s = build();
      s.settings.ambientSound = AmbientSound.rain;
      s.settings.healthSync = true;

      s.timer.start();
      expect(audio.bells, [1.0]);
      expect(audio.ambient, AmbientSound.rain);
      expect(wakelock, [true]);

      async.elapse(const Duration(minutes: 1));
      expect(audio.bells, [1.0, 1.0]); // 완료 종
      expect(audio.ambient, isNull);
      expect(wakelock, [true, false]);
      expect(s.history.totalSessions, 1);
      expect(health.records, hasLength(1));
      s.coordinator.dispose();
    });
  });

  test('일시정지하면 배경 소리도 멈추고, 계속하면 다시 나온다', () {
    fakeAsync((async) {
      final s = build();
      s.settings.ambientSound = AmbientSound.waves;
      s.timer.start();
      s.timer.pause();
      expect(audio.ambientPaused, isTrue);
      s.timer.start();
      expect(audio.ambientPaused, isFalse);
      s.timer.reset();
      s.coordinator.dispose();
    });
  });

  test('중간 종은 작은 볼륨으로 울린다', () {
    fakeAsync((async) {
      final s = build(minutes: 2);
      s.settings.intervalBellMinutes = 1;
      s.timer.start();
      async.elapse(const Duration(seconds: 61));
      expect(audio.bells, [1.0, 0.5]);
      s.timer.reset();
      s.coordinator.dispose();
    });
  });

  test('가이드 음성은 명상 진행에 맞춰 순서대로 읽는다', () {
    fakeAsync((async) {
      final s = build(minutes: 10);
      s.settings.guided = GuidedMeditation.breath;
      final prompts = GuidedMeditation.breath.prompts;
      s.timer.start();

      async.elapse(const Duration(seconds: 3));
      expect(audio.spoken, isEmpty); // 시작 종과 겹치지 않게 잠시 기다린다
      async.elapse(const Duration(seconds: 2));
      expect(audio.spoken, [prompts[0].text]);
      async.elapse(const Duration(minutes: 1)); // 10% 지점
      expect(audio.spoken, [prompts[0].text, prompts[1].text]);
      s.timer.reset();
      s.coordinator.dispose();
    });
  });

  test('백그라운드에서는 완료 알림을 예약하고, 앱 안의 종은 울리지 않는다', () {
    fakeAsync((async) {
      final s = build();
      s.timer.start();
      s.coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(notifications.scheduledCompletion, isNotNull);

      async.elapse(const Duration(minutes: 1));
      expect(audio.bells, [1.0]); // 시작 종만
      s.coordinator.dispose();
    });
  });

  test('앱으로 돌아오면 예약한 완료 알림을 취소한다', () {
    fakeAsync((async) {
      final s = build();
      s.timer.start();
      s.coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
      async.elapse(const Duration(seconds: 10));
      s.coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(notifications.scheduledCompletion, isNull);

      async.elapse(const Duration(minutes: 1));
      expect(audio.bells, [1.0, 1.0]); // 앱 안에서 완료 종
      s.coordinator.dispose();
    });
  });

  test('리마인더는 권한이 있을 때만 켜진다', () async {
    final s = build();
    notifications.permission = false;
    expect(await s.coordinator.setReminder(true), isFalse);
    expect(s.settings.reminderEnabled, isFalse);

    notifications.permission = true;
    expect(await s.coordinator.setReminder(true), isTrue);
    expect(s.settings.reminderEnabled, isTrue);
    expect(notifications.reminder, s.settings.reminderTime);
    s.coordinator.dispose();
  });
}
