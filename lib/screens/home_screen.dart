import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/timer_model.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'timer_screen.dart';

/// 하단 탭: 명상 / 기록 / 설정.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // 명상 중에는 다른 탭으로 가지 않게 해서 집중을 돕는다.
    final active = context.select<TimerModel, bool>((t) => t.isActive);

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [TimerScreen(), StatsScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: active
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.self_improvement), label: '명상'),
                NavigationDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights),
                    label: '기록'),
                NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: '설정'),
              ],
            ),
    );
  }
}
