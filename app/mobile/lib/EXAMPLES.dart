import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/models.dart';
import 'providers/providers.dart';

/// EXAMPLE 1: Simple Auth Flow with Riverpod
///
/// This example shows how to use Riverpod providers for authentication
class AuthExampleScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth notifier state
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (user) {
        // User is logged in
        if (user != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Welcome')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome, ${user.fullName}!'),
                  ElevatedButton(
                    onPressed: () {
                      // Read notifier to perform action
                      ref.read(authNotifierProvider.notifier).signOut();
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }
        // User is not logged in, show login form
        return const LoginFormExample();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}

/// EXAMPLE 2: Login Form with Error Handling
class LoginFormExample extends ConsumerStatefulWidget {
  const LoginFormExample();

  @override
  ConsumerState<LoginFormExample> createState() => _LoginFormExampleState();
}

class _LoginFormExampleState extends ConsumerState<LoginFormExample> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch loading state
    final isLoading = ref.watch(
      authNotifierProvider.select((state) => state.isLoading),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      try {
                        // Read the notifier and call signIn
                        await ref
                            .read(authNotifierProvider.notifier)
                            .signIn(
                              email: _emailController.text,
                              password: _passwordController.text,
                            );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

/// EXAMPLE 3: Loading User Data and Stats
class UserStatsExample extends ConsumerWidget {
  final String userId;

  const UserStatsExample({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load user data
    final userData = ref.watch(userDataProvider(userId));

    // Load user statistics
    final userStats = ref.watch(userStatsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('My Stats')),
      body: Column(
        children: [
          // User Data Section
          userData.when(
            data: (user) => user != null
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${user.fullName}'),
                          Text('Email: ${user.email}'),
                          Text('Member since: ${user.createdAt}'),
                        ],
                      ),
                    ),
                  )
                : const Text('User not found'),
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => Text('Error: $err'),
          ),
          const SizedBox(height: 16),
          // Statistics Section
          userStats.when(
            data: (stats) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Points: ${stats['totalPoints']}'),
                    Text(
                      'Average Accuracy: ${((stats['averageAccuracy'] as num) * 100).toStringAsFixed(1)}%',
                    ),
                    Text('Completed Topics: ${stats['completedTopics']}'),
                  ],
                ),
              ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }
}

/// EXAMPLE 4: Recording Practice with Riverpod
class RecordPracticeExample extends ConsumerWidget {
  final String topicId;
  final String sentence;
  final String transcribedText;
  final double accuracy;

  const RecordPracticeExample({
    required this.topicId,
    required this.sentence,
    required this.transcribedText,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please login first'));
        }

        return ElevatedButton(
          onPressed: () async {
            try {
              // Create practice model
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

              // Record practice using notifier
              await ref
                  .read(userProfileNotifierProvider.notifier)
                  .recordPractice(userId: user.uid, practice: practice);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Practice saved!')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          child: const Text('Save Practice'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Center(child: Text('Error loading user')),
    );
  }
}

/// EXAMPLE 5: Fetching Topics from API
class TopicsListExample extends ConsumerWidget {
  const TopicsListExample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch topics provider
    final topics = ref.watch(topicsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Topics')),
      body: topics.when(
        data: (topicsList) => ListView.builder(
          itemCount: topicsList.length,
          itemBuilder: (context, index) {
            final topic = topicsList[index];
            return ListTile(
              title: Text(topic.title),
              subtitle: Text(topic.description),
              trailing: Text('Level ${topic.difficulty}'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading topics: $error')),
      ),
    );
  }
}

/// EXAMPLE 6: Using App State (Dark Mode)
class AppSettingsExample extends ConsumerWidget {
  const AppSettingsExample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch app state
    final appState = ref.watch(appStateProvider);
    final isDarkMode = appState.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (_) {
              // Toggle dark mode
              ref.read(appStateProvider.notifier).toggleDarkMode();
            },
          ),
          ListTile(
            title: const Text('Current Language'),
            subtitle: Text(appState.selectedLanguage ?? 'English'),
            onTap: () {
              // Set language
              ref
                  .read(appStateProvider.notifier)
                  .setLanguage('en'); // or other language code
            },
          ),
        ],
      ),
    );
  }
}

/// EXAMPLE 7: Main App with Riverpod Setup
void mainExample() {
  runApp(
    // Wrap with ProviderScope to enable Riverpod
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch app state for theme
    final appState = ref.watch(appStateProvider);

    // Watch auth for routing
    final authState = ref.watch(authNotifierProvider);

    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: authState.when(
        data: (user) => user != null
            ? const UserStatsExample(userId: 'user123')
            : const LoginFormExample(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const LoginFormExample(),
      ),
    );
  }
}
