/// 명상 중 반복 재생하는 배경 소리.
enum AmbientSound {
  none('없음', null),
  rain('빗소리', 'sounds/rain.wav'),
  waves('파도', 'sounds/waves.wav'),
  whiteNoise('화이트 노이즈', 'sounds/white_noise.wav'),
  brownNoise('브라운 노이즈', 'sounds/brown_noise.wav');

  const AmbientSound(this.label, this.asset);

  final String label;

  /// `assets/` 아래 경로. [none]이면 null.
  final String? asset;
}
