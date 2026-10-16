# 명상 (meditation_app)

Flutter로 만든 명상 타이머 앱입니다. 시간을 정하고 앉아 숨에 집중하는 데 필요한 타이머, 종소리, 배경 소리, 가이드, 기록을 한곳에 담았습니다.

> 빌드·배포 전 확인할 점과 플랫폼별 제한은 [CAVEATS.md](CAVEATS.md)에 정리되어 있습니다.

## 기능

앱은 하단 탭 세 개(**명상 · 기록 · 설정**)로 되어 있습니다. 명상하는 동안에는 탭이 사라져 명상 화면에만 집중할 수 있습니다.

### 명상 타이머
- **시간 선택**
  - 1·3·5·10·15·20·30분 중에 고르거나, 1~180분 사이로 직접 입력할 수 있습니다.
  - 마지막으로 고른 시간을 기억합니다.
- **준비 시간**: 시작 전 0~30초 카운트다운으로 자세를 잡을 시간을 줍니다.
- **진행 조작**: 시작, 일시정지, 계속, 그만하기, 다시 시작.
- **진행률 원**: 남은 시간 주위의 원이 차오르며 진행 정도를 보여줍니다.
- **정확한 시간 계산**: "끝나는 시각"을 기준으로 남은 시간을 계산합니다. 앱을 잠시 벗어났다 돌아와도 어긋나지 않습니다.
- **화면 켜두기**: 명상 중에 화면이 꺼지지 않게 합니다.

### 종소리
- **시작 종**: 명상을 시작할 때 울립니다.
- **중간 종**: 1·2·5·10분 간격으로 작게 울려 구간을 알려줍니다.
- **완료 종**: 끝나면 싱잉볼 소리가 납니다.

### 배경 소리
- 빗소리, 파도, 화이트 노이즈, 브라운 노이즈 중에서 고르고 볼륨을 조절합니다.
- 명상 중에 바꿔도 바로 반영되고, 일시정지하면 함께 멈춥니다.

### 가이드 음성
한국어 음성이 안내 문장을 읽어 줍니다. 문장은 명상 길이에 맞춰 배치되어, 3분이든 30분이든 같은 흐름으로 진행됩니다.

| 가이드 | 내용 |
|---|---|
| 호흡 알아차림 | 숨에 주의를 두고, 생각이 떠오르면 다시 숨으로 돌아오는 연습 |
| 바디 스캔 | 발끝부터 머리까지 몸의 감각을 차례로 느끼기 |
| 자애 명상 | 나, 소중한 사람, 모르는 사람, 어려운 사람, 모든 존재의 평안을 바라기 |

### 호흡 가이드
원이 커지고 작아지며 "들이쉬기 / 멈추기 / 내쉬기"와 남은 초를 보여줍니다. 일시정지하면 함께 멈춥니다.

| 패턴 | 리듬 |
|---|---|
| 편안한 호흡 | 4초 들숨, 6초 날숨 |
| 박스 호흡 | 4초 들숨, 4초 멈춤, 4초 날숨, 4초 멈춤 |
| 4-7-8 호흡 | 4초 들숨, 7초 멈춤, 8초 날숨 |

### 기록과 통계
- **요약**: 연속 일수, 오늘 명상 시간, 총 명상 시간, 총 횟수, 최장 연속 기록
- **최근 7일 그래프**: 막대를 길게 누르거나 마우스를 올리면 정확한 시간이 나옵니다.
- **최근 기록 목록**: 끝까지 마친 명상은 "완료", 중간에 그만둔 명상은 "중간에 마침"으로 표시됩니다.
- **연속 일수**: 오늘 아직 명상하지 않았어도 어제까지 이어졌다면 유지됩니다.

### 알림
- **완료 알림**: 명상 중에 앱을 벗어나 있으면, 끝나는 시각에 종소리 알림을 보냅니다.
- **매일 리마인더**: 정한 시각에 명상 알림을 보냅니다.

### 연동과 화면
- **Apple 건강 앱**: 명상 시간을 마음챙김 시간으로 저장합니다.
- **다크 모드**: 시스템 / 라이트 / 다크 중에서 고를 수 있습니다.

### 플랫폼별 지원

| 기능 | iOS | Android | 웹 |
|---|:-:|:-:|:-:|
| 타이머 · 종 · 배경 소리 · 가이드 · 호흡 · 기록 · 다크 모드 | ✓ | ✓ | ✓ |
| 화면 켜두기 | ✓ | ✓ | ✓ |
| 완료 알림 · 매일 리마인더 | ✓ | ✓ | – |
| Apple 건강 앱 연동 | ✓ | – | – |

## 기술 스택

| 구분 | 사용 기술 |
|---|---|
| 프레임워크 | Flutter 3.47 (Dart 3.13), Material 3 |
| 상태 관리 | [provider](https://pub.dev/packages/provider) (`ChangeNotifier`) |
| 오디오 | [audioplayers](https://pub.dev/packages/audioplayers): 종소리, 배경 소리 반복 재생 |
| 음성 안내 | [flutter_tts](https://pub.dev/packages/flutter_tts): 기기 TTS로 한국어 가이드 낭독 |
| 알림 | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications), [timezone](https://pub.dev/packages/timezone), [flutter_timezone](https://pub.dev/packages/flutter_timezone) |
| 화면 켜두기 | [wakelock_plus](https://pub.dev/packages/wakelock_plus) |
| 건강 앱 연동 | [health](https://pub.dev/packages/health) (Apple HealthKit) |
| 로컬 저장 | [shared_preferences](https://pub.dev/packages/shared_preferences): 설정과 명상 기록 |
| 시간 | [clock](https://pub.dev/packages/clock): 테스트에서 시간을 조작할 수 있는 현재 시각 |
| 테스트 | flutter_test, [fake_async](https://pub.dev/packages/fake_async) |
| 사운드 | Python으로 직접 합성한 WAV (싱잉볼, 빗소리, 파도, 노이즈 루프) |

### 설계

```
TimerModel ──이벤트──▶ SessionCoordinator ──▶ AudioService         (종, 배경 소리, TTS)
 (시간 계산만)          (부수효과 담당)       ──▶ NotificationService  (완료 알림, 리마인더)
                                             ──▶ HistoryModel         (기록 저장)
                                             ──▶ HealthService        (건강 앱)
                                             ──▶ wakelock             (화면 켜두기)
```

- **`TimerModel`**
  - 준비 → 실행 → 일시정지 → 완료 상태와 시간 계산만 맡습니다.
  - 일이 생기면 `TimerEvents`로 알립니다.
- **`SessionCoordinator`**
  - 이벤트를 받아 소리, 알림, 기록, 건강 앱, 화면 켜두기를 처리합니다.
  - 앱 생명주기(백그라운드 진입·복귀)에 맞춰 완료 알림을 예약하거나 취소합니다.
- **테스트하기 쉬운 구조**
  - 서비스는 생성자로 주입받기 때문에, 테스트에서는 가짜 서비스로 바꿔 끼웁니다.
  - 시간은 `clock`과 `fake_async`로 조작합니다.
  - 그래서 60분짜리 명상도 테스트에서는 바로 끝납니다.
- **웹 빌드 대응**: `health`는 `dart:io`를 쓰기 때문에, 조건부 export로 웹에서는 빈 구현을 씁니다.

## 프로젝트 구조

```
lib/
  main.dart                      앱 진입점, 상태·서비스 연결, 테마
  models/
    timer_model.dart             타이머 상태와 시간 계산
    settings_model.dart          사용자 설정 (기기에 저장)
    history_model.dart           명상 기록과 통계
  services/
    session_coordinator.dart     타이머 이벤트를 소리·알림·기록으로 연결
    audio_service.dart           종소리, 배경 소리, TTS
    notification_service.dart    완료 알림, 매일 리마인더
    health_service*.dart         Apple 건강 앱 기록 (웹은 빈 구현)
  data/
    ambient_sounds.dart          배경 소리 목록
    guided_scripts.dart          가이드 명상 문장
    breathing_patterns.dart      호흡 패턴과 시점별 호흡 상태 계산
  screens/                       명상 · 기록 · 설정 화면, 하단 탭
  widgets/breathing_guide.dart   호흡 가이드 애니메이션
assets/sounds/                   종소리와 배경 소리
test/                            단위 · 위젯 테스트 (32개)
```

## 실행

```bash
flutter pub get
flutter run -d chrome
```

```bash
flutter test
```
