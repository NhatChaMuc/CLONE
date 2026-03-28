// File: lib/screens/sound_library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/sound_library_service.dart';
import 'practice_screen.dart';

const Color primaryColor = Color(0xFF0EA5E9);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color surfaceColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color subtleTextColor = Color(0xFF64748B);
const Color errorColor = Color(0xFFEF4444);

class SoundLibraryScreen extends StatefulWidget {
  const SoundLibraryScreen({super.key});

  @override
  State<SoundLibraryScreen> createState() => _SoundLibraryScreenState();
}

class _SoundLibraryScreenState extends State<SoundLibraryScreen> {
  List<String> _difficultWords = [];
  Future<void>? _loadWordsFuture;

  final FlutterTts _flutterTts = FlutterTts();
  String? _speakingWord;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadWordsFuture = _loadWords();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingWord = null);
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() => _speakingWord = null);
        _showErrorSnackbar("Text-to-speech failed.");
      }
    });
  }

  Future<void> _loadWords() async {
    try {
      final words = await SoundLibraryService.getDifficultWords();
      if (mounted) {
        setState(() {
          _difficultWords = words;
        });
      }
    } catch (e) {
      throw Exception('Failed to load words: $e');
    }
  }

  Future<void> _speak(String word) async {
    setState(() => _speakingWord = word);
    await _flutterTts.speak(word);
  }

  void _practiceWord(String word) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeScreen(initialSentence: word),
      ),
    );
  }

  Future<void> _removeWord(int index) async {
    final wordToRemove = _difficultWords[index];

    setState(() {
      _difficultWords.removeAt(index);
    });

    try {
      await SoundLibraryService.removeDifficultWord(wordToRemove);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "$wordToRemove"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _undoRemove(index, wordToRemove),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _difficultWords.insert(index, wordToRemove);
      });
      _showErrorSnackbar('Could not remove word. Please try again.');
    }
  }

  Future<void> _undoRemove(int index, String word) async {
    setState(() {
      _difficultWords.insert(index, word);
    });
    await SoundLibraryService.addDifficultWord(word);
  }

  Future<void> _clearLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Clear Library?"),
        content: const Text(
          "This will remove all saved words. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear", style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SoundLibraryService.clearLibrary();
      setState(() => _difficultWords = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sound library has been cleared.")),
        );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Sound Library',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: surfaceColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: textColor),
        actions: [
          if (_difficultWords.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: subtleTextColor,
              ),
              onPressed: _clearLibrary,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loadWordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: () {
                setState(() {
                  _loadWordsFuture = _loadWords();
                });
              },
            );
          }
          if (_difficultWords.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: _difficultWords.length,
            itemBuilder: (context, index) {
              final word = _difficultWords[index];
              return Dismissible(
                key: ValueKey(word + index.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _removeWord(index),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: errorColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: _WordCard(
                  word: word,
                  isSpeaking: _speakingWord == word,
                  onSpeak: () => _speak(word),
                  onPractice: () => _practiceWord(word),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Failed to Load Words',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(fontSize: 16, color: subtleTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Your Sound Library is Empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Words you mispronounce during practice will be automatically added here for review.',
              style: TextStyle(fontSize: 16, color: subtleTextColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final String word;
  final bool isSpeaking;
  final VoidCallback onSpeak;
  final VoidCallback onPractice;

  const _WordCard({
    required this.word,
    required this.isSpeaking,
    required this.onSpeak,
    required this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                word,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(
              width: 90,
              child: isSpeaking
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: onSpeak,
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.volume_up_outlined, size: 20),
                          SizedBox(width: 4),
                          Text('Listen'),
                        ],
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onPractice,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.fitness_center_outlined, size: 18),
                  SizedBox(width: 4),
                  Text('Practice'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
