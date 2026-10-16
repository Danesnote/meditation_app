import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/breathing_patterns.dart';
import '../models/timer_model.dart';

/// 원이 커졌다 작아지며 호흡을 안내한다. 타이머의 경과 시간에 맞춰 움직여서
/// 일시정지하면 함께 멈춘다.
class BreathingGuide extends StatefulWidget {
  const BreathingGuide({super.key, required this.timer, required this.pattern});

  final TimerModel timer;
  final BreathingPattern pattern;

  @override
  State<BreathingGuide> createState() => _BreathingGuideState();
}

class _BreathingGuideState extends State<BreathingGuide>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() {}))..start();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = breathStateAt(widget.pattern, widget.timer.elapsed);
    final colors = Theme.of(context).colorScheme;
    final size = Curves.easeInOut.transform(state.size);

    return LayoutBuilder(builder: (context, constraints) {
      final maxD = constraints.biggest.shortestSide;
      final d = maxD * (0.45 + 0.4 * size);
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primaryContainer.withValues(alpha: 0.7),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.phase.label,
                  style: Theme.of(context).textTheme.titleLarge),
              Text('${state.secondsLeft}',
                  style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ],
      );
    });
  }
}
