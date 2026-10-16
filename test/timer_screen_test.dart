import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditation_app/main.dart';

void main() {
  testWidgets('시작하면 시간이 흐르고, 일시정지·초기화가 동작한다', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('05:00'), findsOneWidget);

    await tester.tap(find.text('시작'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('04:57'), findsOneWidget);

    await tester.tap(find.text('일시정지'));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('04:57'), findsOneWidget);
    expect(find.text('계속'), findsOneWidget);

    await tester.tap(find.text('초기화'));
    await tester.pump();
    expect(find.text('05:00'), findsOneWidget);
  });

  testWidgets('시간을 고르면 타이머 시간이 바뀐다', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.widgetWithText(ChoiceChip, '10분'));
    await tester.pump();
    expect(find.text('10:00'), findsOneWidget);
  });

  testWidgets('완료되면 완료 화면과 다시 시작 버튼이 나오고 알림이 호출된다', (tester) async {
    var completed = 0;
    await tester.pumpWidget(MyApp(onTimerComplete: () => completed++));
    await tester.tap(find.widgetWithText(ChoiceChip, '1분'));
    await tester.tap(find.text('시작'));
    await tester.pump(const Duration(seconds: 61));

    expect(find.text('완료'), findsOneWidget);
    expect(find.text('다시 시작'), findsOneWidget);
    expect(completed, 1);

    await tester.tap(find.text('다시 시작'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:59'), findsOneWidget);

    // 테스트 종료 시 실행 중인 타이머가 남지 않도록 정리
    await tester.tap(find.text('초기화'));
    await tester.pump();
  });
}
