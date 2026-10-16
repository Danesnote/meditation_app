import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history_model.dart';

String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes분';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '$h시간' : '$h시간 $m분';
}

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryModel>();
    final sessions = history.sessions;

    return Scaffold(
      appBar: AppBar(title: const Text('명상 기록')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatTile(label: '연속 일수', value: '${history.currentStreak}일'),
              _StatTile(label: '오늘', value: formatMinutes(history.todayMinutes)),
              _StatTile(label: '총 명상 시간', value: formatMinutes(history.totalMinutes)),
              _StatTile(label: '총 횟수', value: '${history.totalSessions}회'),
              _StatTile(label: '최장 연속', value: '${history.longestStreak}일'),
            ],
          ),
          const SizedBox(height: 32),
          Text('최근 7일', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _WeekChart(history: history),
          const SizedBox(height: 32),
          Text('최근 기록', style: Theme.of(context).textTheme.titleMedium),
          if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('아직 기록이 없어요. 첫 명상을 시작해 보세요.'),
            )
          else
            for (final s in sessions.take(30)) _SessionTile(record: s),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

/// 최근 7일 명상 시간 막대 그래프. 막대를 길게 누르거나 마우스를 올리면 정확한 값이 나온다.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.history});

  final HistoryModel history;

  static const _chartHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = history.last7Days;
    final minutes = [for (final d in days) history.minutesOn(d)];
    final maxMinutes = minutes.fold(0, (a, b) => a > b ? a : b);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Semantics(
      label: '최근 7일 명상 시간: '
          '${[for (var i = 0; i < 7; i++) '${_weekdays[days[i].weekday - 1]} ${minutes[i]}분'].join(', ')}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Tooltip(
                message: '${days[i].month}/${days[i].day} · ${formatMinutes(minutes[i])}',
                child: Column(
                  children: [
                    if (i == 6) Text(formatMinutes(minutes[i]), style: muted),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: _chartHeight,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 20,
                          // 0분인 날도 바닥선이 보이게 최소 2px.
                          height: maxMinutes == 0
                              ? 2
                              : (minutes[i] / maxMinutes * _chartHeight)
                                  .clamp(2, _chartHeight),
                          decoration: BoxDecoration(
                            color: minutes[i] == 0
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(i == 6 ? '오늘' : _weekdays[days[i].weekday - 1],
                        style: muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.record});

  final SessionRecord record;

  @override
  Widget build(BuildContext context) {
    final t = record.startedAt;
    final when = '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
    final mins = (record.seconds / 60).round();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(record.completed ? Icons.check_circle : Icons.timelapse),
      title: Text('${mins < 1 ? 1 : mins}분 명상'),
      subtitle: Text(record.completed ? '$when · 완료' : '$when · 중간에 마침'),
    );
  }
}
