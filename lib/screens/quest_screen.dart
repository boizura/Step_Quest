import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  String getTodayId() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> createDailyQuest(String uid) async {
    final todayId = getTodayId();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('quests')
        .doc(todayId)
        .set({
      'title': 'Daily Journey',
      'description': 'Walk 5,000 steps to continue your adventure.',
      'stepRequirement': 5000,
      'currentSteps': 0,
      'rewardXp': 50,
      'completed': false,
      'balancingRule': 'Starting goal set to 5,000 steps for new players.',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addDemoSteps(String uid, Map<String, dynamic> quest) async {
    final todayId = getTodayId();
    final questRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('quests')
        .doc(todayId);

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final currentSteps = quest['currentSteps'] ?? 0;
    final stepRequirement = quest['stepRequirement'] ?? 5000;
    final rewardXp = quest['rewardXp'] ?? 50;

    final newSteps = currentSteps + 1000;
    final completed = newSteps >= stepRequirement;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.update(questRef, {
        'currentSteps': newSteps,
        'completed': completed,
      });

      if (completed && quest['completed'] == false) {
        transaction.update(userRef, {
          'xp': FieldValue.increment(rewardXp),
          'totalSteps': FieldValue.increment(1000),
        });
      } else {
        transaction.update(userRef, {
          'totalSteps': FieldValue.increment(1000),
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final todayId = getTodayId();

    final questRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('quests')
        .doc(todayId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quest'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: questRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading quest.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: () => createDailyQuest(uid),
                icon: const Icon(Icons.add),
                label: const Text('Create Today’s Quest'),
              ),
            );
          }

          final quest = snapshot.data!.data() as Map<String, dynamic>;

          final title = quest['title'] ?? 'Daily Quest';
          final description = quest['description'] ?? '';
          final stepRequirement = quest['stepRequirement'] ?? 5000;
          final currentSteps = quest['currentSteps'] ?? 0;
          final rewardXp = quest['rewardXp'] ?? 0;
          final completed = quest['completed'] ?? false;
          final balancingRule = quest['balancingRule'] ?? 'No rule available.';

          final progress = (currentSteps / stepRequirement).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(description),
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 14,
                        ),
                        const SizedBox(height: 8),
                        Text('$currentSteps / $stepRequirement steps'),
                        const SizedBox(height: 16),
                        Text('Reward: $rewardXp XP'),
                        const SizedBox(height: 16),
                        Text(
                          completed ? 'Quest Complete!' : 'Quest In Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: completed ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.balance, color: Colors.deepPurple),
                    title: const Text('Balancing Rule'),
                    subtitle: Text(balancingRule),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: completed ? null : () => addDemoSteps(uid, quest),
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Add 1,000 Demo Steps'),
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