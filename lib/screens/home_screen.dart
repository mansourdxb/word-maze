import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'player_setup_screen.dart';
import '../models/game_mode.dart';
import '../models/difficulty.dart';
import 'game_screen.dart'; // ✅ THIS LINE IS NEEDED!

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  GameMode _selectedMode = GameMode.solo;
  Difficulty _selectedDifficulty = Difficulty.easy;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void startGame() async {
    HapticFeedback.mediumImpact();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerSetupScreen(
          gameMode: _selectedMode,
          difficulty: _selectedDifficulty,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => GameScreen(
            gameMode: _selectedMode,
            difficulty: _selectedDifficulty,
            player1Name: result['player1Name'],
            player1AvatarPath: result['player1AvatarPath'],
            player2Name: result['player2Name'],
            player2AvatarPath: result['player2AvatarPath'],
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Widget _buildSelectionCard({
    required String title,
    required Widget content,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF195B5B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeSelector() {
    return Column(
      children: GameMode.values.map((mode) {
        final titles = {
          GameMode.solo: 'Solo Adventure',
          GameMode.versusPlayer: 'Play against Friends & AI',
          GameMode.versusAI: 'Battle AI Bot',
        };

        final icons = {
          GameMode.solo: Icons.person,
          GameMode.versusPlayer: Icons.people,
          GameMode.versusAI: Icons.smart_toy,
        };

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMode = mode;
            });
            HapticFeedback.lightImpact();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _selectedMode == mode
                  ? const Color(0xFF195B5B).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedMode == mode
                    ? const Color(0xFF195B5B)
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icons[mode],
                  color: _selectedMode == mode
                      ? const Color(0xFF195B5B)
                      : Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  titles[mode] ?? mode.toString().split('.').last,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _selectedMode == mode
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedMode == mode
                        ? const Color(0xFF195B5B)
                        : Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (_selectedMode == mode)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF195B5B),
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultySelector() {
    final difficultyColors = {
      Difficulty.easy: Colors.green.shade700,
      Difficulty.medium: Colors.orange.shade700,
      Difficulty.hard: Colors.red.shade700,
    };

    final difficultyDescriptions = {
      Difficulty.easy: 'Perfect for beginners',
      Difficulty.medium: 'Challenge your skills',
      Difficulty.hard: 'For word masters only',
    };

    return Column(
      children: Difficulty.values.map((difficulty) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDifficulty = difficulty;
            });
            HapticFeedback.lightImpact();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _selectedDifficulty == difficulty
                  ? (difficultyColors[difficulty] ?? Colors.blue).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDifficulty == difficulty
                    ? (difficultyColors[difficulty] ?? Colors.blue)
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: _selectedDifficulty == difficulty
                      ? (difficultyColors[difficulty] ?? Colors.blue)
                      : Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      difficulty.toString().split('.').last,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _selectedDifficulty == difficulty
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedDifficulty == difficulty
                            ? (difficultyColors[difficulty] ?? Colors.blue)
                            : Colors.grey.shade800,
                      ),
                    ),
                    if (_selectedDifficulty == difficulty)
                      Text(
                        difficultyDescriptions[difficulty] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: difficultyColors[difficulty] ?? Colors.blue,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                if (_selectedDifficulty == difficulty)
                  Icon(
                    Icons.check_circle,
                    color: difficultyColors[difficulty] ?? Colors.blue,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA),
              Color(0xFFB2EBF2),
              Color(0xFF80DEEA),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Hero(
                      tag: 'gameTitle',
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Word Maze',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF195B5B),
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Challenge Your Vocabulary',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF195B5B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildSelectionCard(
                      title: 'Game Mode',
                      content: _buildGameModeSelector(),
                      icon: Icons.sports_esports,
                      iconColor: const Color(0xFF009688),
                    ),
                    _buildSelectionCard(
                      title: 'Difficulty Level',
                      content: _buildDifficultySelector(),
                      icon: Icons.speed,
                      iconColor: const Color(0xFFF57C00),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC149).withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC149),
                          foregroundColor: const Color(0xFF195B5B),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Start Game',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.play_arrow, size: 28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
