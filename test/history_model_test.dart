import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditation_app/models/history_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

SessionRecord _session(DateTime at, {int minutes = 10, bool completed = true}) =>
    SessionRecord(startedAt: at, seconds: minutes * 60, completed: completed);

void main() {
  final now = DateTime(2026, 10, 16, 21);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('기록이 저장되고 다시 불러와진다', () async {
    final prefs = await SharedPreferences.getInstance();
    await HistoryModel(prefs).add(_session(now));
    final reloaded = HistoryModel(prefs);
    expect(reloaded.totalSessions, 1);
    expect(reloaded.totalMinutes, 10);
  });

  test('1분 미만으로 하다 그만둔 명상은 기록하지 않는다', () async {
    final history = HistoryModel(await SharedPreferences.getInstance());
    await history.add(SessionRecord(startedAt: now, seconds: 30, completed: false));
    await history.add(SessionRecord(startedAt: now, seconds: 30, completed: true));
    expect(history.totalSessions, 1);
  });

  test('연속 일수: 오늘 아직 안 했어도 어제까지 이어지면 유지된다', () async {
    final history = HistoryModel(await SharedPreferences.getInstance());
    for (final daysAgo in [1, 2, 3, 5, 6]) {
      await history.add(_session(now.subtract(Duration(days: daysAgo))));
    }
    withClock(Clock.fixed(now), () {
      expect(history.currentStreak, 3);
      expect(history.longestStreak, 3);
      expect(history.todayMinutes, 0);
    });
  });

  test('연속 일수: 이틀 이상 쉬면 0으로 돌아간다', () async {
    final history = HistoryModel(await SharedPreferences.getInstance());
    await history.add(_session(now.subtract(const Duration(days: 2))));
    withClock(Clock.fixed(now), () => expect(history.currentStreak, 0));
  });

  test('최근 7일은 오늘로 끝나고, 날짜별 시간을 합산한다', () async {
    final history = HistoryModel(await SharedPreferences.getInstance());
    await history.add(_session(now, minutes: 5));
    await history.add(_session(now.subtract(const Duration(hours: 3)), minutes: 15));
    withClock(Clock.fixed(now), () {
      final days = history.last7Days;
      expect(days, hasLength(7));
      expect(history.minutesOn(days.last), 20);
      expect(history.todayMinutes, 20);
    });
  });
}
