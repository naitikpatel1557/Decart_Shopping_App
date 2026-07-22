import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              const Text(
                'DECÁRT',
                style: TextStyle(
                  fontSize: 38,
                  fontFamily: 'Times New Roman',
                  color: Color(0xFF0F172A),
                  letterSpacing: 6.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'ALL PRODUCTS. ONE APP.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  letterSpacing: 3.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 60.0),
                child: SizedBox(
                  width: 80,
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF312E81)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}