import 'package:cloud_firestore/cloud_firestore.dart';

class BattleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateBattleFromSteps({
    required String uid,
    required String encounterId,
    required int steps,
  }) async {
    final damage = steps ~/ 100;

    final encounterRef = _db
        .collection('users')
        .doc(uid)
        .collection('encounters')
        .doc(encounterId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(encounterRef);

      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final currentHealth = data['enemyHealth'] ?? 100;
      final newHealth = currentHealth - damage;

      transaction.update(encounterRef, {
        'enemyHealth': newHealth <= 0 ? 0 : newHealth,
        'damageDealt': FieldValue.increment(damage),
        'completed': newHealth <= 0,
      });
    });
  }
}
