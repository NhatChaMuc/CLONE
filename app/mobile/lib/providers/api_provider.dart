import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/models.dart';

/// Base URL for backend API
const String _baseUrl = 'http://10.0.2.2:8000';

/// HTTP client provider
final httpClientProvider = Provider((ref) {
  return http.Client();
});

/// Provider for fetching all topics
final topicsProvider = FutureProvider<List<TopicModel>>((ref) async {
  final client = ref.watch(httpClientProvider);

  try {
    final response = await client
        .get(Uri.parse('$_baseUrl/topics'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw NetworkException(
        message: 'Failed to load topics',
        statusCode: response.statusCode,
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final topicsData = (decoded['topics'] as List?) ?? [];

    return [
      for (final topic in topicsData)
        TopicModel.fromJson(topic as Map<String, dynamic>),
    ];
  } catch (e) {
    throw NetworkException(
      message: 'Failed to load topics: $e',
      originalException: e,
    );
  }
});

/// Provider for fetching a specific topic
final topicProvider = FutureProvider.family<TopicModel, String>((
  ref,
  topicId,
) async {
  final client = ref.watch(httpClientProvider);

  try {
    final response = await client
        .get(Uri.parse('$_baseUrl/topics/$topicId'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw NetworkException(
        message: 'Failed to load topic',
        statusCode: response.statusCode,
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    return TopicModel.fromJson(decoded);
  } catch (e) {
    throw NetworkException(
      message: 'Failed to load topic: $e',
      originalException: e,
    );
  }
});

/// Provider for fetching tongue twisters
final tongueTwistersProvider = FutureProvider<List<TongueTwisterModel>>((
  ref,
) async {
  final client = ref.watch(httpClientProvider);

  try {
    final response = await client
        .get(Uri.parse('$_baseUrl/tongue-twisters'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw NetworkException(
        message: 'Failed to load tongue twisters',
        statusCode: response.statusCode,
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final twistersData = (decoded['twisters'] as List?) ?? [];

    return [
      for (final twister in twistersData)
        TongueTwisterModel.fromJson(twister as Map<String, dynamic>),
    ];
  } catch (e) {
    throw NetworkException(
      message: 'Failed to load tongue twisters: $e',
      originalException: e,
    );
  }
});

/// Notifier for transcription requests
final transcriptionNotifierProvider =
    StateNotifierProvider<
      TranscriptionNotifier,
      AsyncValue<TranscriptionResultModel>
    >((ref) {
      return TranscriptionNotifier(ref);
    });

class TranscriptionNotifier
    extends StateNotifier<AsyncValue<TranscriptionResultModel>> {
  final Ref ref;

  TranscriptionNotifier(this.ref)
    : super(
        const AsyncValue.data(null) as AsyncValue<TranscriptionResultModel>,
      );

  /// Submit audio for transcription
  Future<void> transcribeAudio({
    required String audioPath,
    required String sentence,
  }) async {
    state = const AsyncValue.loading();

    try {
      final client = ref.read(httpClientProvider);

      // TODO: Implement proper file upload
      // For now, this is a placeholder
      final response = await client
          .post(
            Uri.parse('$_baseUrl/transcribe'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'sentence': sentence, 'audioPath': audioPath}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw NetworkException(
          message: 'Transcription failed',
          statusCode: response.statusCode,
        );
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final result = TranscriptionResultModel.fromJson(decoded);

      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error(
        NetworkException(
          message: 'Transcription error: $e',
          originalException: e,
        ),
        StackTrace.current,
      );
    }
  }
}
