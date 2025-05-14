import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // ✅ Splash screen import
import 'screens/home_screen.dart';
import 'screens/player_setup_screen.dart';
import 'models/game_mode.dart';
import 'models/difficulty.dart';

void main() {
  runApp(const WordMazeApp());
}

class WordMazeApp extends StatelessWidget {
  const WordMazeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Word Maze',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFE0F7FA),
        primarySwatch: Colors.teal,
      ),
      home: const SplashScreen(), // 🌟 Splash screen first
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/setup':
            return MaterialPageRoute(builder: (_) => const PlayerSetupScreen(
              gameMode: GameMode.solo,
              difficulty: Difficulty.easy,
            ));
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
