import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';

class AudioRecord {
  AudioRecord({required String fileName}) : _fileName = fileName {
    const logLevel = kDebugMode ? Level.debug : Level.nothing;
    // ignore: avoid_redundant_argument_values
    _audioRecorder = FlutterSoundRecorder(logLevel: logLevel)..openRecorder();
  }

  final String _fileName;

  late final FlutterSoundRecorder _audioRecorder;

  Future<void> _delFile(String basePath) async {
    final File delFile = File(basePath + _fileName);
    if (delFile.existsSync()) {
      await delFile.delete(recursive: true);
    }
  }

  Future<void> startRecord(String basePath) async {
    if (_audioRecorder.isRecording) {
      await stopRecord();
    }
    await _delFile(basePath);
    await _audioRecorder.startRecorder(
      toFile: basePath + _fileName,
    );
  }

  Future<void> stopRecord() async {
    await _audioRecorder.stopRecorder();
  }
}
