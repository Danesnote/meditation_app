// health 패키지는 dart:io를 쓰므로 웹 빌드에서는 빈 구현을 쓴다.
export 'health_service_stub.dart'
    if (dart.library.io) 'health_service_io.dart';
