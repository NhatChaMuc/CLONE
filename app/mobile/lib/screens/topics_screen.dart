import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'practice_topic_screen.dart';

const Color primaryColor = Color(0xFF0EA5E9);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color surfaceColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color subtleTextColor = Color(0xFF64748B);

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  List<dynamic> _topics = [];
  bool _isLoading = true;
  String? _error;

  String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    if (_topics.isEmpty) {
      setState(() => _isLoading = true);
    }
    setState(() => _error = null);

    try {
      final uri = Uri.parse('$_baseUrl/topics');
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      print('🔎 [DEBUG] GET /topics → ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final topics = (decoded['topics'] ?? []) as List;

        if (mounted) {
          setState(() {
            _topics = topics;
          });
        }

        // ✅ Nếu không có dữ liệu → hiển thị fallback để test
        if (topics.isEmpty) {
          print('⚠️ Topics list empty, showing fallback.');
          setState(() {
            _topics = [
              {
                "title": "Sample Topic",
                "sentences": ["Hello world!", "This is a test sentence."],
              },
            ];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load topics (Status ${response.statusCode})';
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching topics: $e');
      if (mounted) {
        setState(() {
          _error = 'Error fetching topics: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Practice Topics',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: surfaceColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTopics,
        color: primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _topics.isEmpty) {
      return _buildLoadingState();
    }

    if (_error != null && _topics.isEmpty) {
      return _buildErrorState();
    }

    if (_topics.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTopicList();
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5,
      itemBuilder: (context, index) => const _TopicCardSkeleton(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Topics',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Please check your server connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: subtleTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchTopics,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No topics found.',
            style: TextStyle(fontSize: 18, color: subtleTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final topic = _topics[index];
        final title = topic['title'] ?? 'Untitled Topic';
        final sentences = List<String>.from(topic['sentences'] ?? []);

        return _TopicCard(
          title: title,
          sentenceCount: sentences.length,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopicPracticeScreen(
                  topicTitle: title,
                  sentences: sentences,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String title;
  final int sentenceCount;
  final VoidCallback onTap;

  const _TopicCard({
    required this.title,
    required this.sentenceCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: const Icon(Icons.list_alt, color: primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sentenceCount sentences',
                      style: const TextStyle(color: subtleTextColor),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicCardSkeleton extends StatelessWidget {
  const _TopicCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(radius: 24, backgroundColor: Colors.grey[200]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.grey[200],
                  ),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 14, color: Colors.grey[200]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
