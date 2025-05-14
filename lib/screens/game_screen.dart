import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../models/game_mode.dart';
import '../models/difficulty.dart';
import '../data/word_lists.dart';

class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final Difficulty difficulty;
  final String player1Name;
  final String player1AvatarPath;
  final String? player2Name;
  final String? player2AvatarPath;

  const GameScreen({
    Key? key,
    required this.gameMode,
    required this.difficulty,
    required this.player1Name,
    required this.player1AvatarPath,
    this.player2Name,
    this.player2AvatarPath,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final Random _random = Random();
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 3));
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<int> selectedIndexes = [];
  List<int> aiSelectedIndexes = [];
  String selectedLetters = '';

  int secondsRemaining = 120;
  Timer? countdownTimer;
  Timer? aiTimer;

  String targetWord = '';
  List<String> gridLetters = [];

  bool isPlayer1Turn = true;

  int player1Score = 0;
  int player2Score = 0;
  int player1Words = 0;
  int player2Words = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    pickRandomTargetWord();
    generateGridLetters();
    startTimer();
    if (isVersusAI) startAiBot();

    _audioPlayer.setSourceAsset('sounds/click.mp3');
    _audioPlayer.setSourceAsset('sounds/success.mp3');
    _audioPlayer.setSourceAsset('sounds/fail.mp3');
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    aiTimer?.cancel();
    _confettiController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  bool get isSolo => widget.gameMode == GameMode.solo;
  bool get isVersusPlayer => widget.gameMode == GameMode.versusPlayer;
  bool get isVersusAI => widget.gameMode == GameMode.versusAI;

  Future<void> playSound(String fileName) async => await _audioPlayer.play(AssetSource('sounds/$fileName'));

  void pickRandomTargetWord() {
    List<String> pool = widget.difficulty == Difficulty.easy
        ? WordLists.easyWords
        : widget.difficulty == Difficulty.medium
            ? WordLists.mediumWords
            : WordLists.hardWords;
    targetWord = pool[_random.nextInt(pool.length)].toUpperCase();
  }

  void generateGridLetters() {
    gridLetters = targetWord.split('');
    while (gridLetters.length < 36) {
      gridLetters.add(String.fromCharCode(_random.nextInt(26) + 65));
    }
    gridLetters.shuffle();
  }

  void startTimer() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        timer.cancel();
        playSound('fail.mp3');
        showTimeUpDialog();
      }
    });
  }

void startAiBot() {
  aiTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
    // ✅ Only play when it's AI's turn
    if (secondsRemaining <= 0 || selectedLetters == targetWord || isPlayer1Turn) {
      return;
    }

    // The rest of your smart AI logic stays unchanged
    int aiProgress = aiSelectedIndexes.length;
    String nextLetter = aiProgress < targetWord.length ? targetWord[aiProgress] : '';

    List<int> candidates = List.generate(gridLetters.length, (i) => i).where((i) {
      return gridLetters[i] == nextLetter &&
             !selectedIndexes.contains(i) &&
             !aiSelectedIndexes.contains(i);
    }).toList();

    if (candidates.isNotEmpty) {
      int selectedIndex = candidates[_random.nextInt(candidates.length)];
      setState(() => aiSelectedIndexes.add(selectedIndex));

  if (aiSelectedIndexes.length == targetWord.length) {
  playSound('success.mp3');
  _confettiController.play();
  player2Score += 50;
  player2Words++;
  
  // ✅ Delay next round to allow UI to update and show last AI selection
  Future.delayed(const Duration(milliseconds: 500), () {
    setState(() {
      aiSelectedIndexes.clear();
      selectedIndexes.clear();
      selectedLetters = '';
      isPlayer1Turn = true;
      pickRandomTargetWord();
      generateGridLetters();
    });
  });
}

    }
  });
}




  void resetGame() {
    setState(() {
      selectedIndexes.clear();
      aiSelectedIndexes.clear();
      selectedLetters = '';
      secondsRemaining = 120;
      player1Score = 0;
      player2Score = 0;
      player1Words = 0;
      player2Words = 0;
      isPlayer1Turn = true;
      pickRandomTargetWord();
      generateGridLetters();
      startTimer();
      if (isVersusAI) startAiBot();
    });
  }

  void showTimeUpDialog() {
    String player1Name = widget.player1Name;
    String player2Name = widget.gameMode == GameMode.versusAI
    ? 'AI'
    : (widget.player2Name ?? 'Friend');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Time's Up!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.teal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 50, color: Colors.amber),
            const SizedBox(height: 8),
            Text(
              '$player1Name: $player1Score pts, $player1Words words\n$player2Name: $player2Score pts, $player2Words words',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  void onTileTapped(int index) async {
    if (aiSelectedIndexes.contains(index)) return;
    playSound('click.mp3');

    setState(() {
      if (selectedIndexes.contains(index)) {
        selectedIndexes.remove(index);
        selectedLetters = selectedLetters.replaceFirst(gridLetters[index], '');
      } else {
        selectedIndexes.add(index);
        selectedLetters += gridLetters[index];
      }

      if (selectedLetters == targetWord) {
        _confettiController.play();
        playSound('success.mp3');
        if (isPlayer1Turn) {
          player1Score += 50;
          player1Words++;
        } else {
          player2Score += 50;
          player2Words++;
        }

        selectedIndexes.clear();
        aiSelectedIndexes.clear();
        selectedLetters = '';
        isPlayer1Turn = !isPlayer1Turn;
        pickRandomTargetWord();
        generateGridLetters();
      }
    });
  }

@override
Widget build(BuildContext context) {
  double gridSize = MediaQuery.of(context).size.width - 32;

  return Scaffold(
    backgroundColor: Colors.teal.shade50,
    appBar: AppBar(
      title: const Text('Word Maze'),
      centerTitle: true,
      backgroundColor: Colors.teal,
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildTopPlayersBar(),
          ),
          const SizedBox(height: 4),
          _buildTargetWord(),
          const SizedBox(height: 4),

          // ✅ Use Expanded to auto-fit grid without overflow
          Expanded(
            child: Container(
              width: gridSize,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder
              (
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 36,
                itemBuilder: (context, index) => _buildGridTile(index),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ✅ Keep selected word visible, make it compact
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selected Letters:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedLetters.isEmpty ? '_' : selectedLetters,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.teal.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 6), // ✅ Final bottom padding
        ],
      ),
    ),
    floatingActionButton: Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        numberOfParticles: 30,
        gravity: 0.3,
      ),
    ),
  );
}


  Widget _buildTopPlayersBar() => Padding(
    padding: const EdgeInsets.all(12.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPlayerInfo(true),
        _buildTimer(),
        if (isVersusPlayer || isVersusAI) _buildPlayerInfo(false),
      ],
    ),
  );

  Widget _buildPlayerInfo(bool isPlayer1) {
    String name = isPlayer1
    ? widget.player1Name
    : (widget.gameMode == GameMode.versusAI ? 'AI' : (widget.player2Name ?? 'Friend'));

    String avatar = isPlayer1 ? widget.player1AvatarPath : (widget.player2AvatarPath ?? 'assets/images/boy_avatar.png');
    int score = isPlayer1 ? player1Score : player2Score;
    int words = isPlayer1 ? player1Words : player2Words;
    bool isActive = isPlayer1 == isPlayer1Turn;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.teal : Colors.grey.shade400,
              width: isActive ? 4 : 2,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundImage: avatar.startsWith('assets/')
                ? AssetImage(avatar)
                : FileImage(File(avatar)) as ImageProvider,
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal.shade900)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 14, color: Colors.amber.shade700),
            const SizedBox(width: 4),
            Text('$score pts', style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 14, color: Colors.deepPurple),
            const SizedBox(width: 4),
            Text('$words words', style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimer() => Column(
    children: [
      Row(
        children: [
          Icon(Icons.timer, color: Colors.teal.shade800, size: 18),
          const SizedBox(width: 6),
          Text(
            "${(secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(secondsRemaining % 60).toString().padLeft(2, '0')}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: secondsRemaining < 30 ? Colors.redAccent : Colors.teal.shade800,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      const Text('Time Left', style: TextStyle(fontSize: 12, color: Colors.black54)),
    ],
  );

  Widget _buildTargetWord() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // ⬅️ Reduced vertical margin
  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // ⬅️ Reduced vertical padding
  decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
    ),
    child: ScaleTransition(
      scale: _pulseAnimation,
      child: Text(
        targetWord.split('').join(' '),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: targetWord.length > 10 ? 18 : 24, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
      ),
    ),
  );

  Widget _buildGridTile(int index) => GestureDetector(
    onTap: () => onTileTapped(index),
    child: Container(
      decoration: BoxDecoration(
        color: selectedIndexes.contains(index)
            ? Colors.teal
            : aiSelectedIndexes.contains(index)
                ? Colors.deepOrange
                : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      child: Center(
        child: Text(
          gridLetters[index],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: selectedIndexes.contains(index) || aiSelectedIndexes.contains(index) ? Colors.white : Colors.teal.shade900,
          ),
        ),
      ),
    ),
  );

Widget _buildSelectedWord() => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // reduced vertical padding
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        'Selected Letters:',
        style: TextStyle(
          fontSize: 11, // smaller label
          fontWeight: FontWeight.w500,
          color: Colors.teal,
        ),
      ),
      const SizedBox(height: 2), // less spacing
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          selectedLetters.isEmpty ? '_' : selectedLetters,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16, // slightly smaller
            color: Colors.teal.shade900,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  ),
);


}
