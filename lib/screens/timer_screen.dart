import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_model.dart';
import 'dart:async';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final timerModel = Provider.of<TimerModel>(context, listen: false);
    timerModel.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timerModel.tick();
    });
  }

  void _pauseTimer() {
    final timerModel = Provider.of<TimerModel>(context, listen: false);
    timerModel.pause();
    _timer?.cancel();
  }

  void _resetTimer() {
    final timerModel = Provider.of<TimerModel>(context, listen: false);
    timerModel.reset();
    _timer?.cancel();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('명상 타이머'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<TimerModel>(
              builder: (context, timerModel, child) {
                return Text(
                  _formatTime(timerModel.remainingTime),
                  style: const TextStyle(fontSize: 48),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer<TimerModel>(
                  builder: (context, timerModel, child) {
                    if (timerModel.status == TimerStatus.ready ||
                        timerModel.status == TimerStatus.paused) {
                      return ElevatedButton(
                        onPressed: _startTimer,
                        child: const Text('시작'),
                      );
                    } else if (timerModel.status == TimerStatus.running) {
                      return ElevatedButton(
                        onPressed: _pauseTimer,
                        child: const Text('일시정지'),
                      );
                    } else {
                      return ElevatedButton(
                        onPressed: _resetTimer,
                        child: const Text('다시 시작'),
                      );
                    }
                  },
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _resetTimer,
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