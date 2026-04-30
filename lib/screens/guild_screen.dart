import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuildScreen extends StatelessWidget {
  const GuildScreen({super.key});

  Future<void> createGuild(String uid) async {
    final guildRef = FirebaseFirestore.instance.collection('guilds').doc();

    await guildRef.set({
      'name': 'Dragon Walkers',
      'weeklyStepTotal': 0,
      'challengeGoal': 100000,
      'members': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await guildRef.collection('members').doc(uid).set({
      'displayName': 'Hero',
      'weeklySteps': 0,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'guildId': guildRef.id,
    });
  }

  Future<void> addGuildSteps(String guildId, String uid) async {
    final guildRef = FirebaseFirestore.instance.collection('guilds').doc(guildId);
    final memberRef = guildRef.collection('members').doc(uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.update(guildRef, {
        'weeklyStepTotal': FieldValue.increment(1000),
      });

      transaction.update(memberRef, {
        'weeklySteps': FieldValue.increment(1000),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guild Challenge'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userRef.snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return const Center(child: Text('Error loading guild.'));
          }

          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final guildId = userData['guildId'];

          if (guildId == null) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: () => createGuild(uid),
                icon: const Icon(Icons.groups),
                label: const Text('Create Demo Guild'),
              ),
            );
          }

          final guildRef =
              FirebaseFirestore.instance.collection('guilds').doc(guildId);

          return StreamBuilder<DocumentSnapshot>(
            stream: guildRef.snapshots(),
            builder: (context, guildSnapshot) {
              if (guildSnapshot.hasError) {
                return const Center(child: Text('Error loading guild data.'));
              }

              if (guildSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!guildSnapshot.hasData || !guildSnapshot.data!.exists) {
                return const Center(child: Text('Guild not found.'));
              }

              final guild = guildSnapshot.data!.data() as Map<String, dynamic>;

              final name = guild['name'] ?? 'Unnamed Guild';
              final weeklyStepTotal = guild['weeklyStepTotal'] ?? 0;
              final challengeGoal = guild['challengeGoal'] ?? 100000;

              final progress =
                  (weeklyStepTotal / challengeGoal).clamp(0.0, 1.0);

              return SingleChildScrollView(
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
                              name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Work together to reach the weekly step goal.',
                            ),
                            const SizedBox(height: 20),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 14,
                            ),
                            const SizedBox(height: 8),
                            Text('$weeklyStepTotal / $challengeGoal steps'),
                            const SizedBox(height: 16),
                            Text(
                              progress >= 1
                                  ? 'Weekly Challenge Complete!'
                                  : 'Challenge In Progress',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: progress >= 1
                                    ? Colors.green
                                    : Colors.orange,
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
                        onPressed: () => addGuildSteps(guildId, uid),
                        icon: const Icon(Icons.directions_walk),
                        label: const Text('Add 1,000 Guild Steps'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Guild Members',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: guildRef.collection('members').snapshots(),
                      builder: (context, memberSnapshot) {
                        if (!memberSnapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final members = memberSnapshot.data!.docs;

                        return Column(
                          children: members.map((doc) {
                            final member =
                                doc.data() as Map<String, dynamic>;

                            return Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.person,
                                  color: Colors.deepPurple,
                                ),
                                title: Text(member['displayName'] ?? 'Hero'),
                                trailing: Text(
                                  '${member['weeklySteps'] ?? 0} steps',
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}