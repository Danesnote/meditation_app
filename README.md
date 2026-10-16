# meditation_app

Flutter로 만든 명상 타이머 앱입니다.

## 기능

- 명상 시간 선택 (1·3·5·10·15·20·30분)
- 시작 / 일시정지 / 계속 / 초기화, 완료 후 다시 시작
- 진행률 원형 표시
- 완료 시 종소리 (`assets/sounds/bell.wav`)

타이머는 "끝나는 시각"을 기준으로 남은 시간을 계산하므로, 앱이 잠시 백그라운드에 있다가 돌아와도 시간이 어긋나지 않습니다.

## 구조

```
lib/
  main.dart                 앱 진입점, 종소리 연결
  models/timer_model.dart   타이머 상태와 로직 (ChangeNotifier)
  screens/timer_screen.dart 타이머 화면
test/
  timer_model_test.dart     타이머 로직 단위 테스트
  timer_screen_test.dart    화면 위젯 테스트
```

## 실행

```bash
flutter pub get
flutter run -d chrome
flutter test
```
