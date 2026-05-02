import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import '../services/fcm_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService().initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('StepQuest Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading dashboard.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser!;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({
                        'email': user.email ?? '',
                        'characterName': 'Hero',
                        'level': 1,
                        'xp': 0,
                        'health': 100,
                        'stamina': 100,
                        'streakCount': 0,
                        'totalSteps': 0,
                        'dailyGoal': 5000,
                        'currentQuestId': null,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                },
                child: const Text('Create Character Profile'),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final characterName = data['characterName'] ?? 'Hero';
          final level = data['level'] ?? 1;
          final xp = data['xp'] ?? 0;
          final health = data['health'] ?? 100;
          final stamina = data['stamina'] ?? 100;
          final streakCount = data['streakCount'] ?? 0;
          final totalSteps = data['totalSteps'] ?? 0;

          final dailyGoal = data['dailyGoal'] ?? 5000;
          final progress = (totalSteps / dailyGoal).clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $characterName!',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Level $level Hero',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today’s Quest',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text('Walk $dailyGoal steps to continue your journey.'),

                        const SizedBox(height: 16),

                        LinearProgressIndicator(value: progress, minHeight: 12),

                        const SizedBox(height: 8),

                        Text('$totalSteps / $dailyGoal steps'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'XP',
                        value: '$xp',
                        icon: Icons.bolt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Streak',
                        value: '$streakCount days',
                        icon: Icons.local_fire_department,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Health',
                        value: '$health',
                        icon: Icons.favorite,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Stamina',
                        value: '$stamina',
                        icon: Icons.directions_run,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Adventure Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                _ActionButton(
                  title: 'View Quest',
                  icon: Icons.map,
                  onTap: () {
                    Navigator.pushNamed(context, '/quest');
                  },
                ),

                _ActionButton(
                  title: 'Enter Battle',
                  icon: Icons.shield,
                  onTap: () {
                    Navigator.pushNamed(context, '/battle');
                  },
                ),

                _ActionButton(
                  title: 'Character Progression',
                  icon: Icons.person,
                  onTap: () {
                    Navigator.pushNamed(context, '/character');
                  },
                ),

                _ActionButton(
                  title: 'Guild Challenges',
                  icon: Icons.groups,
                  onTap: () {
                    Navigator.pushNamed(context, '/guild');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
