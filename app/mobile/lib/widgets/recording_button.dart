// File: app/mobile/lib/widgets/recording_button.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class RecordingButton extends StatefulWidget {
  final ValueChanged<String> onResult;
  final bool isLoading;

  const RecordingButton({
    super.key,
    required this.onResult,
    this.isLoading = false,
  });

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      final available = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      if (mounted) {
        setState(() {
          _isSpeechAvailable = available;
        });
      }
    } catch (e) {
      print('Could not initialize speech recognition: $e');
    }
  }

  void _startListening() async {
    if (!_isSpeechAvailable || _isListening || widget.isLoading) return;

    await _speechToText.stop();

    setState(() => _isListening = true);

    _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'en-US',
      listenMode: ListenMode.confirmation,
    );
  }

  void _stopListening() async {
    if (!_isListening) return;

    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      final recognizedText = result.recognizedWords;
      print('Final recognized text: $recognizedText');
      widget.onResult(recognizedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = !_isSpeechAvailable || widget.isLoading;
    final bool isRecording = _isListening;

    final buttonColor = isRecording ? Colors.red : Colors.green;
    final icon = isRecording ? Icons.stop : Icons.mic;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: isDisabled
              ? null
              : (isRecording ? _stopListening : _startListening),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDisabled ? Colors.grey : buttonColor,
              shape: BoxShape.circle,
              boxShadow: [
                if (!isDisabled)
                  BoxShadow(
                    color: buttonColor.withOpacity(0.5),
                    blurRadius: isRecording ? 20 : 10,
                    spreadRadius: isRecording ? 5 : 0,
                  ),
              ],
            ),
            child: widget.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Icon(icon, size: 40, color: Colors.white),
          ),
        ),
        if (isRecording) ...[
          const SizedBox(height: 20),
          Lottie.asset(
            'assets/animations/recording.json',
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          const Text(
            "Listening...",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ] else if (!isRecording && !widget.isLoading) ...[
          const SizedBox(height: 20),
          const Text(
            "Tap the button to speak",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
