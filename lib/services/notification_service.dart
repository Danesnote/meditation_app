import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 명상 완료 알림과 매일 리마인더. iOS·Android에서만 동작한다.
class NotificationService {
  static const _completeId = 1;
  static const _reminderId = 2;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// 예약 알림을 쓸 수 있는 플랫폼인지 (웹은 예약 알림을 지원하지 않는다).
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!isSupported) return;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // 권한은 처음 실제로 필요할 때 요청한다.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('알림 초기화 실패: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ??
        await ios?.requestPermissions(alert: true, sound: true) ??
        false;
    return granted;
  }

  /// 앱이 백그라운드로 갔을 때 끝나는 시각에 종소리 알림을 예약한다.
  Future<void> scheduleCompletion(DateTime endsAt) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: _completeId,
      title: '명상이 끝났습니다',
      body: '천천히 눈을 뜨고, 지금의 느낌을 잠시 머금어 보세요.',
      scheduledDate: tz.TZDateTime.from(endsAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'meditation_complete',
          '명상 완료',
          channelDescription: '명상 타이머가 끝나면 알려줍니다',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('bell'),
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
      androidScheduleMode: await _scheduleMode(),
    );
  }

  Future<void> cancelCompletion() async {
    if (_ready) await _plugin.cancel(id: _completeId);
  }

  /// 매일 [time]에 명상 리마인더를 보낸다.
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    if (!_ready) return;
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _reminderId,
      title: '명상할 시간이에요',
      body: '잠시 멈추고, 몇 분만 숨에 집중해 볼까요?',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          '매일 리마인더',
          channelDescription: '정해진 시간에 명상을 알려줍니다',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    if (_ready) await _plugin.cancel(id: _reminderId);
  }

  /// 정확한 알람 권한이 있으면 정확히, 없으면 조금 늦을 수 있는 방식으로 예약한다.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }
}
