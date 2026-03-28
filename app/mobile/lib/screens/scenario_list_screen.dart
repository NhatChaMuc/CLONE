// lib/screens/scenario_list_screen.dart
import 'package:flutter/material.dart';
import 'scenario_chat_screen.dart';

const Color primaryColor = Color(0xFF0EA5E9);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color surfaceColor = Colors.white;
const Color textColor = Color(0xFF1E293B);
const Color subtleTextColor = Color(0xFF64748B);

class Scenario {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String systemPrompt;
  final String goal;

  Scenario({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.systemPrompt,
    required this.goal,
  });
}

class ScenarioListScreen extends StatelessWidget {
  ScenarioListScreen({super.key});

  final List<Scenario> scenarios = [
    Scenario(
      title: 'Ordering Coffee',
      description: 'Practice ordering your favorite coffee.',
      icon: Icons.coffee_outlined,
      color: Colors.brown,
      goal: "Successfully order a large latte with oat milk.",
      systemPrompt:
          "You are a friendly barista at a coffee shop named Alex. Start by greeting the user and asking for their order. Keep your responses short and natural. The user should use phrases like 'I'd like to have...' or 'Can I get...'. If they succeed, end with 'Coming right up!'",
    ),
    Scenario(
      title: 'Job Interview',
      description: 'Practice answering common interview questions.',
      icon: Icons.work_outline,
      color: Colors.indigo,
      goal: "Answer the question 'Tell me about yourself' confidently.",
      systemPrompt:
          "You are a hiring manager named Sarah conducting a job interview for a software developer role. Start by introducing yourself and asking the user 'Tell me about yourself'. Ask common interview questions. Evaluate their responses based on clarity and confidence.",
    ),
    Scenario(
      title: 'Asking for Directions',
      description: 'Practice asking a stranger for directions.',
      icon: Icons.directions_outlined,
      color: Colors.teal,
      goal: "Find out how to get to the nearest train station.",
      systemPrompt:
          "You are a helpful local on a street corner. The user will ask you for directions. Your first response must be 'Excuse me, can I help you?'. Respond helpfully and clearly. The user should use phrases like 'Could you tell me how to get to...?' or 'Where is the nearest...?'.",
    ),
    Scenario(
      title: 'Booking a Hotel Room',
      description: 'Practice making a reservation over the phone.',
      icon: Icons.hotel_outlined,
      color: Colors.deepPurple,
      goal: "Book a double room for two nights, starting this Friday.",
      systemPrompt:
          "You are a hotel receptionist named Ben. Start the conversation with 'Thank you for calling The Grand Hotel, Ben speaking. How can I help you?'. The user needs to book a room. Guide them through the process, asking for the type of room, dates, and their name.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Real-world Scenarios',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: surfaceColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Choose a situation to practice your conversational skills with an AI tutor.',
              style: TextStyle(fontSize: 16, color: subtleTextColor),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scenarios.length,
              itemBuilder: (context, index) {
                final scenario = scenarios[index];
                return _AnimatedScenarioCard(
                  index: index,
                  scenario: scenario,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ScenarioChatScreen(scenario: scenario),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedScenarioCard extends StatefulWidget {
  final int index;
  final Scenario scenario;
  final VoidCallback onTap;

  const _AnimatedScenarioCard({
    required this.index,
    required this.scenario,
    required this.onTap,
  });

  @override
  State<_AnimatedScenarioCard> createState() => _AnimatedScenarioCardState();
}

class _AnimatedScenarioCardState extends State<_AnimatedScenarioCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: _offsetAnimation,
        child: _ScenarioCard(scenario: widget.scenario, onTap: widget.onTap),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final VoidCallback onTap;

  const _ScenarioCard({required this.scenario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(width: 6, height: 88, color: scenario.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: scenario.color.withOpacity(0.1),
                      child: Icon(
                        scenario.icon,
                        color: scenario.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scenario.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scenario.description,
                            style: const TextStyle(color: subtleTextColor),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
