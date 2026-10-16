import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/ambient_sounds.dart';
import '../data/breathing_patterns.dart';
import '../data/guided_scripts.dart';
import '../models/settings_model.dart';
import '../models/timer_model.dart';
import '../widgets/breathing_guide.dart';

/// 선택할 수 있는 명상 시간(분).
const durationOptions = [1, 3, 5, 10, 15, 20, 30];

/// 직접 입력할 수 있는 최대 시간(분).
const maxCustomMinutes = 180;

String formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  void _selectDuration(BuildContext context, int minutes) {
    context.read<TimerModel>().setDuration(minutes);
    context.read<SettingsModel>().durationMinutes = minutes;
  }

  Future<void> _askCustomDuration(BuildContext context) async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => const _CustomDurationDialog(),
    );
    if (minutes != null && context.mounted) _selectDuration(context, minutes);
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerModel>();
    final settings = context.watch<SettingsModel>();
    final selected = timer.duration.inMinutes;
    final isCustom = !durationOptions.contains(selected);

    return Scaffold(
      appBar: AppBar(title: const Text('명상 타이머')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final minutes in durationOptions)
                      ChoiceChip(
                        label: Text('$minutes분'),
                        selected: selected == minutes,
                        onSelected: timer.isActive
                            ? null
                            : (_) => _selectDuration(context, minutes),
                      ),
                    ChoiceChip(
                      avatar: isCustom ? null : const Icon(Icons.edit, size: 16),
                      label: Text(isCustom ? '$selected분' : '직접 입력'),
                      selected: isCustom,
                      onSelected: timer.isActive
                          ? null
                          : (_) => _askCustomDuration(context),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox.square(
                  dimension: 260,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: timer.progress,
                        strokeWidth: 6,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _RingContent(
                            timer: timer, pattern: settings.breathing),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SessionSummary(settings: settings),
                const SizedBox(height: 24),
                _Controls(timer: timer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 명상 시간을 분 단위로 직접 입력받는다.
/// 닫히는 애니메이션 동안에도 입력란이 살아 있도록 컨트롤러를 State가 소유한다.
class _CustomDurationDialog extends StatefulWidget {
  const _CustomDurationDialog();

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text);
    if (value != null && value >= 1 && value <= maxCustomMinutes) {
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('명상 시간 직접 입력'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          suffixText: '분',
          helperText: '1 ~ $maxCustomMinutes분',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(onPressed: _submit, child: const Text('확인')),
      ],
    );
  }
}

class _RingContent extends StatelessWidget {
  const _RingContent({required this.timer, required this.pattern});

  final TimerModel timer;
  final BreathingPattern pattern;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final time = formatTime(timer.remainingTime);

    switch (timer.status) {
      case TimerStatus.preparing:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('자세를 편안하게', style: text.titleMedium),
            Text('${timer.prepRemaining}', style: const TextStyle(fontSize: 64)),
          ],
        );
      case TimerStatus.completed:
        return const Center(child: Text('완료', style: TextStyle(fontSize: 48)));
      case TimerStatus.running when pattern != BreathingPattern.none:
        return Column(
          children: [
            Expanded(child: BreathingGuide(timer: timer, pattern: pattern)),
            Text(time, style: text.titleMedium),
          ],
        );
      default:
        return Center(child: Text(time, style: const TextStyle(fontSize: 48)));
    }
  }
}

/// 이번 명상에 적용되는 옵션을 한 줄로 보여준다.
class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.settings});

  final SettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (settings.ambientSound != AmbientSound.none)
        settings.ambientSound.label,
      if (settings.guided != GuidedMeditation.none) settings.guided.label,
      if (settings.breathing != BreathingPattern.none)
        settings.breathing.label,
      if (settings.intervalBellMinutes > 0)
        '${settings.intervalBellMinutes}분마다 종',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.timer});

  final TimerModel timer;

  @override
  Widget build(BuildContext context) {
    final status = timer.status;
    final (label, action) = switch (status) {
      TimerStatus.ready => ('시작', timer.start),
      TimerStatus.preparing => ('취소', timer.reset),
      TimerStatus.running => ('일시정지', timer.pause),
      TimerStatus.paused => ('계속', timer.start),
      TimerStatus.completed => ('다시 시작', timer.restart),
    };
    final showStop =
        status == TimerStatus.running || status == TimerStatus.paused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton(onPressed: action, child: Text(label)),
        if (status != TimerStatus.preparing) ...[
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: timer.reset,
            child: Text(showStop ? '그만하기' : '초기화'),
          ),
        ],
      ],
    );
  }
}
