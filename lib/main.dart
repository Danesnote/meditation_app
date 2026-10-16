import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/timer_model.dart';
import 'screens/timer_screen.dart';

void main() {
  final bellPlayer = AudioPlayer();
  runApp(MyApp(
    onTimerComplete: () => bellPlayer.play(AssetSource('sounds/bell.wav')),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.onTimerComplete});

  /// 타이머가 끝났을 때 실행할 동작. 테스트에서는 비워 둔다.
  final VoidCallback? onTimerComplete;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TimerModel(onComplete: onTimerComplete),
      child: MaterialApp(
        title: '명상 앱',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const TimerScreen(),
      ),
    );
  }
}
