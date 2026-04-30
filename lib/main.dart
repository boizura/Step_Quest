import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:step_quiz/screens/auth_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const StepQuestApp());
}

class StepQuestApp extends StatelessWidget {
  const StepQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StepQuest',
      debugShowCheckedModeBanner: false,
      home: AuthScreen(),
    );
  }
}

