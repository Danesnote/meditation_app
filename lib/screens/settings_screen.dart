import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/ambient_sounds.dart';
import '../data/breathing_patterns.dart';
import '../data/guided_scripts.dart';
import '../models/settings_model.dart';
import '../services/health_service.dart';
import '../services/notification_service.dart';
import '../services/session_coordinator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showDenied(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$what 권한이 없어요. 기기 설정에서 허용해 주세요.')));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsModel>();
    final coordinator = context.read<SessionCoordinator>();
    final healthSupported = context.read<HealthService>().isSupported;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const _Header('타이머'),
          _Choice<int>(
            title: '준비 시간',
            value: s.prepSeconds,
            options: const {0: '없음', 5: '5초', 10: '10초', 15: '15초', 30: '30초'},
            onChanged: (v) => s.prepSeconds = v,
          ),
          SwitchListTile(
            title: const Text('시작 종'),
            subtitle: const Text('명상을 시작할 때 종을 울립니다'),
            value: s.startBell,
            onChanged: (v) => s.startBell = v,
          ),
          _Choice<int>(
            title: '중간 종',
            subtitle: '정해진 간격마다 작게 종을 울립니다',
            value: s.intervalBellMinutes,
            options: const {0: '없음', 1: '1분', 2: '2분', 5: '5분', 10: '10분'},
            onChanged: (v) => s.intervalBellMinutes = v,
          ),
          SwitchListTile(
            title: const Text('화면 켜두기'),
            subtitle: const Text('명상 중에 화면이 꺼지지 않게 합니다'),
            value: s.keepScreenOn,
            onChanged: (v) => s.keepScreenOn = v,
          ),
          const _Header('소리와 가이드'),
          _Choice<AmbientSound>(
            title: '배경 소리',
            value: s.ambientSound,
            options: {for (final a in AmbientSound.values) a: a.label},
            onChanged: (v) => s.ambientSound = v,
          ),
          if (s.ambientSound != AmbientSound.none)
            ListTile(
              title: const Text('배경 소리 볼륨'),
              subtitle: Slider(
                value: s.ambientVolume,
                divisions: 10,
                label: '${(s.ambientVolume * 100).round()}%',
                onChanged: (v) => s.ambientVolume = v,
              ),
            ),
          _Choice<GuidedMeditation>(
            title: '가이드 음성',
            subtitle: '명상 흐름에 맞춰 안내 문장을 읽어 줍니다',
            value: s.guided,
            options: {for (final g in GuidedMeditation.values) g: g.label},
            onChanged: (v) => s.guided = v,
          ),
          _Choice<BreathingPattern>(
            title: '호흡 가이드',
            subtitle: '원의 크기로 들숨과 날숨을 안내합니다',
            value: s.breathing,
            options: {for (final b in BreathingPattern.values) b: b.label},
            onChanged: (v) => s.breathing = v,
          ),
          const _Header('알림'),
          SwitchListTile(
            title: const Text('매일 명상 리마인더'),
            subtitle: Text(NotificationService.isSupported
                ? '매일 ${s.reminderTime.format(context)}에 알려드려요'
                : 'iOS·Android 앱에서 사용할 수 있어요'),
            value: s.reminderEnabled,
            onChanged: NotificationService.isSupported
                ? (v) async {
                    final ok = await coordinator.setReminder(v);
                    if (!ok && context.mounted) _showDenied(context, '알림');
                  }
                : null,
          ),
          if (s.reminderEnabled)
            ListTile(
              title: const Text('리마인더 시간'),
              trailing: Text(s.reminderTime.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                    context: context, initialTime: s.reminderTime);
                if (time != null) await coordinator.setReminder(true, time: time);
              },
            ),
          const _Header('연동'),
          SwitchListTile(
            title: const Text('Apple 건강 앱에 기록'),
            subtitle: Text(healthSupported
                ? '명상 시간을 마음챙김 시간으로 저장합니다'
                : 'iPhone에서만 사용할 수 있어요'),
            value: s.healthSync,
            onChanged: healthSupported
                ? (v) async {
                    final ok = await coordinator.setHealthSync(v);
                    if (!ok && context.mounted) _showDenied(context, '건강 앱');
                  }
                : null,
          ),
          const _Header('화면'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('시스템')),
                ButtonSegment(value: ThemeMode.light, label: Text('라이트')),
                ButtonSegment(value: ThemeMode.dark, label: Text('다크')),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => s.themeMode = v.first,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}

/// 여러 값 중 하나를 고르는 설정 줄.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.title,
    this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [
          for (final e in options.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
