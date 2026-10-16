import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditation_app/models/timer_model.dart';

/// 타이머 이벤트를 기록만 하는 가짜.
class RecordingEvents extends TimerEvents {
  final log = <String>[];
  Duration? endElapsed;

  @override
  void onMeditationStart(DateTime endsAt) => log.add('start');
  @override
  void onPause() => log.add('pause');
  @override
  void onResume(DateTime endsAt) => log.add('resume');
  @override
  void onInterval() => log.add('interval');
  @override
  void onEnd(DateTime startedAt, Duration elapsed, {required bool completed}) {
    endElapsed = elapsed;
    log.add(completed ? 'complete' : 'stop');
  }
}

void main() {
  group('TimerModel', () {
    test('기본값은 5분, 대기 상태', () {
      final model = TimerModel();
      expect(model.remainingTime, 300);
      expect(model.status, TimerStatus.ready);
    });

    test('실제 경과 시간만큼 남은 시간이 줄어든다', () {
      fakeAsync((async) {
        final model = TimerModel()..start();
        async.elapse(const Duration(seconds: 10));
        expect(model.remainingTime, 290);
        expect(model.elapsed, const Duration(seconds: 10));
        model.dispose();
      });
    });

    test('일시정지 중에는 시간이 흐르지 않고, 계속하면 이어서 진행된다', () {
      fakeAsync((async) {
        final events = RecordingEvents();
        final model = TimerModel(events: events)..start();
        async.elapse(const Duration(seconds: 30));
        model.pause();
        async.elapse(const Duration(minutes: 1));
        expect(model.remainingTime, 270);
        expect(model.status, TimerStatus.paused);

        model.start();
        async.elapse(const Duration(seconds: 20));
        expect(model.remainingTime, 250);
        expect(events.log, ['start', 'pause', 'resume']);
        model.dispose();
      });
    });

    test('중복 시작해도 두 배로 빨라지지 않는다', () {
      fakeAsync((async) {
        final model = TimerModel()
          ..start()
          ..start();
        async.elapse(const Duration(seconds: 10));
        expect(model.remainingTime, 290);
        model.dispose();
      });
    });

    test('끝나면 완료 상태가 되고 onEnd가 한 번만 호출된다', () {
      fakeAsync((async) {
        final events = RecordingEvents();
        final model = TimerModel(events: events, minutes: 1)..start();
        async.elapse(const Duration(seconds: 60));
        expect(model.status, TimerStatus.completed);
        expect(model.remainingTime, 0);

        async.elapse(const Duration(minutes: 1));
        expect(events.log, ['start', 'complete']);
        expect(events.endElapsed, const Duration(minutes: 1));
        expect(async.periodicTimerCount, 0); // 완료 후 타이머가 정리됨
        model.dispose();
      });
    });

    test('중간에 그만두면 실제 명상 시간과 함께 중단으로 알린다', () {
      fakeAsync((async) {
        final events = RecordingEvents();
        final model = TimerModel(events: events)..start();
        async.elapse(const Duration(seconds: 90));
        model.reset();
        expect(events.log, ['start', 'stop']);
        expect(events.endElapsed, const Duration(seconds: 90));
        expect(model.status, TimerStatus.ready);
        model.dispose();
      });
    });

    test('restart는 완료 후 같은 시간으로 다시 시작한다', () {
      fakeAsync((async) {
        final model = TimerModel(minutes: 1)..start();
        async.elapse(const Duration(minutes: 2));
        model.restart();
        expect(model.status, TimerStatus.running);
        async.elapse(const Duration(seconds: 15));
        expect(model.remainingTime, 45);
        model.dispose();
      });
    });

    test('진행 중에는 시간을 바꿀 수 없다', () {
      fakeAsync((async) {
        final model = TimerModel()..start();
        model.setDuration(10);
        expect(model.duration, const Duration(minutes: 5));
        model.dispose();
      });
    });

    test('준비 시간이 지나야 명상이 시작된다', () {
      fakeAsync((async) {
        final events = RecordingEvents();
        final model = TimerModel(events: events)
          ..prepTime = const Duration(seconds: 10)
          ..start();
        expect(model.status, TimerStatus.preparing);
        async.elapse(const Duration(seconds: 3));
        expect(model.prepRemaining, 7);
        expect(events.log, isEmpty);

        async.elapse(const Duration(seconds: 7));
        expect(model.status, TimerStatus.running);
        expect(events.log, ['start']);
        expect(model.remainingTime, 300); // 준비 시간은 명상 시간에서 빠지지 않는다

        async.elapse(const Duration(seconds: 5));
        expect(model.remainingTime, 295);
        model.dispose();
      });
    });

    test('준비 중에 멈추면 기록 없이 처음으로 돌아간다', () {
      fakeAsync((async) {
        final events = RecordingEvents();
        final model = TimerModel(events: events)
          ..prepTime = const Duration(seconds: 10)
          ..start();
        async.elapse(const Duration(seconds: 3));
        model.pause();
        expect(model.status, TimerStatus.ready);
        expect(events.log, isEmpty);
        model.dispose();
      });
    });

    test('중간 종은 간격마다 울리고, 끝나는 순간에는 울리지 않는다', () {
      fakeAsync((async) {
        final events = RecordingEvents();
        final model = TimerModel(events: events, minutes: 3)
          ..intervalBell = const Duration(minutes: 1)
          ..start();
        async.elapse(const Duration(minutes: 3));
        expect(events.log, ['start', 'interval', 'interval', 'complete']);
        model.dispose();
      });
    });
  });
}
