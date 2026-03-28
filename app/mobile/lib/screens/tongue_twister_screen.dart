// File: lib/screens/tongue_twister_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/tongue_twister_service.dart';
import 'result_screen.dart';
import '../services/audio_recorder_service.dart';

const Color primaryColor = Color(0xFF0EA5E9);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color surfaceColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color subtleTextColor = Color(0xFF64748B);
const Color accentColor = Color(0xFFF97316);

enum ScreenState { idle, recording, loadingResult, showingResult }

class TongueTwisterScreen extends StatefulWidget {
  const TongueTwisterScreen({super.key});

  @override
  State<TongueTwisterScreen> createState() => _TongueTwisterScreenState();
}

class _TongueTwisterScreenState extends State<TongueTwisterScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<String>> _twistersFuture;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  late final AudioRecorderService _audioRecorderService;
  late final AnimationController _animationController;

  int _currentIndex = 0;
  ScreenState _screenState = ScreenState.idle;
  Map<String, dynamic>? _currentResult;

  @override
  void initState() {
    super.initState();
    _twistersFuture = TongueTwisterService.getTongueTwisters();
    _audioRecorderService = AudioRecorderService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _audioRecorderService.requestPermission();
  }

  Future<void> _toggleRecording(String sentence) async {
    if (_screenState == ScreenState.recording) {
      try {
        final recordingData = await _audioRecorderService.stopRecording();
        if (mounted) setState(() => _screenState = ScreenState.idle);
        if (recordingData != null) {
          _submitRecording(
            recordingData.bytes,
            recordingData.mimeType,
            sentence,
          );
        }
      } catch (e) {
        _showErrorSnackbar('Failed to stop recording: $e');
        if (mounted) setState(() => _screenState = ScreenState.idle);
      }
    } else {
      try {
        await _audioRecorderService.startRecording();
        if (mounted) setState(() => _screenState = ScreenState.recording);
      } catch (e) {
        _showErrorSnackbar(
          'Could not start recording: $e. Please grant microphone permissions.',
        );
        _audioRecorderService.requestPermission();
      }
    }
  }

  Future<void> _submitRecording(
    List<int> audioBytes,
    String mimeType,
    String target,
  ) async {
    setState(() => _screenState = ScreenState.loadingResult);
    try {
      var request =
          http.MultipartRequest(
              'POST',
              Uri.parse('http://127.0.0.1:8000/practice'),
            )
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                audioBytes,
                filename:
                    'recording.${mimeType.split('/').last.split(';').first}',
              ),
            )
            ..fields['target'] = target;

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        setState(() {
          _currentResult = json.decode(responseData);
          _screenState = ScreenState.showingResult;
        });
      } else {
        final errorBody = await response.stream.bytesToString();
        _showErrorSnackbar(
          'Failed to get result. Status: ${response.statusCode}, Body: $errorBody',
        );
        setState(() => _screenState = ScreenState.idle);
      }
    } catch (e) {
      _showErrorSnackbar('Error submitting recording: $e');
      if (mounted) setState(() => _screenState = ScreenState.idle);
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _nextTwister(int total) {
    if (_currentIndex < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _currentResult = null;
      _screenState = ScreenState.idle;
    });
  }

  void _retryTwister() {
    setState(() {
      _currentResult = null;
      _screenState = ScreenState.idle;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _currentResult = null;
      if (_screenState == ScreenState.recording) {
        _audioRecorderService.stopRecording();
      }
      _screenState = ScreenState.idle;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioRecorderService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tongue Twister Challenge',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: surfaceColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: FutureBuilder<List<String>>(
        future: _twistersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text(snapshot.error?.toString() ?? 'No challenges found.'),
            );
          }
          final twisters = snapshot.data!;
          return Column(
            children: [
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: twisters.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return _buildTwisterCard(twisters[index], isSelected);
                  },
                ),
              ),
              const Spacer(),
              _buildInteractionArea(twisters),
              const Spacer(flex: 2),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTwisterCard(String text, bool isSelected) {
    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.85,
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isSelected
              ? const BorderSide(color: accentColor, width: 2.5)
              : BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionArea(List<String> twisters) {
    switch (_screenState) {
      case ScreenState.loadingResult:
        return const Center(child: CircularProgressIndicator());
      case ScreenState.showingResult:
        return _buildResultView(twisters.length);
      case ScreenState.recording:
      case ScreenState.idle:
      // ignore: unreachable_switch_default
      default:
        return _buildRecordingView(twisters[_currentIndex]);
    }
  }

  Widget _buildResultView(int totalTwisters) {
    if (_currentResult == null) return const SizedBox.shrink();
    final score = _currentResult!['score'] ?? 0;
    return Column(
      children: [
        Text(
          'Your Score',
          style: TextStyle(fontSize: 20, color: subtleTextColor),
        ),
        const SizedBox(height: 8),
        Text(
          '$score%',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(resultData: _currentResult!),
            ),
          ),
          child: const Text('View Detailed Result'),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _retryTwister,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _nextTwister(totalTwisters),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordingView(String currentTwister) {
    final isRecording = _screenState == ScreenState.recording;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _toggleRecording(currentTwister),
          child: ScaleTransition(
            scale: isRecording
                ? Tween<double>(
                    begin: 1.0,
                    end: 1.15,
                  ).animate(_animationController)
                : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.red : primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? Colors.red : primaryColor)
                        .withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isRecording ? "Recording... Tap to stop" : "Tap to record",
          style: const TextStyle(fontSize: 16, color: subtleTextColor),
        ),
      ],
    );
  }
}
