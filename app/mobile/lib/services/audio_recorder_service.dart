// File: lib/services/audio_recorder_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

// Conditional import for web
import 'dart:html' as html if (dart.library.html) 'dart:html';

import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

class RecordingData {
  final List<int> bytes;
  final String mimeType;
  RecordingData(this.bytes, this.mimeType);
}

class AudioRecorderService {
  dynamic _audioRecorder;
  List<html.Blob> _webAudioChunks = [];
  bool get isRecording => _isRecording;
  bool _isRecording = false;

  AudioRecorderService() {
    if (!kIsWeb) {
      _audioRecorder = AudioRecorder();
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) {
      debugPrint(
        "[AudioService-Web] Permission will be requested by browser on start.",
      );
      return true;
    } else {
      debugPrint("[AudioService-Mobile] Requesting microphone permission...");
      final status = await Permission.microphone.request();
      debugPrint("[AudioService-Mobile] Permission status: $status");
      return status == PermissionStatus.granted;
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    if (kIsWeb) {
      try {
        debugPrint(
          "[AudioService-Web] Requesting media devices (getUserMedia)...",
        );
        final stream = await html.window.navigator.mediaDevices!.getUserMedia({
          'audio': true,
        });
        debugPrint("[AudioService-Web] Media stream acquired successfully!");

        _audioRecorder = html.MediaRecorder(stream, {'mimeType': 'audio/webm'});
        _webAudioChunks = [];

        _audioRecorder.addEventListener('dataavailable', (html.Event event) {
          if (event is html.BlobEvent && event.data != null) {
            _webAudioChunks.add(event.data!);
          }
        });
        _audioRecorder.start();
        debugPrint("[AudioService-Web] Recording started.");
      } catch (e) {
        debugPrint("[AudioService-Web] ERROR starting recording: $e");
        throw Exception(
          "Failed to start web recording: $e. Ensure you are on HTTPS and have granted permissions.",
        );
      }
    } else {
      if (await (_audioRecorder as AudioRecorder).hasPermission()) {
        final dir = await getTemporaryDirectory();
        await (_audioRecorder as AudioRecorder).start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
          path: '${dir.path}/recording.wav',
        );
        debugPrint("[AudioService-Mobile] Recording started.");
      } else {
        debugPrint("[AudioService-Mobile] Microphone permission not granted.");
        throw Exception("Microphone permission not granted.");
      }
    }
    _isRecording = true;
  }

  Future<RecordingData?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      if (kIsWeb) {
        final completer = Completer<RecordingData?>();
        _audioRecorder.addEventListener('stop', (_) async {
          debugPrint(
            "[AudioService-Web] Recording stopped. Processing audio chunks...",
          );
          final blob = html.Blob(_webAudioChunks, 'audio/webm');
          final reader = html.FileReader();
          reader.readAsArrayBuffer(blob);
          await reader.onLoadEnd.first;
          final bytes = List<int>.from(reader.result as List<int>);
          debugPrint(
            "[AudioService-Web] Audio processed into ${bytes.length} bytes.",
          );
          completer.complete(RecordingData(bytes, 'audio/webm'));
        });

        (_audioRecorder as html.MediaRecorder).stop();
        if ((_audioRecorder as html.MediaRecorder).stream != null) {
          (_audioRecorder as html.MediaRecorder).stream!.getTracks().forEach(
            (track) => track.stop(),
          );
        }
        return completer.future;
      } else {
        final path = await (_audioRecorder as AudioRecorder).stop();
        debugPrint("[AudioService-Mobile] Recording stopped. Path: $path");
        if (path != null) {
          final file = io.File(path);
          final bytes = await file.readAsBytes();
          debugPrint(
            "[AudioService-Mobile] Audio file read into ${bytes.length} bytes.",
          );
          return RecordingData(bytes, 'audio/wav');
        }
      }
    } finally {
      _isRecording = false;
    }
    return null;
  }

  void dispose() {
    if (!kIsWeb && _audioRecorder != null) {
      (_audioRecorder as AudioRecorder).dispose();
    }
  }
}
