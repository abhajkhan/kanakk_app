import 'dart:async';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // State variables to control the animation
  bool _isTitleVisible = false;
  bool _isButtonVisible = false;

  @override
  void initState() {
    super.initState();

    // Start animations after a short delay when the screen loads
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isTitleVisible = true);
      }
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isButtonVisible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              style: _isTitleVisible
                  ? Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: Colors.white,
                letterSpacing: 2.0,
              )
                  : Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: Colors.transparent,
                letterSpacing: 10.0,
              ),
              child: const Text('Kanakk App'),
            ),
            const SizedBox(height: 40),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeIn,
              opacity: _isButtonVisible ? 1.0 : 0.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  // Navigate to Login Screen later
                },
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}