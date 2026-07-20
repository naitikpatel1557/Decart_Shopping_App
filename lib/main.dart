import 'package:flutter/material.dart';
// 1. ADD THIS IMPORT FOR FIREBASE
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

// 2. MAKE MAIN ASYNC
void main() async {
  // 3. ADD THESE TWO LINES TO INITIALIZE FIREBASE
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DECÁRT App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}