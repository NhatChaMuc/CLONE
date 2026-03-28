import 'package:flutter/material.dart';
import '../widgets/colored_transcript_view.dart';
// ignore: unused_import
import 'dart:math' as math;

const Color primaryColor = Color(0xFF0EA5E9);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color surfaceColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color subtleTextColor = Color(0xFF64748B);
const Color successColor = Color(0xFF22C55E);
const Color warningColor = Color(0xFFF97316);
const Color errorColor = Color(0xFFEF4444);

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    final String target = resultData['target'] ?? '';
    final int score = resultData['score'] ?? 0;
    final List<dynamic> matches = resultData['matches'] ?? [];

    final List<String> mistakes = matches
        .where(
          (match) =>
              match != null &&
              (match['status'] == 'wrong' || match['status'] == 'missing'),
        )
        .map((match) => match['word'] as String)
        .toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Practice Result',
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
            _buildScoreIndicator(score),
            const SizedBox(height: 24),
            _buildSentenceAnalysisCard(matches, target),
            const SizedBox(height: 24),
            _buildMistakesCard(mistakes),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Practice Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(int score) {
    final Color scoreColor = score >= 80
        ? successColor
        : (score >= 50 ? warningColor : errorColor);
    final String feedbackText = score >= 80
        ? "Excellent job! You're a natural."
        : (score >= 50
              ? "Good effort, keep practicing!"
              : "Don't give up, you'll get there!");

    return Card(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: scoreColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                  Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pronunciation Score',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              feedbackText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: subtleTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentenceAnalysisCard(List<dynamic> matches, String target) {
    return Card(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sentence Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'YOUR SPEECH:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            ColoredTranscriptView(matches: matches),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'TARGET SENTENCE:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: subtleTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              target,
              style: const TextStyle(fontSize: 18, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakesCard(List<String> mistakes) {
    return Card(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Words to Improve',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            if (mistakes.isEmpty)
              const Row(
                children: [
                  Icon(Icons.check_circle, color: successColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Perfect! No mistakes found.",
                    style: TextStyle(fontSize: 16, color: successColor),
                  ),
                ],
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: mistakes
                    .map(
                      (m) => Chip(
                        label: Text(m),
                        backgroundColor: errorColor.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                        side: const BorderSide(color: errorColor, width: 1),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
