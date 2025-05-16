import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../models/game_mode.dart';
import '../models/difficulty.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:word_maze/data/word_lists.dart';


class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final Difficulty difficulty;
  final String player1Name;
  final String player1AvatarPath;
  final String? player2Name;
  final String? player2AvatarPath;
  final String languageCode; // Added parameter

  const GameScreen({
    super.key,
    required this.gameMode,
    required this.difficulty,
    required this.player1Name,
    required this.player1AvatarPath,
    this.player2Name,
    this.player2AvatarPath,
    required this.languageCode, // Added parameter requirement
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin 
{
  final Random _random = Random();
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 3));
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> usedWords = {}; // Add this line to track used words

 // Add this constant
  static const int _maxTrackedWords = 100; // Adjust as needed
  
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

  // Initialize with loading state
  targetWord = '...';
  
  // First load the current language
  WordLists().load(widget.languageCode).then((_) {
    // Also load English as a fallback if needed
    if (widget.languageCode != 'en') {
      return WordLists().load('en');
    }
    return Future.value();
  }).then((_) {
    setState(() {
      pickRandomTargetWord();
      generateGridLetters();
    });
    
    // Start timer and AI after words are loaded
    startTimer();
    if (isVersusAI) startAiBot();
  });

  _audioPlayer.setSourceAsset('sounds/click.mp3');
  _audioPlayer.setSourceAsset('sounds/success.mp3');
  _audioPlayer.setSourceAsset('sounds/fail.mp3');
}

String _randomArabicLetter() {
  const arabicLetters = ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'];
    final letter = arabicLetters[_random.nextInt(arabicLetters.length)];
  
  // Validation to ensure we don't return an empty string
  return letter.isNotEmpty ? letter : 'ع'; // Fallback to 'ع' if somehow we get an empty letter
}
 @override
void dispose() {
  countdownTimer?.cancel();
  aiTimer?.cancel();
  _confettiController.dispose();
  _pulseController.dispose();
  _audioPlayer.dispose();
  usedWords.clear(); // Clear the used words
  super.dispose();
}

  bool get isSolo => widget.gameMode == GameMode.solo;
  bool get isVersusPlayer => widget.gameMode == GameMode.versusPlayer;
  bool get isVersusAI => widget.gameMode == GameMode.versusAI;

  Future<void> playSound(String fileName) async => await _audioPlayer.play(AssetSource('sounds/$fileName'));

void pickRandomTargetWord() {
  // Get word lists for the selected language
  List<String> pool = [];
  String effectiveLanguage = widget.languageCode;
  
  // Check if we have words for this language and difficulty
  switch (widget.difficulty) {
    case Difficulty.easy:
      if (WordLists().easy[effectiveLanguage]?.isEmpty ?? true) {
        effectiveLanguage = 'en'; // Fall back to English
      }
      pool = WordLists().easy[effectiveLanguage] ?? [];
      break;
    case Difficulty.medium:
      if (WordLists().medium[effectiveLanguage]?.isEmpty ?? true) {
        effectiveLanguage = 'en';
      }
      pool = WordLists().medium[effectiveLanguage] ?? [];
      break;
    case Difficulty.hard:
      if (WordLists().hard[effectiveLanguage]?.isEmpty ?? true) {
        effectiveLanguage = 'en';
      }
      pool = WordLists().hard[effectiveLanguage] ?? [];
      break;
  }

  // Filter out words that have already been used
  List<String> availableWords = pool.where((word) => !usedWords.contains(word.toUpperCase())).toList();
  
  // If we've used all words, reset the used words tracking
  if (availableWords.isEmpty) {
    print("All words have been used! Resetting word pool.");
    usedWords.clear();
    availableWords = pool;
  }

  // Pick a random word from available words
  final randomWord = availableWords[_random.nextInt(availableWords.length)].toUpperCase();
  
  // Add the word to used words set
  usedWords.add(randomWord);
  
  // Add memory management - prevent the tracked words list from growing too large
  if (usedWords.length > _maxTrackedWords) {
    // Remove the oldest words
    final List<String> wordsList = usedWords.toList();
    wordsList.removeRange(0, wordsList.length - _maxTrackedWords ~/ 2);
    usedWords.clear();
    usedWords.addAll(wordsList);
    print("Memory management: Reduced used words list to ${usedWords.length} words");
  }
  
  // Set the target word
  targetWord = randomWord;
  print("Selected target word: $targetWord from language: $effectiveLanguage (${usedWords.length} words used)");
}
 void generateGridLetters() {
  if (targetWord.isEmpty) {
    print("❌ targetWord is empty, using fallback");
    targetWord = 'TEST';
  }

  // Start with characters from the target word
  gridLetters = targetWord.characters.toList();
  
  // Create a pool of filler letters
  List<String> fillerPool = [];
  
  // Get words from the current language first
  List<String> wordPool = [];
  switch (widget.difficulty) {
    case Difficulty.easy:
      wordPool = WordLists().easy[widget.languageCode] ?? [];
      break;
    case Difficulty.medium:
      wordPool = WordLists().medium[widget.languageCode] ?? [];
      break;
    case Difficulty.hard:
      wordPool = WordLists().hard[widget.languageCode] ?? [];
      break;
  }
  
  // If no words in this language, try English
  if (wordPool.isEmpty && widget.languageCode != 'en') {
    switch (widget.difficulty) {
      case Difficulty.easy:
        wordPool = WordLists().easy['en'] ?? [];
        break;
      case Difficulty.medium:
        wordPool = WordLists().medium['en'] ?? [];
        break;
      case Difficulty.hard:
        wordPool = WordLists().hard['en'] ?? [];
        break;
    }
  }
  
  // Extract characters from words
  for (var word in wordPool) {
    fillerPool.addAll(word.characters);
  }
  
  // Filter out any empty or whitespace characters
  fillerPool.removeWhere((char) => char.trim().isEmpty);
  
  // Also remove target word characters to avoid too many duplicates
  fillerPool.removeWhere((char) => targetWord.characters.contains(char));
  
  // Fill the grid
  while (gridLetters.length < 36) {
    if (fillerPool.isNotEmpty) {
      // Use characters from our pool
      String nextChar = fillerPool[_random.nextInt(fillerPool.length)];
      
      // Extra validation - ensure no empty characters
      if (nextChar.trim().isNotEmpty) {
        gridLetters.add(nextChar);
      } else {
        // If somehow we got an empty character, add a fallback
        if (widget.languageCode == 'ar') {
          gridLetters.add(_randomArabicLetter());
        } else {
          gridLetters.add(String.fromCharCode(65 + _random.nextInt(26))); // A-Z
        }
      }
    } else {
      // Fallback to language-appropriate characters
      if (widget.languageCode == 'ar') {
        gridLetters.add(_randomArabicLetter());
      } else {
        // Default to English alphabet
        gridLetters.add(String.fromCharCode(65 + _random.nextInt(26))); // A-Z
      }
    }
  }

  // Final validation - ensure no empty cells in the grid
  for (int i = 0; i < gridLetters.length; i++) {
    if (gridLetters[i].trim().isEmpty) {
      // Replace any empty cells with a valid letter
      if (widget.languageCode == 'ar') {
        gridLetters[i] = _randomArabicLetter();
      } else {
        gridLetters[i] = String.fromCharCode(65 + _random.nextInt(26)); // A-Z
      }
      print("⚠️ Fixed an empty cell at position $i");
    }
  }

  // Shuffle the grid
  gridLetters.shuffle();
  print("🔤 Generated grid with ${gridLetters.length} letters");
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
      usedWords.clear(); // Clear the used words
      pickRandomTargetWord();
      generateGridLetters();
      startTimer();
      if (isVersusAI) startAiBot();
    });
  }

void showTimeUpDialog() {
  String player1Name = widget.player1Name;
  String player2Name = widget.gameMode == GameMode.versusAI
    ? AppLocalizations.of(context)?.versusAI ?? 'AI'
    : (widget.player2Name ?? AppLocalizations.of(context)?.player2 ?? 'Friend');

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(
        AppLocalizations.of(context)?.timesUp ?? "Time's Up!", 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.teal)
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 50, color: Colors.amber),
          const SizedBox(height: 8),
          Text(
            '$player1Name: $player1Score ${AppLocalizations.of(context)?.pts ?? "pts"}, '
            '$player1Words ${AppLocalizations.of(context)?.words ?? "words"}\n'
            '$player2Name: $player2Score ${AppLocalizations.of(context)?.pts ?? "pts"}, '
            '$player2Words ${AppLocalizations.of(context)?.words ?? "words"}',
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
          child: Text(AppLocalizations.of(context)?.playAgain ?? 'Play Again'),
        ),
        TextButton(
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: Text(AppLocalizations.of(context)?.backToHome ?? 'Back to Home'),
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
  
  // Get current locale and determine if RTL
  final currentLocale = Localizations.localeOf(context).languageCode;
  final isRtl = currentLocale == 'ar';
  
  // For debugging
  print('Building GameScreen with locale: $currentLocale, is RTL: $isRtl');

  return Directionality(
    // Set text direction based on language
    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        // Replace const Text with localized text
        title: Text(
          AppLocalizations.of(context)?.appTitle ?? 'Word Maze',
        ),
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

            // ✅ This part is already good
            Expanded(
              child: Container(
                width: gridSize,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
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

            // Update the "Selected Letters" text to use localization
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Replace const Text with localized text
                  Text(
                    AppLocalizations.of(context)?.selectedLetters ?? 'Selected Letters:',
                    style: const TextStyle(
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

            const SizedBox(height: 6),
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
    : (widget.gameMode == GameMode.versusAI 
        ? AppLocalizations.of(context)?.versusAI ?? 'AI' 
        : (widget.player2Name ?? AppLocalizations.of(context)?.player2 ?? 'Friend'));

  String avatar = isPlayer1 ? widget.player1AvatarPath : (widget.player2AvatarPath ?? 'assets/images/boy_avatar.png');
  int score = isPlayer1 ? player1Score : player2Score;
  int words = isPlayer1 ? player1Words : player2Words;
  bool isActive = isPlayer1 == isPlayer1Turn;

  return Column(
    children: [
      // Avatar container is fine
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
          Text('$score ${AppLocalizations.of(context)?.pts ?? "pts"}', 
               style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 14, color: Colors.deepPurple),
          const SizedBox(width: 4),
          Text('$words ${AppLocalizations.of(context)?.words ?? "words"}', 
               style: const TextStyle(fontSize: 12, color: Colors.black87)),
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
    Text(
      AppLocalizations.of(context)?.timeLeft ?? 'Time Left', 
      style: const TextStyle(fontSize: 12, color: Colors.black54)
    ),
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
  widget.languageCode == 'ar' 
      ? targetWord 
      : targetWord.split('').join(' '),
  textAlign: TextAlign.center,
  textDirection: widget.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
  style: TextStyle(
    fontSize: targetWord.length > 10 ? 18 : 24, 
    fontWeight: FontWeight.bold, 
    color: Colors.teal.shade900
  ),
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
        // Add validation to ensure we display something
        gridLetters[index].trim().isNotEmpty ? gridLetters[index] : (widget.languageCode == 'ar' ? 'ع' : 'X'),
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
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        AppLocalizations.of(context)?.selectedLetters ?? 'Selected Letters:',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.teal,
        ),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          selectedLetters.isEmpty ? '_' : selectedLetters,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.teal.shade900,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  ),
);


}
