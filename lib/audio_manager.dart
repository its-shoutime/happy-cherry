import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central music + SFX controller for Happy Cherry.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  static const _mutedKey = 'audio_muted';

  final AudioPlayer _bgm = AudioPlayer(playerId: 'bgm');
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');

  bool _ready = false;
  bool _muted = false;
  bool get muted => _muted;

  Future<void> init() async {
    if (_ready) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _muted = prefs.getBool(_mutedKey) ?? false;

      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: true,
        ).build(),
      );

      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.setVolume(_muted ? 0 : 0.35);
      await _sfx.setReleaseMode(ReleaseMode.stop);
      await _sfx.setVolume(_muted ? 0 : 0.7);

      _ready = true;
    } catch (error, stackTrace) {
      debugPrint('AudioManager init failed: $error\n$stackTrace');
    }
  }

  Future<void> setMuted(bool muted) async {
    _muted = muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutedKey, muted);
      await _bgm.setVolume(muted ? 0 : 0.35);
      await _sfx.setVolume(muted ? 0 : 0.7);
      if (muted) {
        await _bgm.pause();
      } else {
        await playBgm();
      }
    } catch (error, stackTrace) {
      debugPrint('AudioManager setMuted failed: $error\n$stackTrace');
    }
  }

  Future<void> toggleMute() => setMuted(!_muted);

  Future<void> playBgm() async {
    if (!_ready || _muted) return;
    try {
      final state = _bgm.state;
      if (state == PlayerState.playing) return;
      if (state == PlayerState.paused) {
        await _bgm.resume();
        return;
      }
      await _bgm.play(AssetSource('audio/bgm.wav'));
    } catch (error, stackTrace) {
      debugPrint('BGM play failed: $error\n$stackTrace');
    }
  }

  Future<void> pauseBgm() async {
    try {
      await _bgm.pause();
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgm.stop();
    } catch (_) {}
  }

  Future<void> _playSfx(String file) async {
    if (!_ready || _muted) return;
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource('audio/$file'));
    } catch (error, stackTrace) {
      debugPrint('SFX $file failed: $error\n$stackTrace');
    }
  }

  Future<void> playButton() => _playSfx('button.wav');
  Future<void> playFeed() => _playSfx('feed.wav');
  Future<void> playClean() => _playSfx('clean.wav');
  Future<void> playHeal() => _playSfx('heal.wav');
  Future<void> playCatch() => _playSfx('catch.wav');
  Future<void> playMiss() => _playSfx('miss.wav');
  Future<void> playCoin() => _playSfx('coin.wav');
  Future<void> playGameOver() => _playSfx('game_over.wav');
  Future<void> playDeath() => _playSfx('death.wav');
}
