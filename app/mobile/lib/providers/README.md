# State Management & Providers Documentation

## Overview
This project uses **Riverpod** for state management. Riverpod provides a compile-safe, testable state management solution with excellent performance.

## Architecture Layers

### 1. **Models** (`lib/models/`)
Data classes with serialization support
- Type-safe data structures
- Serialization/Deserialization methods

### 2. **Repositories** (`lib/repositories/`)
Business logic layer for data operations
- Handle Firestore operations
- Error handling and mapping
- Single source of truth

### 3. **Providers** (`lib/providers/`)
State management and data access layer
- Manages async data loading
- Caches data efficiently
- Exposes repositories to UI

### 4. **UI Widgets**
Consumer widgets that read from providers
- Never directly access Firestore
- Always through providers for consistency

## Provider Types

### StateProvider
Simple mutable state
```dart
final countProvider = StateProvider<int>((ref) => 0);

// Usage in widget
Consumer(builder: (context, ref, child) {
  final count = ref.watch(countProvider);
  return Text('Count: $count');
});
```

### FutureProvider
Handles async data with loading/error states
```dart
final topicsProvider = FutureProvider<List<TopicModel>>((ref) async {
  // fetch topics
});

// Usage
Consumer(builder: (context, ref, child) {
  final topics = ref.watch(topicsProvider);
  return topics.when(
    data: (topics) => ListView(...),
    loading: () => CircularProgressIndicator(),
    error: (err, stack) => ErrorWidget(),
  );
});
```

### StateNotifierProvider
Complex state with methods
```dart
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref);
});

// Usage
Consumer(builder: (context, ref, child) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (user) => user != null ? HomeScreen() : LoginScreen(),
    loading: () => LoadingScreen(),
    error: (err, stack) => ErrorScreen(),
  );
});
```

## Available Providers

### Auth Providers (`auth_provider.dart`)

#### `firebaseAuthProvider`
Provides Firebase Auth instance
```dart
final auth = ref.watch(firebaseAuthProvider);
```

#### `currentUserProvider`
Stream of current authenticated user
```dart
final user = ref.watch(currentUserProvider);
```

#### `authNotifierProvider`
State notifier for auth operations
```dart
final authNotifier = ref.read(authNotifierProvider.notifier);
await authNotifier.signUp(email, password, fullName);
```

### Firestore Providers (`firestore_provider.dart`)

#### `userDataProvider`
Fetch user data from Firestore
```dart
final userData = ref.watch(userDataProvider(userId));
```

#### `userPracticeHistoryProvider`
Get user's practice history
```dart
final history = ref.watch(userPracticeHistoryProvider(userId));
```

#### `userStatsProvider`
Calculate user statistics
```dart
final stats = ref.watch(userStatsProvider(userId));
```

#### `userProfileNotifierProvider`
Update user profile or record practices
```dart
final notifier = ref.read(userProfileNotifierProvider.notifier);
await notifier.updateProfile(uid: uid, fullName: 'New Name');
```

### API Providers (`api_provider.dart`)

#### `topicsProvider`
Fetch all topics from backend
```dart
final topics = ref.watch(topicsProvider);
```

#### `tongueTwistersProvider`
Fetch tongue twisters
```dart
final twisters = ref.watch(tongueTwistersProvider);
```

#### `transcriptionNotifierProvider`
Submit audio for transcription
```dart
final notifier = ref.read(transcriptionNotifierProvider.notifier);
await notifier.transcribeAudio(audioPath: path, sentence: sentence);
```

### App State Providers (`app_state_provider.dart`)

#### `appStateProvider`
Global app settings
```dart
final appState = ref.watch(appStateProvider);
final isDark = appState.isDarkMode;

// Toggle dark mode
ref.read(appStateProvider.notifier).toggleDarkMode();
```

## Usage Examples

### Example 1: Login Screen
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/providers.dart';

class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          return HomeScreen();
        }
        return _LoginForm();
      },
      loading: () => LoadingScreen(),
      error: (error, stack) => ErrorScreen(error: error),
    );
  }
}

class _LoginForm extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    return ElevatedButton(
      onPressed: () async {
        try {
          await authNotifier.signIn(
            email: 'user@example.com',
            password: 'password123',
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      },
      child: Text('Sign In'),
    );
  }
}
```

### Example 2: Home Screen with User Data
```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final appState = ref.watch(appStateProvider);
    
    return currentUser.when(
      data: (user) {
        if (user == null) {
          return LoginScreen();
        }
        
        final userData = ref.watch(userDataProvider(user.uid));
        
        return userData.when(
          data: (userModel) => Scaffold(
            body: Column(
              children: [
                Text('Welcome, ${userModel?.fullName}'),
                Consumer(builder: (context, ref, _) {
                  final stats = ref.watch(userStatsProvider(user.uid));
                  
                  return stats.when(
                    data: (statsData) => StatsWidget(stats: statsData),
                    loading: () => CircularProgressIndicator(),
                    error: (err, _) => ErrorWidget(),
                  );
                }),
              ],
            ),
          ),
          loading: () => LoadingScreen(),
          error: (err, _) => ErrorScreen(),
        );
      },
      loading: () => LoadingScreen(),
      error: (_, __) => LoginScreen(),
    );
  }
}
```

### Example 3: Recording Practice
```dart
class PracticeResultScreen extends ConsumerWidget {
  final String sentence;
  final String transcribedText;
  final double accuracy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfileNotifier = ref.read(userProfileNotifierProvider.notifier);
    
    return ElevatedButton(
      onPressed: () async {
        final user = currentUser.value;
        if (user == null) return;
        
        final practice = PracticeModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.uid,
          topicId: topicId,
          practiceType: 'transcribe',
          sentence: sentence,
          transcribedText: transcribedText,
          accuracy: accuracy,
          pointsEarned: (accuracy * 100).toInt(),
          createdAt: DateTime.now(),
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        
        await userProfileNotifier.recordPractice(
          userId: user.uid,
          practice: practice,
        );
      },
      child: Text('Save Result'),
    );
  }
}
```

## Repositories

### UserRepository
```dart
final repo = UserRepository();

// Sign up
await repo.signUp(
  email: 'user@example.com',
  password: 'password123',
  fullName: 'John Doe',
);

// Sign in
final user = await repo.signIn(
  email: 'user@example.com',
  password: 'password123',
);

// Get user
final userData = await repo.getUserById(uid);

// Update profile
await repo.updateUserProfile(
  uid: uid,
  fullName: 'New Name',
);
```

### PracticeRepository
```dart
final repo = PracticeRepository();

// Record practice
await repo.recordPractice(practiceModel);

// Get history
final history = await repo.getPracticeHistory(userId: uid);

// Get statistics
final stats = await repo.getUserStatistics(uid);
```

## Error Handling

All providers throw custom exceptions:
```dart
try {
  final data = await ref.read(topicsProvider.future);
} on NetworkException catch (e) {
  print('Network error: ${e.statusCode}');
} on AuthException catch (e) {
  print('Auth error: ${e.code}');
} on DataException catch (e) {
  print('Data error: ${e.message}');
} on AppException catch (e) {
  print('Error: ${e.message}');
}
```

## Best Practices

1. **Always use Consumer/ConsumerWidget** - Never access providers outside of widgets
2. **Use `.watch()`** - For reactive updates in build
3. **Use `.read()`** - For reading state in callbacks/notifiers
4. **Use FutureProvider.family** - For parameterized async data
5. **Handle AsyncValue** - Always use `.when()` for loading/error states
6. **Keep notifiers simple** - Business logic in repositories
7. **Cache appropriately** - Riverpod caches by default
8. **Invalidate when needed** - Use `ref.invalidate()` to refresh data

## Importing

```dart
// Import all providers
import 'package:mobile/providers/providers.dart';

// Import specific
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/repositories/repositories.dart';
```

## Future Improvements

- [ ] Add provider testing
- [ ] Implement RefreshIndicator integration
- [ ] Add logging for debugging
- [ ] Implement offline persistence with Hive
- [ ] Add analytics integration
