import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  String getEncounterId() {
    final now = DateTime.now();
    return 'encounter-${now.year}-${now.month}-${now.day}';
  }

  Future<void> createEncounter(String uid) async {
    final encounterId = getEncounterId();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('encounters')
        .doc(encounterId)
        .set({
      'enemyName': 'Forest Goblin',
      'enemyHealth': 100,
      'maxEnemyHealth': 100,
      'damageDealt': 0,
      'completed': false,
      'rewardXp': 40,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> attackWithSteps({
    required String uid,
    required Map<String, dynamic> encounter,
  }) async {
    final encounterId = getEncounterId();

    final encounterRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('encounters')
        .doc(encounterId);

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    const demoSteps = 1000;
    const damage = 10;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final encounterSnapshot = await transaction.get(encounterRef);

      if (!encounterSnapshot.exists) return;

      final data = encounterSnapshot.data() as Map<String, dynamic>;

      final currentHealth = data['enemyHealth'] ?? 100;
      final rewardXp = data['rewardXp'] ?? 40;
      final wasCompleted = data['completed'] ?? false;

      final newHealth = currentHealth - damage;
      final isCompleted = newHealth <= 0;

      transaction.update(encounterRef, {
        'enemyHealth': isCompleted ? 0 : newHealth,
        'damageDealt': FieldValue.increment(damage),
        'completed': isCompleted,
      });

      transaction.update(userRef, {
        'totalSteps': FieldValue.increment(demoSteps),
      });

      if (isCompleted && !wasCompleted) {
        transaction.update(userRef, {
          'xp': FieldValue.increment(rewardXp),
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final encounterId = getEncounterId();

    final encounterRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('encounters')
        .doc(encounterId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Encounter'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: encounterRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading battle.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: () => createEncounter(uid),
                icon: const Icon(Icons.shield),
                label: const Text('Start Encounter'),
              ),
            );
          }

          final encounter = snapshot.data!.data() as Map<String, dynamic>;

          final enemyName = encounter['enemyName'] ?? 'Enemy';
          final enemyHealth = encounter['enemyHealth'] ?? 100;
          final maxEnemyHealth = encounter['maxEnemyHealth'] ?? 100;
          final damageDealt = encounter['damageDealt'] ?? 0;
          final completed = encounter['completed'] ?? false;
          final rewardXp = encounter['rewardXp'] ?? 0;

          final healthProgress =
              (enemyHealth / maxEnemyHealth).clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cruelty_free,
                          size: 70,
                          color: Colors.deepPurple,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          enemyName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        LinearProgressIndicator(
                          value: healthProgress,
                          minHeight: 14,
                        ),

                        const SizedBox(height: 8),

                        Text('$enemyHealth / $maxEnemyHealth HP'),

                        const SizedBox(height: 16),

                        Text('Damage dealt: $damageDealt'),

                        const SizedBox(height: 8),

                        Text('Reward: $rewardXp XP'),

                        const SizedBox(height: 16),

                        Text(
                          completed ? 'Enemy Defeated!' : 'Battle In Progress',
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

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: completed
                        ? null
                        : () => attackWithSteps(
                              uid: uid,
                              encounter: encounter,
                            ),
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Attack with 1,000 Demo Steps'),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Rule: 1,000 steps = 10 damage. Defeating the enemy rewards XP.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}