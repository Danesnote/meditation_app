# 주의사항

빌드하거나 배포하기 전에 알아 둘 점을 정리했습니다. 기능 소개는 [README](README.md)를 보세요.

## 검증 상태

- **웹(Chrome)**: 직접 실행해서 주요 흐름을 확인했습니다.
- **iOS·Android**: 각 패키지가 요구하는 네이티브 설정은 들어 있지만, **아직 실제 기기나 시뮬레이터로 빌드해 보지 않았습니다.**
  - 처음 빌드할 때 가장 문제가 생기기 쉬운 곳은 Android Gradle 버전 업그레이드입니다. 아래 Android 항목을 참고하세요.

## iOS 빌드 전 확인

- **최소 버전 iOS 15**: `health` 패키지 요구사항입니다. `ios/Podfile`과 Xcode 프로젝트에 반영되어 있습니다.
- **HealthKit 권한**
  - `ios/Runner/Runner.entitlements`가 프로젝트에 연결되어 있습니다.
  - Xcode의 *Signing & Capabilities*에서 HealthKit이 보이는지 확인하고, 서명 팀(Team)을 지정하세요.
- **건강 앱 권한 문구**: `Info.plist`의 `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`에 있습니다. App Store 심사에서 확인하는 문구이니 필요하면 다듬어 주세요.
- **백그라운드 오디오**
  - `UIBackgroundModes: audio`가 켜져 있어서, 배경 소리를 틀어 두면 화면이 잠겨도 명상이 이어집니다.
  - 심사 때 "왜 백그라운드 오디오가 필요한지" 질문을 받을 수 있습니다.
- **알림**: `AppDelegate.swift`에 `UNUserNotificationCenter` delegate 설정이 추가되어 있습니다.

## Android 빌드 전 확인

- **minSdk 26**: `health` 패키지 요구사항입니다. Android 8.0 미만 기기에는 설치되지 않습니다.
- **Java 17과 core library desugaring**: `flutter_local_notifications` 요구사항입니다.
- **빌드 도구 버전**
  - Android Gradle Plugin 8.11.1, Kotlin 2.1.20, Gradle 8.13으로 올렸습니다.
  - 빌드가 실패하면 먼저 이 버전 조합을 확인하세요.
- **정확한 알림 시각**
  - 완료 알림을 정확한 시각에 받으려면 사용자가 *알람 및 리마인더* 권한을 허용해야 합니다(`SCHEDULE_EXACT_ALARM`).
  - 허용하지 않으면 배터리 절약 모드에서 알림이 몇 분 늦게 올 수 있습니다.
- **알림 종소리 파일**: `android/app/src/main/res/raw/bell.wav`에 있습니다. 릴리스 빌드에서 지워지지 않도록 `keep.xml`로 보호하고 있습니다.

## 플랫폼별 제한

| 항목 | 내용 |
|---|---|
| 건강 앱 연동 | iOS 전용. `health` 패키지가 Android(Health Connect)에서 마음챙김 기록을 지원하지 않습니다. |
| 알림 (웹) | 웹은 예약 알림을 지원하지 않아서 완료 알림·매일 리마인더가 꺼져 있습니다. |
| 화면 켜두기 (웹) | 브라우저가 Wake Lock을 거부할 수 있습니다. 거부되어도 명상은 그대로 진행됩니다. |
| 가이드 음성 | 기기·브라우저에 설치된 한국어 TTS 음성을 쓰므로 목소리가 환경마다 다릅니다. 한국어 음성이 없으면 읽지 않을 수 있습니다. |
| 웹 백그라운드 탭 | 탭이 백그라운드에 있으면 브라우저가 화면 갱신을 늦춥니다. 시간 계산은 정확하게 유지됩니다. |

## 동작 방식에서 알아 둘 점

- **완료 알림 예약 시점**
  - 명상 중에 앱이 백그라운드로 갈 때 끝나는 시각으로 예약하고, 앱으로 돌아오면 취소합니다.
  - 그래서 앱 안에 있을 때는 앱이 직접 종을 울리고, 알림 소리와 겹치지 않습니다.
- **기록 기준**: 1분 미만으로 하다 그만둔 명상은 기록하지 않습니다.
- **데이터 저장 위치**
  - 설정과 기록은 기기 안(`shared_preferences`)에만 저장됩니다.
  - 앱을 지우면 함께 사라지고, 기기 간 동기화는 되지 않습니다.
