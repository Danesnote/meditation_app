import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/history_model.dart';
import 'models/settings_model.dart';
import 'models/timer_model.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/health_service.dart';
import 'services/notification_service.dart';
import 'services/session_coordinator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();
  await notifications.init();

  runApp(MyApp(
    prefs: prefs,
    audio: AudioService(),
    notifications: notifications,
    health: HealthService(),
  ));
}

/// 앱 전체에서 쓰는 상태와 서비스를 만들어 Provider로 내려준다.
/// 테스트에서는 서비스 자리에 가짜 구현을 넣는다.
class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.prefs,
    required this.audio,
    required this.notifications,
    required this.health,
    this.setWakelock,
  });

  final SharedPreferences prefs;
  final AudioService audio;
  final NotificationService notifications;
  final HealthService health;
  final Future<void> Function(bool enable)? setWakelock;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final settings = SettingsModel(widget.prefs);
  late final history = HistoryModel(widget.prefs);
  late final timer = TimerModel(minutes: settings.durationMinutes);
  late final coordinator = SessionCoordinator(
    timer: timer,
    settings: settings,
    history: history,
    audio: widget.audio,
    notifications: widget.notifications,
    health: widget.health,
    setWakelock: widget.setWakelock,
  );

  @override
  void dispose() {
    coordinator.dispose();
    timer.dispose();
    settings.dispose();
    history.dispose();
    super.dispose();
  }

  static const _seed = Color(0xFF4F7C82); // 차분한 청록

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: history),
        ChangeNotifierProvider.value(value: timer),
        Provider.value(value: coordinator),
        Provider.value(value: widget.health),
      ],
      child: Consumer<SettingsModel>(
        builder: (context, settings, _) => MaterialApp(
          title: '명상 앱',
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: _seed),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: _seed, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
