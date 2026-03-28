import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application-wide state providers
class AppState {
  final bool isDarkMode;
  final String? selectedLanguage;

  const AppState({this.isDarkMode = false, this.selectedLanguage = 'en'});

  AppState copyWith({bool? isDarkMode, String? selectedLanguage}) {
    return AppState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }
}

/// Global app state notifier
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  return AppStateNotifier();
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  /// Toggle dark mode
  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  /// Set language
  void setLanguage(String language) {
    state = state.copyWith(selectedLanguage: language);
  }

  /// Reset to default state
  void reset() {
    state = const AppState();
  }
}

/// Loading state provider for general purpose
final loadingProvider = StateProvider<bool>((ref) => false);

/// Error message provider for displaying errors
final errorMessageProvider = StateProvider<String?>((ref) => null);

/// Success message provider for displaying success
final successMessageProvider = StateProvider<String?>((ref) => null);
