import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  Future<void> trainCharacter(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() as Map<String, dynamic>;

      int xp = data['xp'] ?? 0;
      int level = data['level'] ?? 1;

      xp += 25;

      if (xp >= level * 100) {
        xp -= level * 100;
        level += 1;
      }

      transaction.update(userRef, {
        'xp': xp,
        'level': level,
        'health': FieldValue.increment(5),
        'stamina': FieldValue.increment(5),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Character'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading character.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final name = data['characterName'] ?? 'Hero';
          final level = data['level'] ?? 1;
          final xp = data['xp'] ?? 0;
          final health = data['health'] ?? 100;
          final stamina = data['stamina'] ?? 100;
          final streak = data['streakCount'] ?? 0;
          final totalSteps = data['totalSteps'] ?? 0;

          final xpNeeded = level * 100;
          final xpProgress = (xp / xpNeeded).clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.person, size: 70, color: Colors.white),
                ),

                const SizedBox(height: 16),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  'Level $level Adventurer',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'XP Progress',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: xpProgress,
                          minHeight: 12,
                        ),
                        const SizedBox(height: 8),
                        Text('$xp / $xpNeeded XP'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _StatTile(
                  icon: Icons.favorite,
                  title: 'Health',
                  value: '$health',
                ),
                _StatTile(
                  icon: Icons.directions_run,
                  title: 'Stamina',
                  value: '$stamina',
                ),
                _StatTile(
                  icon: Icons.local_fire_department,
                  title: 'Streak',
                  value: '$streak days',
                ),
                _StatTile(
                  icon: Icons.terrain,
                  title: 'Total Steps',
                  value: '$totalSteps',
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => trainCharacter(uid),
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('Demo Train Character +25 XP'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}