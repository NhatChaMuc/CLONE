import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

const Color primaryColor = Color(0xFF0EA5E9);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color surfaceColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color subtleTextColor = Color(0xFF64748B);

class TranscribeScreen extends StatefulWidget {
  const TranscribeScreen({super.key});

  @override
  State<TranscribeScreen> createState() => _TranscribeScreenState();
}

class _TranscribeScreenState extends State<TranscribeScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _resultData;
  final String _apiUrl = 'http://127.0.0.1:8000';

  Future<void> _pickAndTranscribeFile() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _resultData = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        final file = result.files.single;

        if (kIsWeb) {
          if (file.bytes != null) {
            await _transcribeFileBytes(file.bytes!, file.name);
          } else {
            _showErrorInResult("Error: File bytes are unavailable on web.");
          }
        } else {
          if (file.path != null) {
            await _transcribeFilePath(file.path!);
          } else {
            _showErrorInResult("Error: File path is unavailable.");
          }
        }
      } else {
        if (mounted) setState(() => _resultData = null);
      }
    } catch (e) {
      _showErrorInResult("Error picking file: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _transcribeFileBytes(Uint8List bytes, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiUrl/transcribe'),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() => _resultData = jsonDecode(responseData));
      } else {
        _showErrorInResult(
          "Server error: ${response.statusCode} - ${jsonDecode(responseData)['detail']}",
        );
      }
    } catch (e) {
      _showErrorInResult("Connection error: $e");
    }
  }

  Future<void> _transcribeFilePath(String filePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiUrl/transcribe'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() => _resultData = jsonDecode(responseData));
      } else {
        _showErrorInResult(
          "Server error: ${response.statusCode} - ${jsonDecode(responseData)['detail']}",
        );
      }
    } catch (e) {
      _showErrorInResult("Connection error: $e");
    }
  }

  void _showErrorInResult(String message) {
    if (mounted) {
      setState(() {
        _resultData = {"error": "❌ $message"};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Transcribe Audio',
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
            _buildUploadCard(),
            const SizedBox(height: 32),
            _buildResultArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _pickAndTranscribeFile,
      child: Card(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.upload_file,
                  size: 48,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tap to Upload Audio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Supports MP3, WAV, FLAC, M4A',
                style: TextStyle(fontSize: 14, color: subtleTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Transcription Result",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.all(20.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _resultData == null
                ? _buildInitialResultView()
                : _buildResultContent(_resultData!),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialResultView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notes, size: 40, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Your transcription will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: subtleTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(Map<String, dynamic> data) {
    if (data.containsKey("error")) {
      return Center(
        child: Text(
          data["error"],
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }
    final transcription = data['transcription'] ?? 'N/A';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Transcription:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: subtleTextColor, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: transcription));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard!')),
                );
              },
              tooltip: 'Copy text',
            ),
          ],
        ),
        const SizedBox(height: 8),
        SelectableText(
          transcription,
          style: const TextStyle(fontSize: 18, color: textColor, height: 1.5),
        ),
      ],
    );
  }
}
