/// 건강 앱 연동을 지원하지 않는 플랫폼용 빈 구현.
class HealthService {
  bool get isSupported => false;
  Future<bool> requestPermission() async => false;
  Future<void> recordMindfulness(DateTime start, DateTime end) async {}
}
