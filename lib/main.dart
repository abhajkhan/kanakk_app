import 'package:flutter/material.dart';
import 'dart:async'; // Import for using Timer

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hides the debug banner
      title: 'Kanakk App',
      theme: ThemeData(
        // Let's use a dark theme for a modern feel.
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white70),
        ),
      ),
      home: const WelcomeScreen(), // We'll create this new screen
    );
  }
}

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
            // This widget animates its child's style implicitly.
            AnimatedDefaultTextStyle(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              // Change style based on the _isTitleVisible state
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
            // This widget animates its child's opacity.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeIn,
              // Change opacity based on the _isButtonVisible state
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
                  // You can navigate to your main app screen here
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
