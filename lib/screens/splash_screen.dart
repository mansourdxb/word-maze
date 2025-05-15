import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _logoAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
      ),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  // Get current locale and determine if RTL
  final currentLocale = Localizations.localeOf(context).languageCode;
  final isRtl = currentLocale == 'ar';
  
  return Directionality(
    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: Center(
        child: ScaleTransition(
          scale: _logoAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/wordmaze_logo.png',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)?.appTitle ?? "Word Maze",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF195B5B),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)?.splashTagline ?? "Play against Friends & AI",
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF195B5B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
