import 'package:cloud_firestore/cloud_firestore.dart';

class GuildService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createGuild({
    required String guildName,
    required String uid,
    required String displayName,
  }) async {
    final guildRef = _db.collection('guilds').doc();

    await guildRef.set({
      'name': guildName,
      'weeklyStepTotal': 0,
      'challengeGoal': 100000,
      'members': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await guildRef.collection('members').doc(uid).set({
      'displayName': displayName,
      'weeklySteps': 0,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addStepsToGuild({
    required String guildId,
    required String uid,
    required int steps,
  }) async {
    final guildRef = _db.collection('guilds').doc(guildId);
    final memberRef = guildRef.collection('members').doc(uid);

    await _db.runTransaction((transaction) async {
      transaction.update(guildRef, {
        'weeklyStepTotal': FieldValue.increment(steps),
      });

      transaction.update(memberRef, {
        'weeklySteps': FieldValue.increment(steps),
      });
    });
  }
}
