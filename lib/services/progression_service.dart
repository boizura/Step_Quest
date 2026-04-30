import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addXp({
    required String uid,
    required int xpEarned,
  }) async {
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      int currentXp = data['xp'] ?? 0;
      int currentLevel = data['level'] ?? 1;

      int newXp = currentXp + xpEarned;
      int xpNeeded = currentLevel * 100;

      while (newXp >= xpNeeded) {
        newXp -= xpNeeded;
        currentLevel++;
        xpNeeded = currentLevel * 100;
      }

      transaction.update(userRef, {
        'xp': newXp,
        'level': currentLevel,
      });
    });
  }
}
