import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Profile'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
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
            return const Center(
              child: Text('Error loading profile.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('No profile found.'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final characterName = data['characterName'] ?? 'Unknown Hero';
          final email = data['email'] ?? '';
          final level = data['level'] ?? 1;
          final xp = data['xp'] ?? 0;
          final health = data['health'] ?? 100;
          final stamina = data['stamina'] ?? 100;
          final streakCount = data['streakCount'] ?? 0;
          final totalSteps = data['totalSteps'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  characterName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  email,
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 24),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: const Text('Level'),
                    trailing: Text('$level'),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bolt, color: Colors.orange),
                    title: const Text('XP'),
                    trailing: Text('$xp'),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: const Text('Health'),
                    trailing: Text('$health'),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_run, color: Colors.green),
                    title: const Text('Stamina'),
                    trailing: Text('$stamina'),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                    title: const Text('Streak'),
                    trailing: Text('$streakCount days'),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.terrain, color: Colors.blue),
                    title: const Text('Total Steps'),
                    trailing: Text('$totalSteps'),
                  ),
                ),
              ],
              ),
            ),
          );
        },
      ),
    );
  }
}
