import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/splash/presentation/pages/welcome_screen.dart';

class KanakApp extends StatelessWidget {
  const KanakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kanakk App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white70),
        ),
      ),
      home: const LoginPage(),
    );
  }
}