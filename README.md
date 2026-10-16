# 명상 (meditation_app)

Flutter로 만든 명상 타이머 앱입니다. 시간을 정하고 앉아서 숨에 집중하는 데 필요한 것들을 담았습니다.

## 기능

### 타이머
- **시간 선택**: 1·3·5·10·15·20·30분 또는 직접 입력(1~180분). 마지막으로 고른 시간을 기억합니다.
- **준비 시간**: 시작 전에 자세를 잡을 수 있게 0~30초 카운트다운.
- **시작 종 / 중간 종 / 완료 종**: 시작할 때, 정해진 간격마다(작게), 끝날 때 종이 울립니다.
- **정확한 시간 계산**: "끝나는 시각"을 기준으로 남은 시간을 계산해서, 앱이 백그라운드에 있다가 돌아와도 어긋나지 않습니다.
- **집중 모드**: 명상 중에는 하단 탭이 사라지고, 화면이 꺼지지 않게 할 수 있습니다.

### 소리와 가이드
- **배경 소리**: 빗소리, 파도, 화이트 노이즈, 브라운 노이즈 (볼륨 조절, 명상 중에도 바로 바뀜).
- **가이드 음성**: 호흡 알아차림 · 바디 스캔 · 자애 명상. 기기의 한국어 TTS로 읽으며, 안내 문장이 명상 길이에 맞춰 배치됩니다.
- **호흡 가이드**: 원이 커졌다 작아지며 들숨·멈춤·날숨을 안내합니다. 편안한 호흡(4-6), 박스 호흡(4-4-4-4), 4-7-8 호흡.

### 기록과 알림
- **명상 기록**: 연속 일수, 오늘·총 명상 시간, 총 횟수, 최장 연속 기록, 최근 7일 그래프, 최근 기록 목록. 1분 이상 하다 그만둔 명상도 "중간에 마침"으로 남습니다.
- **완료 알림**: 명상 중 앱을 벗어나면 끝나는 시각에 종소리 알림을 보냅니다 (iOS·Android).
- **매일 리마인더**: 정한 시각에 명상 알림 (iOS·Android).
- **Apple 건강 앱 연동**: 명상 시간을 마음챙김 시간으로 저장 (iOS).
- **다크 모드**: 시스템 / 라이트 / 다크.

## 플랫폼별 지원

| 기능 | iOS | Android | 웹 |
|---|:-:|:-:|:-:|
| 타이머·종·배경 소리·호흡 가이드·기록 | ✓ | ✓ | ✓ |
| 가이드 음성 (TTS) | ✓ | ✓ | ✓ (브라우저 음성) |
| 화면 켜두기 | ✓ | ✓ | 브라우저가 허용할 때 |
| 완료 알림·매일 리마인더 | ✓ | ✓ | – |
| 건강 앱 연동 | ✓ | – | – |

건강 앱 연동이 iOS 전용인 이유: `health` 패키지가 Android(Health Connect)에서는 마음챙김 기록을 지원하지 않습니다.

## 구조

```
lib/
  main.dart                      앱 진입점, 상태·서비스 연결, 테마
  models/
    timer_model.dart             타이머 상태와 시간 계산 (준비·실행·일시정지·완료)
    settings_model.dart          사용자 설정 (기기에 저장)
    history_model.dart           명상 기록과 통계 (연속 일수 등)
  services/
    session_coordinator.dart     타이머 이벤트 → 종·배경 소리·가이드·알림·기록·건강 앱
    audio_service.dart           종소리, 배경 소리 반복 재생, TTS
    notification_service.dart    완료 알림, 매일 리마인더
    health_service*.dart         Apple 건강 앱 기록 (웹에서는 빈 구현)
  data/
    ambient_sounds.dart          배경 소리 목록
    guided_scripts.dart          가이드 명상 문장
    breathing_patterns.dart      호흡 패턴과 시점별 호흡 상태 계산
  screens/                       명상 / 기록 / 설정 화면, 하단 탭
  widgets/breathing_guide.dart   호흡 가이드 애니메이션
assets/sounds/                   종소리와 배경 소리 (직접 합성한 WAV)
test/                            단위·위젯 테스트
```

`TimerModel`은 시간 계산만 하고, 소리·알림·기록 같은 바깥 일은 `SessionCoordinator`가 맡습니다. 그래서 타이머 로직은 가짜 시계로, 나머지는 가짜 서비스로 테스트합니다.

## 실행

```bash
flutter pub get
flutter run -d chrome
```

```bash
flutter test
```

## iOS·Android 빌드 전 확인할 것

이 저장소에는 각 패키지가 요구하는 네이티브 설정이 들어 있지만, **아직 실제 기기·시뮬레이터 빌드로 확인하지 않았습니다.** 처음 빌드할 때 아래를 확인해 주세요.

### iOS
- 최소 버전 iOS 15 (`health` 요구사항). `ios/Podfile`과 Xcode 프로젝트에 반영되어 있습니다.
- **HealthKit**: `ios/Runner/Runner.entitlements`가 연결되어 있습니다. Xcode의 *Signing & Capabilities*에서 HealthKit이 보이는지 확인하고, 서명 팀(Team)을 지정하세요.
- 백그라운드 오디오(`UIBackgroundModes: audio`)가 켜져 있어서, 배경 소리를 틀어 두면 화면이 잠겨도 명상이 이어집니다.
- 건강 앱 권한 문구는 `Info.plist`의 `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`에 있습니다.

### Android
- `minSdk 26` (`health` 요구사항), Java 17, core library desugaring(`flutter_local_notifications` 요구사항).
- Android Gradle Plugin 8.11.1, Kotlin 2.1.20, Gradle 8.13으로 올렸습니다.
- 완료 알림을 정확한 시각에 받으려면 사용자가 *알람 및 리마인더* 권한을 허용해야 합니다. 허용하지 않으면 알림이 조금 늦게 올 수 있습니다.
- 알림 종소리는 `android/app/src/main/res/raw/bell.wav`입니다.

## 소리 파일

`assets/sounds/`의 모든 소리는 저작권 문제 없이 쓰도록 Python으로 직접 합성했습니다.

- `bell.wav`: 싱잉볼 종소리
- `rain.wav`, `waves.wav`, `white_noise.wav`, `brown_noise.wav`: 이음매 없이 반복되는 배경 소리 (끝부분을 앞부분에 크로스페이드)

실제 녹음한 소리로 바꾸려면 같은 이름으로 파일을 교체하면 됩니다.

## 알려진 한계

- **완료 알림 (iOS·Android)**: 앱이 백그라운드로 갈 때 끝나는 시각으로 예약됩니다. Android에서 *알람 및 리마인더* 권한이 없으면 배터리 절약 모드에서 몇 분 늦게 올 수 있습니다.
- **가이드 음성**: 기기에 설치된 한국어 TTS 음성을 쓰므로, 기기마다 목소리가 다릅니다.
- **웹**: 예약 알림을 지원하지 않습니다. 탭이 백그라운드에 있으면 브라우저가 화면 갱신을 늦출 수 있습니다.
