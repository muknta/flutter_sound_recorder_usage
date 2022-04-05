import 'dart:async';

import 'package:bug_flutter_sound_recorder/audio_play.dart';
import 'package:bug_flutter_sound_recorder/audio_record.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  final String _title = 'FlutterSound(Recorder/Player) Issue';

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: _title,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: _title),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key) {
    _player = AudioPlay(fileName: _fileName);
    _recorder = AudioRecord(fileName: _fileName);
  }

  final String title;

  final _fileName = '/pronunciation_record.aac';
  final _tickDuration = const Duration(seconds: 1);

  late final AudioPlay _player;
  late final AudioRecord _recorder;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late bool _isRecording;
  late bool _isPlaying;
  late String _recordTitle;
  late String _playerTitle;
  late Duration duration;

  String? basePath;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isRecording = false;
    _isPlaying = false;
    duration = Duration.zero;
  }

  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      print('request');
    }
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    _recordTitle = _isRecording ? 'Tap to stop recording\n${duration.inSeconds} seconds' : 'Record';
    _playerTitle = _isPlaying ? 'Tap to stop playing\n${duration.inSeconds} seconds' : 'Play';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: FutureBuilder<bool>(
          future: _requestMicrophonePermission(),
          builder: (context, isGrantedSnap) => isGrantedSnap.hasData && (isGrantedSnap.data ?? false)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _getTitleWidget(_recordTitle),
                        FloatingActionButton(
                          onPressed: () async => _isRecording ? _stopRecording() : _recordAudio(),
                          tooltip: _recordTitle,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _getTitleWidget(_playerTitle),
                        FloatingActionButton(
                          onPressed: () async => _isPlaying ? _stopPlaying() : _playAudio(),
                          tooltip: _playerTitle,
                          child: const Icon(Icons.view_array),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Give microphone permission'),
                    ),
                    const Text('or reinstall an app'),
                  ],
                ),
        ),
      ),
    );
  }

  ScaffoldFeatureController _getSnackBar([String message = 'Error']) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

  Widget _getTitleWidget(String title) => Padding(
        padding: const EdgeInsets.all(40.0),
        child: Text(
          title,
          textAlign: TextAlign.center,
        ),
      );

  Future<void> _recordAudio() async {
    basePath ??= (await getApplicationDocumentsDirectory()).path;
    if (!_isPlaying) {
      await _stopRecording();
      await widget._recorder.startRecord(basePath!);

      setState(() {
        _isRecording = true;
        _timer?.cancel();
        _timer = Timer.periodic(
          widget._tickDuration,
          (timer) => setState(() {
            duration += widget._tickDuration;
            _isRecording = true;
          }),
        );
      });
    } else {
      _getSnackBar('Finish playing before recording');
    }
  }

  Future<void> _stopRecording() async {
    await widget._recorder.stopRecord();
    setState(() {
      _cancelRecordingStaff();
    });
  }

  Future<void> _playAudio() async {
    basePath ??= (await getApplicationDocumentsDirectory()).path;
    if (!_isRecording) {
      duration = await widget._player.playFromLocalRecord(basePath!);
      setState(() {
        _isPlaying = true;
        _timer?.cancel();
        _timer = Timer.periodic(
          widget._tickDuration,
          (timer) => setState(() {
            if (duration.inSeconds < widget._tickDuration.inSeconds) {
              _cancelPlayingStaff();
              return;
            }
            duration -= widget._tickDuration;
            _isPlaying = true;
          }),
        );
      });
    } else {
      _getSnackBar('Finish recording before playing');
    }
  }

  Future<void> _stopPlaying() async {
    await widget._player.stopPlaying();
    setState(() {
      _cancelPlayingStaff();
    });
  }

  void _cancelRecordingStaff() {
    _isRecording = false;
    _timer?.cancel();
    duration = Duration.zero;
  }

  void _cancelPlayingStaff() {
    _isPlaying = false;
    _timer?.cancel();
    duration = Duration.zero;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
