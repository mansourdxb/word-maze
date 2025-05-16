import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'game_screen.dart';
import 'history_screen.dart'; // <-- new import
import '../models/game_mode.dart';
import '../models/difficulty.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ResultScreen extends StatefulWidget {
  final String player1Name;
  final String player1AvatarPath;
  final int player1Score;
  final int player1Words;

  final String? player2Name;
  final String? player2AvatarPath;
  final int? player2Score;
  final int? player2Words;

  final GameMode gameMode;
  final Difficulty difficulty;

  const ResultScreen({
    super.key,
    required this.player1Name,
    required this.player1AvatarPath,
    required this.player1Score,
    required this.player1Words,
    this.player2Name,
    this.player2AvatarPath,
    this.player2Score,
    this.player2Words,
    required this.gameMode,
    required this.difficulty,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
    );

    _saveResultToLocalHistory();
  }

  Future<void> _saveResultToLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('game_history') ?? [];

    final result = {
      'timestamp': DateTime.now().toIso8601String(),
      'player1Name': widget.player1Name,
      'player1Score': widget.player1Score,
      'player1Words': widget.player1Words,
      'player2Name': widget.player2Name,
      'player2Score': widget.player2Score,
      'player2Words': widget.player2Words,
      'gameMode': widget.gameMode.name,
      'difficulty': widget.difficulty.name,
    };

    history.add(jsonEncode(result));
    await prefs.setStringList('game_history', history);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ImageProvider _getAvatar(String path) {
    return path.startsWith('assets/') ? AssetImage(path) : FileImage(File(path));
  }

@override
Widget build(BuildContext context) {
  bool versus = widget.player2Name != null && widget.player2AvatarPath != null;
  bool player1Won = !versus || (widget.player1Score >= (widget.player2Score ?? 0));

  // Get current locale and determine if RTL
  final currentLocale = Localizations.localeOf(context).languageCode;
  final isRtl = currentLocale == 'ar';

  return Directionality(
    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Icon(
                    Icons.emoji_events,
                    size: 100,
                    color: player1Won ? Colors.amber : Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                if (!versus)
                  Text(
                    AppLocalizations.of(context)?.won(widget.player1Name) ?? '${widget.player1Name} Won!',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF195B5B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (versus)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPlayerBox(
                        name: widget.player1Name,
                        avatarPath: widget.player1AvatarPath,
                        score: widget.player1Score,
                        words: widget.player1Words,
                        isWinner: player1Won,
                      ),
                      _buildPlayerBox(
                        name: widget.player2Name ?? AppLocalizations.of(context)?.player2 ?? 'Friend',
                        avatarPath: widget.player2AvatarPath ?? 'assets/images/boy_avatar.png',
                        score: widget.player2Score ?? 0,
                        words: widget.player2Words ?? 0,
                        isWinner: !player1Won,
                      ),
                    ],
                  ),
                if (!versus)
                  ...[
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: _getAvatar(widget.player1AvatarPath),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)?.wordsSolved(widget.player1Words) ?? 'Words Solved: ${widget.player1Words}',
                      style: const TextStyle(fontSize: 22, color: Colors.teal, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)?.finalScore(widget.player1Score) ?? 'Final Score: ${widget.player1Score} pts',
                      style: const TextStyle(fontSize: 22, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                    ),
                  ],
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                          gameMode: widget.gameMode,
                          difficulty: widget.difficulty,
                          player1Name: widget.player1Name,
                          player1AvatarPath: widget.player1AvatarPath,
                          player2Name: widget.player2Name,
                          player2AvatarPath: widget.player2AvatarPath,
                          languageCode: currentLocale, // Make sure to pass the language!
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC149),
                    foregroundColor: const Color(0xFF195B5B),
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)?.rematch ?? 'Rematch',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: Text(
                    AppLocalizations.of(context)?.backToHome ?? 'Back to Home', 
                    style: const TextStyle(fontSize: 16, color: Colors.teal)
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.viewHistory ?? 'View History', 
                    style: const TextStyle(fontSize: 16, color: Colors.blue)
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildPlayerBox({required String name, required String avatarPath, required int score, required int words, required bool isWinner}) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isWinner ? Colors.amber : Colors.grey.shade400, width: 4),
        ),
        child: CircleAvatar(
          radius: 35,
          backgroundImage: _getAvatar(avatarPath),
          backgroundColor: Colors.white,
        ),
      ),
      const SizedBox(height: 8),
      Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, color: Colors.yellow.shade800, size: 18),
          const SizedBox(width: 4),
          Text('$score ${AppLocalizations.of(context)?.pts ?? "pts"}'),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.text_snippet, color: Colors.deepPurple, size: 18),
          const SizedBox(width: 4),
          Text('$words ${AppLocalizations.of(context)?.words ?? "words"}'),
        ],
      ),
      if (isWinner)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)?.winner ?? 'Winner!', 
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)
              ),
            ],
          ),
        ),
    ],
  );
}

 
}
