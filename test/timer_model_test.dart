import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditation_app/models/timer_model.dart';

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
        model.dispose();
      });
    });

    test('일시정지 중에는 시간이 흐르지 않고, 계속하면 이어서 진행된다', () {
      fakeAsync((async) {
        final model = TimerModel()..start();
        async.elapse(const Duration(seconds: 30));
        model.pause();
        async.elapse(const Duration(minutes: 1));
        expect(model.remainingTime, 270);
        expect(model.status, TimerStatus.paused);

        model.start();
        async.elapse(const Duration(seconds: 20));
        expect(model.remainingTime, 250);
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

    test('끝나면 완료 상태가 되고 onComplete가 한 번만 호출된다', () {
      fakeAsync((async) {
        var completeCount = 0;
        final model = TimerModel(onComplete: () => completeCount++)
          ..setDuration(1)
          ..start();
        async.elapse(const Duration(seconds: 60));
        expect(model.status, TimerStatus.completed);
        expect(model.remainingTime, 0);

        async.elapse(const Duration(minutes: 1));
        expect(completeCount, 1);
        expect(async.periodicTimerCount, 0); // 완료 후 타이머가 정리됨
        model.dispose();
      });
    });

    test('restart는 완료 후 같은 시간으로 다시 시작한다', () {
      fakeAsync((async) {
        final model = TimerModel()
          ..setDuration(1)
          ..start();
        async.elapse(const Duration(minutes: 2));
        model.restart();
        expect(model.status, TimerStatus.running);
        async.elapse(const Duration(seconds: 15));
        expect(model.remainingTime, 45);
        model.dispose();
      });
    });

    test('실행 중에는 시간을 바꿀 수 없다', () {
      fakeAsync((async) {
        final model = TimerModel()..start();
        model.setDuration(10);
        expect(model.duration, const Duration(minutes: 5));
        model.dispose();
      });
    });
  });
}
