import 'package:flutter/material.dart';

class ColoredTranscriptView extends StatelessWidget {
  final List<dynamic> matches;

  const ColoredTranscriptView({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Text(
        'No transcription available.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black, height: 1.5),
        children: matches.map((match) {
          if (match == null || !match.containsKey('word')) {
            return const TextSpan();
          }

          final String word = match['word'];
          final String status = match['status'];
          Color color;

          switch (status) {
            case 'correct':
              color = Colors.green.shade700;
              break;
            case 'wrong':
              color = Colors.red.shade700;
              break;
            case 'missing':
              color = Colors.orange.shade700;
              break;
            default:
              color = Colors.black;
          }

          return TextSpan(
            text: '$word ',
            style: TextStyle(
              color: color,
              fontWeight: status != 'correct'
                  ? FontWeight.bold
                  : FontWeight.normal,
              decoration: status == 'missing'
                  ? TextDecoration.underline
                  : TextDecoration.none,
              fontStyle: status == 'missing'
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          );
        }).toList(),
      ),
    );
  }
}
