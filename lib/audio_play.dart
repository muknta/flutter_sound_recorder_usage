import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';

class AudioPlay {
  AudioPlay({required String fileName}) : _fileName = fileName {
    const logLevel = kDebugMode ? Level.debug : Level.nothing;
    // ignore: avoid_redundant_argument_values
    _player = FlutterSoundPlayer(logLevel: logLevel)..openPlayer();
  }

  final String _fileName;

  late final FlutterSoundPlayer _player;

  Future<Duration> playFromLocalRecord(String basePath) async {
    if (_player.isPlaying) {
      await stopPlaying();
    }
    final String localPath = '$basePath/$_fileName';
    final File soundFile = File(localPath);
    final Uint8List uintSoundFile = soundFile.readAsBytesSync();

    return await _player.startPlayer(
          codec: Codec.aacMP4,
          fromDataBuffer: uintSoundFile,
          whenFinished: () => print('AP_playFromLocalRecord_FINISH'),
        ) ??
        Duration.zero;
  }

  Future<void> stopPlaying() async => _player.stopPlayer();
}
