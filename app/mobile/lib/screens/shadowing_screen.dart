import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class ShadowingScreen extends StatefulWidget {
  final String sentence;
  final String audioUrl;

  const ShadowingScreen({
    super.key,
    required this.sentence,
    required this.audioUrl,
  });

  @override
  _ShadowingScreenState createState() => _ShadowingScreenState();
}

class _ShadowingScreenState extends State<ShadowingScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool _isPlayerReady = false;
  bool _isRecorderReady = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isFinished = false;

  double _playbackProgress = 0.0;
  Duration _totalDuration = Duration.zero;
  String? _pathToAudio;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _totalDuration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (_totalDuration > Duration.zero && mounted) {
        setState(
          () => _playbackProgress =
              p.inMilliseconds / _totalDuration.inMilliseconds,
        );
      }
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isRecording) _stopShadowing();
    });

    try {
      await _audioPlayer.setSourceUrl(widget.audioUrl);
      setState(() => _isPlayerReady = true);
    } catch (e) {
      print("Error setting audio source: $e");
    }

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _recorder.openRecorder();
    final tempDir = await getTemporaryDirectory();
    _pathToAudio = '${tempDir.path}/shadowing_record.wav';

    setState(() => _isRecorderReady = true);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _startShadowing() async {
    if (!_isPlayerReady || !_isRecorderReady || _isRecording) return;

    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.resume();

    await _recorder.startRecorder(toFile: _pathToAudio, codec: Codec.pcm16WAV);
    setState(() {
      _isRecording = true;
      _isFinished = false;
    });
  }

  Future<void> _stopShadowing() async {
    if (!_isRecording) return;
    await _recorder.stopRecorder();
    if (_isPlaying) await _audioPlayer.pause();
    setState(() {
      _isRecording = false;
      _isFinished = true;
      _playbackProgress = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recording finished! Ready to analyze.')),
    );
  }

  void _reset() {
    _audioPlayer.seek(Duration.zero);
    setState(() {
      _isFinished = false;
      _playbackProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canStart = _isPlayerReady && _isRecorderReady && !_isRecording;
    return Scaffold(
      appBar: AppBar(title: const Text('Shadowing Practice')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Listen and repeat simultaneously:',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.sentence,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            const Text('Original Audio Progress'),
            LinearProgressIndicator(
              value: _playbackProgress,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Your Voice Progress'),
            LinearProgressIndicator(
              value: _isRecording ? _playbackProgress : 0.0,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
            ),
            const Spacer(),
            if (_isFinished)
              Column(
                children: [
                  const Text(
                    "Finished! Analyze your speech or try again.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _reset,
                        icon: Icon(Icons.refresh),
                        label: Text("Try Again"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.analytics),
                        label: Text("Analyze"),
                      ),
                    ],
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: canStart ? _startShadowing : null,
                icon: Icon(_isRecording ? Icons.pause : Icons.mic, size: 32),
                label: Text(
                  _isRecording ? 'Recording...' : 'Start Shadowing',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording
                      ? Colors.grey
                      : Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
