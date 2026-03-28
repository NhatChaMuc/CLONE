// File: lib/screens/practice_screen.dart
import 'dart:convert';
// ignore: unused_import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'result_screen.dart';
import '../services/audio_recorder_service.dart';
// ignore: unused_import
import 'dart:io' as io;

const Color primaryColor = Color(0xFF0EA5E9);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color surfaceColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color subtleTextColor = Color(0xFF64748B);
const Color errorColor = Color(0xFFEF4444);

enum PracticeState { idle, recording, processing }

class PracticeScreen extends StatefulWidget {
  final String? initialSentence;
  const PracticeScreen({super.key, this.initialSentence});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with SingleTickerProviderStateMixin {
  late final AudioRecorderService _recorderService;
  final FlutterTts _flutterTts = FlutterTts();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  PracticeState _state = PracticeState.idle;
  String? _transcriptionResult;
  // ignore: unused_field
  String? _errorMessage;

  final List<String> _sentences = [
    "What's your name",
    "How are you",
    "I am learning English",
    "Can you help me",
    "Good morning",
  ];
  late String _selectedSentence;

  @override
  void initState() {
    super.initState();
    _initializeSentence();

    _recorderService = AudioRecorderService();
    _recorderService.requestPermission();
    _initTts();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initializeSentence() {
    if (widget.initialSentence != null && widget.initialSentence!.isNotEmpty) {
      if (!_sentences.contains(widget.initialSentence)) {
        _sentences.insert(0, widget.initialSentence!);
      }
      _selectedSentence = widget.initialSentence!;
    } else {
      _selectedSentence = _sentences.first;
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _toggleRecording() async {
    if (_state == PracticeState.recording) {
      _animationController.reset();
      setState(() => _state = PracticeState.processing);
      try {
        final recordingData = await _recorderService.stopRecording();
        if (recordingData != null) {
          await _submitPracticeRecording(recordingData);
        }
      } catch (e) {
        _showErrorSnackbar('Failed to stop recording: $e');
      } finally {
        if (mounted) setState(() => _state = PracticeState.idle);
      }
    } else {
      try {
        await _recorderService.startRecording();
        _animationController.repeat(reverse: true);
        setState(() => _state = PracticeState.recording);
      } catch (e) {
        _showErrorSnackbar(
          'Could not start recording. Please grant microphone permissions.',
        );
        _recorderService.requestPermission();
      }
    }
  }

  Future<void> _submitPracticeRecording(RecordingData recordingData) async {
    setState(() => _state = PracticeState.processing);
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
                filename: 'recording.${recordingData.mimeType.split('/').last}',
              ),
            )
            ..fields['target'] = _selectedSentence;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 && mounted) {
        final result = jsonDecode(responseData);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(resultData: result),
          ),
        );
      } else {
        _showErrorSnackbar("API Failed with code: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackbar("Error submitting practice: $e");
    } finally {
      if (mounted) setState(() => _state = PracticeState.idle);
    }
  }

  Future<void> _handleFileTranscription() async {
    setState(() {
      _state = PracticeState.processing;
      _transcriptionResult = null;
      _errorMessage = null;
    });
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result == null) {
        setState(() => _state = PracticeState.idle);
        return;
      }

      final fileBytes = result.files.single.bytes;
      final fileName = result.files.single.name;

      if (fileBytes == null) {
        throw Exception("Could not read file bytes.");
      }

      var request =
          http.MultipartRequest(
              'POST',
              Uri.parse('http://127.0.0.1:8000/transcribe'),
            )
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                fileBytes,
                filename: fileName,
              ),
            );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(
          () =>
              _transcriptionResult = jsonDecode(responseData)['transcription'],
        );
      } else {
        _showErrorSnackbar("API Failed with code: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackbar("Error picking or uploading file: $e");
    } finally {
      if (mounted) setState(() => _state = PracticeState.idle);
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isBusy = _state != PracticeState.idle;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Speaking Practice',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: surfaceColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSentenceCard(isBusy),
            const SizedBox(height: 32),
            _buildRecordingSection(),
            const SizedBox(height: 24),
            const Divider(height: 32),
            _buildTranscriptionSection(isBusy),
          ],
        ),
      ),
    );
  }

  Widget _buildSentenceCard(bool isBusy) {
    return Card(
      elevation: 2,
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SENTENCE TO PRACTICE",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSentence,
                      isExpanded: true,
                      items: _sentences
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: textColor,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isBusy
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _selectedSentence = val);
                              }
                            },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.volume_up,
                    color: subtleTextColor,
                    size: 28,
                  ),
                  onPressed: isBusy ? null : () => _speak(_selectedSentence),
                  tooltip: 'Hear pronunciation',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection() {
    String statusText;
    switch (_state) {
      case PracticeState.recording:
        statusText = "Tap to Stop";
        break;
      case PracticeState.processing:
        statusText = "Processing...";
        break;
      case PracticeState.idle:
        statusText = "Tap to Record";
        break;
    }

    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: _state == PracticeState.processing ? null : _toggleRecording,
            child: Container(
              width: 120,
              height: 120,
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
              child: _state == PracticeState.processing
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Icon(
                      _state == PracticeState.recording
                          ? Icons.stop
                          : Icons.mic,
                      color: Colors.white,
                      size: 60,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 16,
            color: subtleTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptionSection(bool isBusy) {
    return Column(
      children: [
        const Text(
          "Or, Transcribe an Audio File",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child:
              _state == PracticeState.processing && _transcriptionResult == null
              ? const Center(child: CircularProgressIndicator())
              : _transcriptionResult == null
              ? const Center(
                  child: Text(
                    "Upload an audio file to see the transcription here.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtleTextColor),
                  ),
                )
              : Text(
                  _transcriptionResult!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: isBusy ? null : _handleFileTranscription,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Audio'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
