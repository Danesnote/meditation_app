import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditation_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<FakeAudio> _pumpApp(WidgetTester tester,
    [Map<String, Object> prefs = const {'prepSeconds': 0}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final audio = FakeAudio();
  await tester.pumpWidget(MyApp(
    prefs: await SharedPreferences.getInstance(),
    audio: audio,
    notifications: FakeNotifications(),
    health: FakeHealth(),
    setWakelock: (_) async {},
  ));
  return audio;
}

void main() {
  testWidgets('시작하면 시간이 흐르고, 일시정지·그만하기가 동작한다', (tester) async {
    await _pumpApp(tester);
    expect(find.text('05:00'), findsOneWidget);

    await tester.tap(find.text('시작'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('04:57'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing); // 명상 중에는 탭 숨김

    await tester.tap(find.text('일시정지'));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('04:57'), findsOneWidget);
    expect(find.text('계속'), findsOneWidget);

    await tester.tap(find.text('그만하기'));
    await tester.pump();
    expect(find.text('05:00'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('시간을 고르면 바뀌고, 다음 실행 때도 기억한다', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '10분'));
    await tester.pump();
    expect(find.text('10:00'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('durationMinutes'), 10);
  });

  testWidgets('직접 입력으로 원하는 시간을 정할 수 있다', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '45');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('45:00'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '45분'), findsOneWidget);
  });

  testWidgets('준비 시간이 끝난 뒤 명상이 시작된다', (tester) async {
    await _pumpApp(tester, {'prepSeconds': 5});
    await tester.tap(find.text('시작'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('자세를 편안하게'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('05:00'), findsNothing);
    expect(find.text('04:59'), findsOneWidget);

    await tester.tap(find.text('그만하기'));
    await tester.pump();
  });

  testWidgets('완료되면 완료 화면, 종소리, 기록이 남는다', (tester) async {
    final audio = await _pumpApp(tester, {'prepSeconds': 0, 'startBell': false});
    await tester.tap(find.widgetWithText(ChoiceChip, '1분'));
    await tester.tap(find.text('시작'));
    await tester.pump(const Duration(seconds: 61));

    expect(find.text('완료'), findsOneWidget);
    expect(find.text('다시 시작'), findsOneWidget);
    expect(audio.bells, [1.0]);

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('1분 명상'), 200);
    expect(find.text('1분 명상'), findsOneWidget);
    expect(find.text('1일'), findsWidgets); // 연속 일수
  });

  testWidgets('호흡 가이드를 켜면 명상 중에 안내가 나온다', (tester) async {
    await _pumpApp(tester, {'prepSeconds': 0, 'breathing': 'box'});
    await tester.tap(find.text('시작'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('들이쉬기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('멈추기'), findsOneWidget);

    await tester.tap(find.text('그만하기'));
    await tester.pump();
  });

  testWidgets('설정에서 다크 모드로 바꿀 수 있다', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('다크'), 200);
    await tester.ensureVisible(find.text('다크'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
