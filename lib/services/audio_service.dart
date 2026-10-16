import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/ambient_sounds.dart';

/// 종소리, 배경 소리, 가이드 음성을 재생한다.
class AudioService {
  final _bell = AudioPlayer();
  final _ambient = AudioPlayer();
  final _tts = FlutterTts();
  bool _ttsReady = false;
  AmbientSound _currentAmbient = AmbientSound.none;

  /// 종을 울린다. 중간 종은 [volume]을 낮춰 부드럽게.
  Future<void> playBell({double volume = 1}) async {
    try {
      await _bell.stop();
      await _bell.setVolume(volume);
      await _bell.play(AssetSource('sounds/bell.wav'));
    } catch (e) {
      debugPrint('종소리 재생 실패: $e');
    }
  }

  Future<void> startAmbient(AmbientSound sound, double volume) async {
    _currentAmbient = sound;
    final asset = sound.asset;
    if (asset == null) return stopAmbient();
    try {
      await _ambient.setReleaseMode(ReleaseMode.loop);
      await _ambient.setVolume(volume);
      await _ambient.play(AssetSource(asset));
    } catch (e) {
      debugPrint('배경 소리 재생 실패: $e');
    }
  }

  Future<void> setAmbientVolume(double volume) => _ambient.setVolume(volume);

  /// 명상 중에 배경 소리 설정이 바뀌면 바로 반영한다.
  Future<void> changeAmbient(AmbientSound sound, double volume) async {
    if (sound == _currentAmbient) return setAmbientVolume(volume);
    await startAmbient(sound, volume);
  }

  Future<void> pauseAmbient() => _ambient.pause();
  Future<void> resumeAmbient() async {
    if (_currentAmbient != AmbientSound.none) await _ambient.resume();
  }

  Future<void> stopAmbient() async {
    _currentAmbient = AmbientSound.none;
    await _ambient.stop();
  }

  Future<void> speak(String text) async {
    try {
      if (!_ttsReady) {
        await _tts.setLanguage('ko-KR');
        await _tts.setSpeechRate(kIsWeb ? 0.8 : 0.42); // 차분하게
        await _tts.setPitch(0.95);
        _ttsReady = true;
      }
      await _tts.speak(text);
    } catch (e) {
      debugPrint('가이드 음성 재생 실패: $e');
    }
  }

  Future<void> stopSpeaking() => _tts.stop();
}
