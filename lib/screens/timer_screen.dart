import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_model.dart';

/// 선택할 수 있는 명상 시간(분).
const durationOptions = [1, 3, 5, 10, 15, 20, 30];

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timerModel = context.watch<TimerModel>();
    final status = timerModel.status;
    final canChangeDuration =
        status == TimerStatus.ready || status == TimerStatus.completed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('명상 타이머'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final minutes in durationOptions)
                  ChoiceChip(
                    label: Text('$minutes분'),
                    selected: timerModel.duration.inMinutes == minutes,
                    onSelected: canChangeDuration
                        ? (_) => timerModel.setDuration(minutes)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: timerModel.progress,
                    strokeWidth: 6,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  Center(
                    child: Text(
                      status == TimerStatus.completed
                          ? '완료'
                          : _formatTime(timerModel.remainingTime),
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                switch (status) {
                  TimerStatus.ready || TimerStatus.paused => ElevatedButton(
                      onPressed: timerModel.start,
                      child: Text(status == TimerStatus.paused ? '계속' : '시작'),
                    ),
                  TimerStatus.running => ElevatedButton(
                      onPressed: timerModel.pause,
                      child: const Text('일시정지'),
                    ),
                  TimerStatus.completed => ElevatedButton(
                      onPressed: timerModel.restart,
                      child: const Text('다시 시작'),
                    ),
                },
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: timerModel.reset,
                  child: const Text('초기화'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
