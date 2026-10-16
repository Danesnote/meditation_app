import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 명상 한 번의 기록.
class SessionRecord {
  const SessionRecord({
    required this.startedAt,
    required this.seconds,
    required this.completed,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        startedAt: DateTime.parse(json['startedAt'] as String),
        seconds: json['seconds'] as int,
        completed: json['completed'] as bool,
      );

  final DateTime startedAt;

  /// 실제로 명상한 시간(초).
  final int seconds;

  /// 끝까지 마쳤는지, 중간에 그만뒀는지.
  final bool completed;

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'seconds': seconds,
        'completed': completed,
      };
}

/// 명상 기록과 통계.
class HistoryModel extends ChangeNotifier {
  HistoryModel(this._prefs) {
    final raw = _prefs.getStringList(_key) ?? const [];
    _sessions.addAll(raw.map(
        (s) => SessionRecord.fromJson(jsonDecode(s) as Map<String, dynamic>)));
  }

  static const _key = 'sessions';

  /// 이보다 짧게 하다 그만둔 명상은 기록하지 않는다.
  static const minRecordSeconds = 60;

  final SharedPreferences _prefs;
  final List<SessionRecord> _sessions = [];

  /// 최신순.
  List<SessionRecord> get sessions => _sessions.reversed.toList();

  Future<void> add(SessionRecord record) async {
    if (!record.completed && record.seconds < minRecordSeconds) return;
    _sessions.add(record);
    notifyListeners();
    await _prefs.setStringList(
        _key, _sessions.map((s) => jsonEncode(s.toJson())).toList());
  }

  int get totalSessions => _sessions.length;

  int get totalMinutes =>
      _sessions.fold(0, (sum, s) => sum + s.seconds) ~/ 60;

  int get todayMinutes => minutesOn(_today);

  /// [day] 날짜(자정 기준)에 명상한 시간(분).
  int minutesOn(DateTime day) =>
      _sessions
          .where((s) => _dateOf(s.startedAt) == day)
          .fold(0, (sum, s) => sum + s.seconds) ~/
      60;

  /// 오늘부터 거슬러 올라간 최근 7일의 날짜 (오래된 날짜가 먼저).
  List<DateTime> get last7Days =>
      [for (var i = 6; i >= 0; i--) _today.subtract(Duration(days: i))];

  /// 연속으로 명상한 날 수.
  /// 오늘 아직 안 했어도 어제까지 이어졌다면 연속 기록이 유지된다.
  int get currentStreak {
    final days = _sessions.map((s) => _dateOf(s.startedAt)).toSet();
    var day = _today;
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 가장 길게 이어졌던 연속 기록.
  int get longestStreak {
    final days = _sessions.map((s) => _dateOf(s.startedAt)).toSet().toList()
      ..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      run = (prev != null && d.difference(prev).inDays == 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  DateTime get _today => _dateOf(clock.now());

  // 서머타임이 있는 지역에서도 날짜 계산이 어긋나지 않도록 UTC 자정으로 맞춘다.
  static DateTime _dateOf(DateTime t) => DateTime.utc(t.year, t.month, t.day);
}
