import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum SoundType {
  questComplete,
  missionAccepted,
  levelUp,
  xpGain,
}

class SoundService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _enabled = true;

  Future<void> playSound(SoundType type) async {
    if (!_enabled) {
      print('Sound disabled');
      return;
    }

    print('Playing sound: $type');

    try {
      await _playAudioTone(type);
    } catch (e) {
      print('Audio error: $e, falling back to haptic');
      await _fallbackToHaptic(type);
    }
  }

  Future<void> _playAudioTone(SoundType type) async {
    try {
      switch (type) {
        case SoundType.questComplete:
          // Victory: three ascending notes
          await _playTone(523, 150); // C5
          await Future.delayed(const Duration(milliseconds: 100));
          await _playTone(659, 150); // E5
          await Future.delayed(const Duration(milliseconds: 100));
          await _playTone(784, 200); // G5
          break;

        case SoundType.missionAccepted:
          // Acceptance: two notes
          await _playTone(440, 200); // A4
          await Future.delayed(const Duration(milliseconds: 100));
          await _playTone(523, 200); // C5
          break;

        case SoundType.levelUp:
          // Fanfare: ascending
          await _playTone(523, 120); // C5
          await Future.delayed(const Duration(milliseconds: 50));
          await _playTone(659, 120); // E5
          await Future.delayed(const Duration(milliseconds: 50));
          await _playTone(784, 120); // G5
          await Future.delayed(const Duration(milliseconds: 50));
          await _playTone(1047, 300); // C6
          break;

        case SoundType.xpGain:
          // Single note
          await _playTone(600, 100);
          break;
      }
    } catch (e) {
      print('Tone generation failed: $e');
      throw e;
    }
  }

  Future<void> _playTone(int frequency, int durationMs) async {
    try {
      await _audioPlayer.stop();
      
      // Create raw audio data for a sine wave
      const sampleRate = 44100;
      final numSamples = (sampleRate * durationMs) ~/ 1000;
      
      List<int> wavData = _generateWavData(frequency, durationMs, sampleRate, numSamples);
      
      // Play the generated audio using play() with BytesSource
      await _audioPlayer.play(
        BytesSource(Uint8List.fromList(wavData)),
      );
      
      // Wait for the tone to finish
      await Future.delayed(Duration(milliseconds: durationMs));
      print('Tone played: $frequency Hz for ${durationMs}ms');
    } catch (e) {
      print('Tone playback error: $e');
      throw e;
    }
  }

  List<int> _generateWavData(int frequency, int durationMs, int sampleRate, int numSamples) {
    // WAV file header (44 bytes)
    const int headerSize = 44;
    final int dataSize = numSamples * 2; // 16-bit samples
    final int fileSize = headerSize + dataSize - 8;

    final List<int> wavFile = List<int>.filled(headerSize + dataSize, 0);

    // RIFF header
    wavFile[0] = 0x52; // 'R'
    wavFile[1] = 0x49; // 'I'
    wavFile[2] = 0x46; // 'F'
    wavFile[3] = 0x46; // 'F'
    
    // File size
    wavFile[4] = fileSize & 0xFF;
    wavFile[5] = (fileSize >> 8) & 0xFF;
    wavFile[6] = (fileSize >> 16) & 0xFF;
    wavFile[7] = (fileSize >> 24) & 0xFF;
    
    // WAVE header
    wavFile[8] = 0x57;  // 'W'
    wavFile[9] = 0x41;  // 'A'
    wavFile[10] = 0x56; // 'V'
    wavFile[11] = 0x45; // 'E'
    
    // fmt subchunk
    wavFile[12] = 0x66; // 'f'
    wavFile[13] = 0x6D; // 'm'
    wavFile[14] = 0x74; // 't'
    wavFile[15] = 0x20; // ' '
    
    // Subchunk1Size = 16
    wavFile[16] = 16;
    wavFile[17] = 0;
    wavFile[18] = 0;
    wavFile[19] = 0;
    
    // AudioFormat = 1 (PCM)
    wavFile[20] = 1;
    wavFile[21] = 0;
    
    // NumChannels = 1
    wavFile[22] = 1;
    wavFile[23] = 0;
    
    // SampleRate
    wavFile[24] = sampleRate & 0xFF;
    wavFile[25] = (sampleRate >> 8) & 0xFF;
    wavFile[26] = (sampleRate >> 16) & 0xFF;
    wavFile[27] = (sampleRate >> 24) & 0xFF;
    
    // ByteRate = SampleRate * NumChannels * BitsPerSample / 8
    final byteRate = sampleRate * 2;
    wavFile[28] = byteRate & 0xFF;
    wavFile[29] = (byteRate >> 8) & 0xFF;
    wavFile[30] = (byteRate >> 16) & 0xFF;
    wavFile[31] = (byteRate >> 24) & 0xFF;
    
    // BlockAlign = NumChannels * BitsPerSample / 8
    wavFile[32] = 2;
    wavFile[33] = 0;
    
    // BitsPerSample = 16
    wavFile[34] = 16;
    wavFile[35] = 0;
    
    // data subchunk
    wavFile[36] = 0x64; // 'd'
    wavFile[37] = 0x61; // 'a'
    wavFile[38] = 0x74; // 't'
    wavFile[39] = 0x61; // 'a'
    
    // Subchunk2Size
    wavFile[40] = dataSize & 0xFF;
    wavFile[41] = (dataSize >> 8) & 0xFF;
    wavFile[42] = (dataSize >> 16) & 0xFF;
    wavFile[43] = (dataSize >> 24) & 0xFF;
    
    // Generate sine wave data
    for (int i = 0; i < numSamples; i++) {
      final value = sin(2.0 * pi * frequency * i / sampleRate) * 32767 * 0.5;
      final sample = value.toInt();
      
      final offset = headerSize + i * 2;
      wavFile[offset] = sample & 0xFF;
      wavFile[offset + 1] = (sample >> 8) & 0xFF;
    }

    return wavFile;
  }

  Future<void> _fallbackToHaptic(SoundType type) async {
    try {
      print('Using haptic feedback for: $type');
      switch (type) {
        case SoundType.questComplete:
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
          print('Quest complete haptic sequence done');
          break;
        case SoundType.missionAccepted:
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 150));
          await HapticFeedback.lightImpact();
          print('Mission accepted haptic sequence done');
          break;
        case SoundType.levelUp:
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
          print('Level up haptic sequence done');
          break;
        case SoundType.xpGain:
          await HapticFeedback.lightImpact();
          print('XP gain haptic done');
          break;
      }
    } catch (e) {
      print('Haptic feedback error: $e');
    }
  }

  void toggleSound(bool enabled) {
    _enabled = enabled;
    print('Sound ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
