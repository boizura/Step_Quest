import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateDailySteps({
    required String uid,
    required int steps,
  }) async {
    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month}-${today.day}";

    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('dailyActivity')
        .doc(dateKey);

    await docRef.set({
      'date': dateKey,
      'steps': steps,
      'goal': 5000,
      'completed': steps >= 5000,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('users').doc(uid).set({
      'totalSteps': FieldValue.increment(steps),
    }, SetOptions(merge: true));
  }
}
