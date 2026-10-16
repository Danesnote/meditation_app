import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Apple 건강 앱에 마음챙김 시간을 기록한다.
/// health 패키지는 Android(Health Connect)에서 마음챙김 기록을 지원하지 않아 iOS 전용이다.
class HealthService {
  final _health = Health();
  bool _configured = false;

  bool get isSupported => Platform.isIOS;

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      await _configure();
      return await _health.requestAuthorization(
        [HealthDataType.MINDFULNESS],
        permissions: [HealthDataAccess.WRITE],
      );
    } catch (e) {
      debugPrint('건강 앱 권한 요청 실패: $e');
      return false;
    }
  }

  Future<void> recordMindfulness(DateTime start, DateTime end) async {
    if (!isSupported) return;
    try {
      await _configure();
      await _health.writeHealthData(
        value: end.difference(start).inSeconds / 60,
        type: HealthDataType.MINDFULNESS,
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      debugPrint('건강 앱 기록 실패: $e');
    }
  }
}
