import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/audio_recorder_service.dart';
import 'dart:async';
// ignore: unused_import
import 'dart:io' show Platform;

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

class ConversationPracticeScreen extends StatefulWidget {
  const ConversationPracticeScreen({super.key});

  @override
  State<ConversationPracticeScreen> createState() =>
      _ConversationPracticeScreenState();
}

class _ConversationPracticeScreenState extends State<ConversationPracticeScreen>
    with TickerProviderStateMixin {
  // --- Services & Controllers ---
  late final AudioRecorderService _audioRecorderService;
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _animationController;

  // --- State ---
  ChatState _state = ChatState.idle;
  final List<ChatUIMessage> _messages = [
    ChatUIMessage(
      "Hello! Let's practice a conversation. Try saying something or type below!",
      MessageRole.assistant,
    ),
  ];
  Timer? _timeoutTimer;
  final String _apiUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    _audioRecorderService = AudioRecorderService()..requestPermission();
    _initTts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        } else if (msg.role == MessageRole.assistant && history.isNotEmpty) {
          history.last["chatbot_response"] = msg.text;
        }
      }

      final request = http.Request('POST', Uri.parse('$_apiUrl/chat'))
        ..headers['Content-Type'] = 'application/json'
        ..body = json.encode({
          'message': text,
          'history': history,
          'system_prompt_override':
              'Your name is Lilly. You are a friendly English tutor helping with conversational practice.',
        });

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      _timeoutTimer?.cancel();

      if (response.statusCode == 200) {
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
          'Server Error: ${response.statusCode} - ${response.reasonPhrase}',
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
      String format = kIsWeb ? 'webm' : 'wav';
      var request =
          http.MultipartRequest('POST', Uri.parse('$_apiUrl/transcribe'))
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                recordingData.bytes,
                filename: 'recording.$format',
                contentType: MediaType('audio', format),
              ),
            );

      var response = await request.send().timeout(const Duration(seconds: 10));
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        if (data.containsKey('transcription')) {
          return data['transcription'];
        }
        _addBotMessage('Invalid response from server.', MessageRole.error);
        return null;
      } else {
        print(
          'Transcription Error: ${response.statusCode} - ${await response.stream.bytesToString()}',
        );
        _addBotMessage(
          'Transcription Server Error: ${response.statusCode}',
          MessageRole.error,
        );
        return null;
      }
    } catch (e) {
      print("Transcription failed: $e");
      _addBotMessage("Failed to transcribe audio: $e", MessageRole.error);
      return null;
    }
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
        title: const Text(
          'AI Conversation',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: surfaceColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          _buildHeader(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: surfaceColor,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'YOUR GOAL',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Practice free conversation in English with Lilly, your AI tutor.',
                    style: TextStyle(color: textColor, fontSize: 14),
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
