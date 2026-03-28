import 'package:shared_preferences/shared_preferences.dart';

class SoundLibraryService {
  static const _key = 'sound_library_words';

  static Future<List<String>> getDifficultWords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addDifficultWord(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanedWord = word.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    if (cleanedWord.isEmpty) return;

    List<String> words = await getDifficultWords();
    if (!words.contains(cleanedWord)) {
      words.add(cleanedWord);
      await prefs.setStringList(_key, words);
    }
  }

  static Future<void> removeDifficultWord(String word) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> words = await getDifficultWords();
    words.remove(word.toLowerCase());
    await prefs.setStringList(_key, words);
  }

  static Future<void> clearLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
