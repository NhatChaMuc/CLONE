// File: lib/screens/scenario_chat_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'scenario_list_screen.dart';
import '../services/audio_recorder_service.dart';
// ignore: unused_import, depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
// ignore: unused_import
import 'package:record/record.dart';

const Color primaryColor = Color(0xFF0EA5E9);
const Color backgroundColor = Color(0xFFF1F5F9);
const Color surfaceColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color subtleTextColor = Color(0xFF64748B);
const Color errorColor = Color(0xFFEF4444);

enum MessageRole { user, assistant, error }

class ChatUIMessage {
  final String text;
  final MessageRole role;
  ChatUIMessage(this.text, this.role);
}

enum ChatState { idle, recording, processing }

class ScenarioChatScreen extends StatefulWidget {
  final Scenario scenario;
  // ignore: use_super_parameters
  const ScenarioChatScreen({Key? key, required this.scenario})
    : super(key: key);

  @override
  State<ScenarioChatScreen> createState() => _ScenarioChatScreenState();
}

class _ScenarioChatScreenState extends State<ScenarioChatScreen>
    with TickerProviderStateMixin {
  late final AudioRecorderService _audioRecorderService;
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _animationController;

  ChatState _state = ChatState.idle;
  final List<ChatUIMessage> _messages = [];
  Timer? _timeoutTimer;

  final String _apiUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    _audioRecorderService = AudioRecorderService();
    _audioRecorderService.requestPermission();
    _initTts();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _startConversation();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  void _startConversation() {
    _addBotMessage(
      "Hi! Let's practice the '${widget.scenario.title}'. What's your first response?",
      MessageRole.assistant,
    );
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text, {bool isUserMessage = true}) async {
    if (text.trim().isEmpty || _state != ChatState.idle) return;

    if (isUserMessage) {
      setState(() => _messages.add(ChatUIMessage(text, MessageRole.user)));
    }

    setState(() => _state = ChatState.processing);

    if (isUserMessage) _textController.clear();
    _scrollToBottom();

    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _state == ChatState.processing) {
        setState(() {
          _state = ChatState.idle;
          _messages.add(
            ChatUIMessage(
              "Sorry, the AI is taking too long. Please try again.",
              MessageRole.error,
            ),
          );
        });
        _scrollToBottom();
      }
    });

    try {
      final List<Map<String, dynamic>> history = [];
      for (var msg in _messages) {
        if (msg.role == MessageRole.user) {
          history.add({"user_message": msg.text});
        } else if (msg.role == MessageRole.assistant) {
          if (history.isNotEmpty) {
            history.last["chatbot_response"] = msg.text;
          }
        }
      }

      final request = http.Request('POST', Uri.parse('$_apiUrl/chat'))
        ..headers['Content-Type'] = 'application/json'
        ..body = json.encode({
          'message': text,
          'history': history,
          'system_prompt_override': widget.scenario.systemPrompt,
        });

      final streamedResponse = await request.send();

      _timeoutTimer?.cancel();

      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        final data = json.decode(response.body);

        if (data.containsKey('response') && data['response'] != null) {
          _addBotMessage(data['response'], MessageRole.assistant);
        } else {
          _addBotMessage(
            "Received an empty response from the AI.",
            MessageRole.error,
          );
        }
      } else {
        _addBotMessage(
          'Server Error: ${streamedResponse.reasonPhrase}',
          MessageRole.error,
        );
      }
    } catch (e) {
      _addBotMessage(
        'Connection Error. Please check your network.',
        MessageRole.error,
      );
    } finally {
      if (mounted) setState(() => _state = ChatState.idle);
    }
  }

  void _addBotMessage(String text, MessageRole role) {
    if (mounted) {
      setState(() => _messages.add(ChatUIMessage(text, role)));
      _scrollToBottom();
      if (role == MessageRole.assistant) {
        _speak(text);
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_state == ChatState.idle) {
      try {
        await _audioRecorderService.startRecording();
        _animationController.repeat(reverse: true);
        setState(() => _state = ChatState.recording);
      } catch (e) {
        _addBotMessage(
          "Microphone permission denied! Please enable it in settings.",
          MessageRole.error,
        );
      }
    } else if (_state == ChatState.recording) {
      _animationController.reset();
      setState(() => _state = ChatState.processing);

      try {
        final recordingData = await _audioRecorderService.stopRecording();
        if (recordingData != null) {
          final transcription = await _transcribeAudio(recordingData);
          if (transcription != null && transcription.isNotEmpty) {
            if (mounted) setState(() => _state = ChatState.idle);
            await _sendMessage(transcription);
          } else {
            _addBotMessage(
              "Sorry, I couldn't understand that. Please try again.",
              MessageRole.error,
            );
          }
        } else {
          _addBotMessage(
            "Recording failed. No audio data captured.",
            MessageRole.error,
          );
        }
      } catch (e) {
        _addBotMessage("Error processing audio: $e", MessageRole.error);
      } finally {
        if (mounted && _state != ChatState.idle) {
          setState(() => _state = ChatState.idle);
        }
      }
    }
  }

  Future<String?> _transcribeAudio(RecordingData recordingData) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$_apiUrl/transcribe'))
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                recordingData.bytes,
                filename: 'recording.wav',
              ),
            );
      var response = await request.send().timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        return jsonDecode(responseData)['transcription'];
      }
    } catch (e) {
      // ignore: avoid_print
      print("Transcription failed: $e");
    }
    return null;
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _audioRecorderService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.scenario.title,
          style: const TextStyle(color: textColor),
        ),
        backgroundColor: surfaceColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          _buildScenarioHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatMessageBubble(
                  message: message,
                  onSpeak: () => _speak(message.text),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildScenarioHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: surfaceColor,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.flag_circle_outlined,
              color: primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR GOAL',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    widget.scenario.goal,
                    style: const TextStyle(color: textColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final hasText = _textController.text.isNotEmpty;
    final isRecording = _state == ChatState.recording;
    final isProcessing = _state == ChatState.processing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: surfaceColor,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onChanged: (text) => setState(() {}),
                enabled: !isProcessing && !isRecording,
                decoration: InputDecoration(
                  hintText: isRecording
                      ? 'Listening...'
                      : (isProcessing
                            ? 'Thinking...'
                            : 'Type or record your response...'),
                  filled: true,
                  fillColor: backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: isProcessing || isRecording
                    ? null
                    : (_) => _sendMessage(_textController.text),
              ),
            ),
            const SizedBox(width: 8),
            if (hasText && !isRecording)
              IconButton(
                icon: const Icon(Icons.send, color: primaryColor),
                onPressed: isProcessing
                    ? null
                    : () => _sendMessage(_textController.text),
              )
            else
              ScaleTransition(
                scale: isRecording
                    ? _animationController
                    : const AlwaysStoppedAnimation(1.0),
                child: FloatingActionButton(
                  onPressed: isProcessing ? null : _toggleRecording,
                  backgroundColor: isRecording ? Colors.red : primaryColor,
                  elevation: 2,
                  child: Icon(isRecording ? Icons.stop : Icons.mic, size: 28),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatUIMessage message;
  final VoidCallback onSpeak;

  const _ChatMessageBubble({required this.message, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isError = message.role == MessageRole.error;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: isUser
              ? primaryColor
              : (isError ? errorColor.withOpacity(0.1) : surfaceColor),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isError ? errorColor : textColor),
                  fontSize: 16,
                ),
              ),
            ),
            if (!isUser && !isError) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onSpeak,
                child: Icon(Icons.volume_up, size: 20, color: subtleTextColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
