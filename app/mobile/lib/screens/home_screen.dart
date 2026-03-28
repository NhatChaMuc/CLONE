import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'about_screen.dart';
import 'conversation_practice_screen.dart';
import 'topics_screen.dart';
import 'transcribe_screen.dart';
import 'scenario_list_screen.dart';
import 'shadowing_screen.dart';
import 'sound_library_screen.dart';
import 'tongue_twister_screen.dart';

const Color primaryColor = Color(0xFF0EA5E9);
const Color secondaryColor = Color(0xFF14B8A6);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color surfaceColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color subtleTextColor = Color(0xFF64748B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _fullName;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserFullName();
  }

  // ✅ Load "full name" từ Firestore
  Future<void> _loadUserFullName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data()!.containsKey('full name')) {
        setState(() => _fullName = doc['full name']);
      } else {
        setState(() => _fullName = user.email ?? 'User');
      }
    } catch (e) {
      debugPrint('❌ Error loading full name: $e');
      setState(() => _fullName = 'User');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<FeatureCardData> learningPathFeatures = [
      FeatureCardData(
        icon: Icons.record_voice_over,
        title: 'Practice Sentences',
        description: 'Improve pronunciation with various topics.',
        color: secondaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TopicsScreen()),
        ),
      ),
      FeatureCardData(
        icon: Icons.coffee_outlined,
        title: 'Real-world Scenarios',
        description: 'Practice conversations like ordering coffee.',
        color: Colors.brown,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ScenarioListScreen()),
        ),
      ),
    ];

    final List<FeatureCardData> workoutFeatures = [
      FeatureCardData(
        icon: Icons.speaker_phone,
        title: 'Shadowing Practice',
        description: 'Listen and repeat along with native audio.',
        color: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ShadowingScreen(
              sentence: "She sells seashells by the seashore.",
              audioUrl:
                  "https://www.learning-english-online.net/wp-content/uploads/2021/01/She-sells-seashells-by-the-seashore.mp3",
            ),
          ),
        ),
      ),
      FeatureCardData(
        icon: Icons.fast_forward_rounded,
        title: 'Tongue Twisters',
        description: 'Challenge yourself with tricky phrases.',
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TongueTwisterScreen()),
        ),
      ),
    ];

    final List<FeatureCardData> toolFeatures = [
      FeatureCardData(
        icon: Icons.school_outlined,
        title: 'My Sound Library',
        description: 'Review words you need to work on.',
        color: Colors.redAccent,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SoundLibraryScreen()),
        ),
      ),
      FeatureCardData(
        icon: Icons.chat_bubble_outline,
        title: 'AI Conversation',
        description: 'Have a free-form chat with our AI tutor.',
        color: primaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConversationPracticeScreen()),
        ),
      ),
      FeatureCardData(
        icon: Icons.multitrack_audio,
        title: 'Transcribe Audio',
        description: 'Listen and check your comprehension.',
        color: Colors.blueGrey,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TranscribeScreen()),
        ),
      ),
      FeatureCardData(
        icon: Icons.info_outline,
        title: 'About This App',
        description: 'Learn more about the application.',
        color: Colors.indigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Bella',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: subtleTextColor),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Text('A', style: TextStyle(color: textColor)),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fullName == null
                        ? 'Welcome back!'
                        : 'Welcome back, $_fullName!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDailyGoalCard(context),
                ],
              ),
            ),
          ),
          _buildSectionHeader('Start Your Lesson'),
          _buildFeatureGrid(learningPathFeatures),
          _buildSectionHeader('Daily Workout'),
          _buildFeatureGrid(workoutFeatures),
          _buildSectionHeader('Tools & Resources'),
          _buildToolList(toolFeatures),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(BuildContext context) {
    const dailyGoalMinutes = 30;
    const timeTodayMinutes = 12;
    final progress = timeTodayMinutes / dailyGoalMinutes;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Goal',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You're ${(progress * 100).toStringAsFixed(0)}% there!",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Text(
              'Keep up the great work.',
              style: TextStyle(fontSize: 14, color: subtleTextColor),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TopicsScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Continue Today's Lesson",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(List<FeatureCardData> features) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildFeatureCard(features[index]),
          childCount: features.length,
        ),
      ),
    );
  }

  Widget _buildToolList(List<FeatureCardData> features) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildToolListItem(features[index]),
          childCount: features.length,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(FeatureCardData data) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        color: surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: data.color.withOpacity(0.1),
                child: Icon(data.icon, color: data.color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: subtleTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolListItem(FeatureCardData data) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      color: surfaceColor,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: data.color.withOpacity(0.1),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    Text(
                      data.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: subtleTextColor,
                      ),
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

class FeatureCardData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  FeatureCardData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });
}
