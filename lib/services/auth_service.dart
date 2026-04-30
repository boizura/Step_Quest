import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signUp({
    required String email,
    required String password,
    required String characterName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'email': email,
        'characterName': characterName,
        'level': 1,
        'xp': 0,
        'health': 100,
        'stamina': 100,
        'streakCount': 0,
        'totalSteps': 0,
        'currentQuestId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return credential.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
