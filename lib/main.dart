import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/player_setup_screen.dart';
import 'models/game_mode.dart';
import 'models/difficulty.dart';
import 'l10n/l10n.dart';
import 'providers/locale_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      child: const WordMazeApp(),
    ),
  );
}

class WordMazeApp extends StatelessWidget {
  const WordMazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current locale from the provider
    final provider = Provider.of<LocaleProvider>(context);
    
     return MaterialApp(
    locale: provider.locale, // This is crucial
    supportedLocales: L10n.all,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
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
            // Extract arguments if provided, otherwise use defaults
            final args = settings.arguments as Map<String, dynamic>?;
            final gameMode = args?['gameMode'] ?? GameMode.solo;
            final difficulty = args?['difficulty'] ?? Difficulty.easy;
            final languageCode = args?['languageCode'] ?? 'en';
            
            return MaterialPageRoute(
              builder: (_) => PlayerSetupScreen(
                gameMode: gameMode,
                difficulty: difficulty,
                languageCode: languageCode,
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}