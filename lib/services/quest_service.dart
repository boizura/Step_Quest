import 'package:cloud_firestore/cloud_firestore.dart';

class QuestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> generateDailyQuest({
    required String uid,
    required int previousGoal,
    required bool completedYesterday,
  }) async {
    int newGoal;

    if (completedYesterday) {
      newGoal = (previousGoal * 1.10).round();
    } else {
      newGoal = (previousGoal * 0.90).round();
    }

    if (newGoal < 3000) newGoal = 3000;
    if (newGoal > 15000) newGoal = 15000;

    final today = DateTime.now();
    final questId = "${today.year}-${today.month}-${today.day}";

    await _db
        .collection('users')
        .doc(uid)
        .collection('quests')
        .doc(questId)
        .set({
      'title': 'Daily Journey',
      'description': 'Walk $newGoal steps to continue your adventure.',
      'stepRequirement': newGoal,
      'rewardXp': newGoal ~/ 100,
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'balancingRule':
          completedYesterday
              ? 'Goal increased by 10% because yesterday was completed.'
              : 'Goal decreased by 10% because yesterday was missed.',
    });
  }
}
