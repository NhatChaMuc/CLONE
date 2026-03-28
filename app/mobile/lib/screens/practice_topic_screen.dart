// File: lib/screens/topic_practice_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'result_screen.dart';
import '../services/audio_recorder_service.dart';

const Color primaryColor = Color(0xFF0EA5E9);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color surfaceColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color subtleTextColor = Color(0xFF64748B);
const Color errorColor = Color(0xFFEF4444);

enum PracticeState { idle, recording, processing }

class TopicPracticeScreen extends StatefulWidget {
  final String topicTitle;
  final List<String> sentences;

  const TopicPracticeScreen({
    super.key,
    required this.topicTitle,
    required this.sentences,
  });

  @override
  State<TopicPracticeScreen> createState() => _TopicPracticeScreenState();
}

class _TopicPracticeScreenState extends State<TopicPracticeScreen>
    with SingleTickerProviderStateMixin {
  late final AudioRecorderService _recorderService;
  final FlutterTts _flutterTts = FlutterTts();

  late final PageController _pageController;
  late final AnimationController _animationController;

  PracticeState _state = PracticeState.idle;
  int _currentSentenceIndex = 0;

  @override
  void initState() {
    super.initState();
    _recorderService = AudioRecorderService();
    _recorderService.requestPermission();
    _initTts();

    _pageController = PageController(viewportFraction: 0.85);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _submitPracticeRecording(RecordingData recordingData) async {
    final targetSentence = widget.sentences[_currentSentenceIndex];
    if (targetSentence.isEmpty) return;

    setState(() => _state = PracticeState.processing);
    debugPrint(
      "[PracticeScreen] Submitting recording... Target: '$targetSentence'",
    );

    try {
      var request =
          http.MultipartRequest(
              'POST',
              Uri.parse('http://127.0.0.1:8000/practice'),
            )
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                recordingData.bytes,
                filename:
                    'recording.${recordingData.mimeType.split('/').last.split(';').first}',
              ),
            )
            ..fields['target'] = targetSentence;

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        debugPrint("[PracticeScreen] API Success! Response: $responseData");
        if (mounted) {
          final result = jsonDecode(responseData);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(resultData: result),
            ),
          );
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        final errorMessage =
            "API Failed! Status: ${response.statusCode}, Reason: ${response.reasonPhrase}, Body: $errorBody";
        debugPrint("[PracticeScreen] $errorMessage");
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      final errorMessage = "HTTP Error: $e";
      debugPrint("[PracticeScreen] $errorMessage");
      _showErrorSnackbar(errorMessage);
    } finally {
      if (mounted) setState(() => _state = PracticeState.idle);
    }
  }

  Future<void> _toggleRecording() async {
    if (_state == PracticeState.recording) {
      _animationController.reset();
      setState(() => _state = PracticeState.idle);
      try {
        final recordingData = await _recorderService.stopRecording();
        if (recordingData != null) {
          await _submitPracticeRecording(recordingData);
        }
      } catch (e) {
        _showErrorSnackbar('Failed to stop recording: $e');
      }
    } else {
      try {
        await _recorderService.startRecording();
        _animationController.repeat(reverse: true);
        setState(() => _state = PracticeState.recording);
      } catch (e) {
        _showErrorSnackbar(
          "Could not start recording. Please grant permissions.",
        );
        _recorderService.requestPermission();
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: errorColor),
      );
    }
  }

  @override
  void dispose() {
    _recorderService.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSentence = widget.sentences.isNotEmpty
        ? widget.sentences[_currentSentenceIndex]
        : "No sentences available.";

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.topicTitle,
          style: const TextStyle(color: textColor),
        ),
        backgroundColor: surfaceColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _buildSentenceCarousel(),
          const Spacer(),
          _buildPracticeArea(currentSentence),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSentenceCarousel() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.sentences.length,
        onPageChanged: (index) {
          if (_state == PracticeState.recording) {
            _recorderService.stopRecording();
            _animationController.reset();
          }
          setState(() {
            _currentSentenceIndex = index;
            _state = PracticeState.idle;
          });
        },
        itemBuilder: (context, index) {
          final isSelected = index == _currentSentenceIndex;
          return AnimatedScale(
            scale: isSelected ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 300),
            child: Card(
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isSelected
                    ? const BorderSide(color: primaryColor, width: 2)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    widget.sentences[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? textColor : subtleTextColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPracticeArea(String sentence) {
    bool isBusy = _state == PracticeState.processing;
    String statusText;
    switch (_state) {
      case PracticeState.recording:
        statusText = "Recording... Tap to stop";
        break;
      case PracticeState.processing:
        statusText = "Processing...";
        break;
      case PracticeState.idle:
        statusText = "Tap to record";
        break;
    }

    return Column(
      children: [
        if (isBusy)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else
          IconButton(
            onPressed: () => _speak(sentence),
            icon: const Icon(Icons.volume_up, color: subtleTextColor, size: 32),
            tooltip: 'Hear pronunciation',
          ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: isBusy ? null : _toggleRecording,
          child: ScaleTransition(
            scale: _state == PracticeState.recording
                ? _animationController
                : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _state == PracticeState.recording
                    ? Colors.red
                    : primaryColor,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_state == PracticeState.recording
                                ? Colors.red
                                : primaryColor)
                            .withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: isBusy
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      _state == PracticeState.recording
                          ? Icons.stop_rounded
                          : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          statusText,
          style: const TextStyle(fontSize: 16, color: subtleTextColor),
        ),
      ],
    );
  }
}
