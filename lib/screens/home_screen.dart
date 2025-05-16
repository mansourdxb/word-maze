import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'player_setup_screen.dart';
import '../models/game_mode.dart';
import '../models/difficulty.dart';
import 'game_screen.dart'; 
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/locale_provider.dart';
import '../services/word_list_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
// Remove any import of WordListService from word_lists.dart if it exists

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin 
{
  GameMode _selectedMode = GameMode.solo;
  Difficulty _selectedDifficulty = Difficulty.easy;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  String selectedLanguage = 'en';

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

  void startGame() async 
  {
    HapticFeedback.mediumImpact();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerSetupScreen(
          gameMode: _selectedMode,
          difficulty: _selectedDifficulty,
          languageCode: selectedLanguage, // Add this

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
      languageCode: selectedLanguage, // Add this line
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

  Widget _buildSelectionCard
  (
    {
    required String title,
    required Widget content,
    required IconData icon,
    required Color iconColor,
  }
  ) 
  {
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
  GameMode.solo: AppLocalizations.of(context)?.soloAdventure ?? 'Solo Adventure',
  GameMode.versusPlayer: AppLocalizations.of(context)?.versusPlayers ?? 'Play against Friends & AI',
  GameMode.versusAI: AppLocalizations.of(context)?.versusAI ?? 'Battle AI Bot',
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

  // Use localized names for difficulties
  final difficultyNames = {
    Difficulty.easy: AppLocalizations.of(context)?.easy ?? 'Easy',
    Difficulty.medium: AppLocalizations.of(context)?.medium ?? 'Medium',
    Difficulty.hard: AppLocalizations.of(context)?.hard ?? 'Hard',
  };

  final difficultyDescriptions = {
    Difficulty.easy: AppLocalizations.of(context)?.easyDescription ?? 'Perfect for beginners',
    Difficulty.medium: AppLocalizations.of(context)?.mediumDescription ?? 'Challenge your skills',
    Difficulty.hard: AppLocalizations.of(context)?.hardDescription ?? 'For word masters only',
  };

  return Column(
    children: Difficulty.values.map<Widget>((difficulty) {
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
                    // Use the localized name instead of the enum value
                    difficultyNames[difficulty] ?? difficulty.toString().split('.').last,
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



Widget _buildLanguageSelector() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context)?.language ?? 'Language:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLanguage,
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
           onChanged: (String? newValue) async {
  if (newValue != null) {
    setState(() {
      selectedLanguage = newValue;
    });
    
    // Debug print
    print('Setting locale to: $newValue');
    
    try {
      // First, save the preference so it persists even if app restarts
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', newValue);
      
      // Update the app's locale using the LocaleProvider
      final provider = Provider.of<LocaleProvider>(context, listen: false);
      provider.setLocale(Locale(newValue));
      
      // Force UI to rebuild with new locale by showing a loading dialog briefly
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          ),
        );
        
        // Small delay to allow locale change to propagate through the widget tree
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Close dialog if context is still mounted
        if (context.mounted) {
          Navigator.of(context).pop();
          
          // Give user feedback about language change
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newValue == 'ar' 
                  ? 'تم تغيير اللغة إلى العربية' 
                  : 'Language changed to English'
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
      
      // Final debug print to confirm change
      print('Language successfully changed to: $newValue');
      
    } catch (e) {
      // Handle any errors
      print('Error changing language: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing language: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
},
              items: [
                DropdownMenuItem<String>(
                  value: 'en',
                  child: Text(AppLocalizations.of(context)?.english ?? 'English'),
                ),
                DropdownMenuItem<String>(
                  value: 'ar',
                  child: Text(AppLocalizations.of(context)?.arabic ?? 'العربية'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildLanguageOption(String code, String name, IconData icon) {
  final isSelected = selectedLanguage == code;
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Material(
      color: isSelected ? const Color(0xFF3F51B5).withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            selectedLanguage = code;
          });
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF3F51B5) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF3F51B5) : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF3F51B5) : Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF3F51B5),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

 @override
Widget build(BuildContext context) {
  // Get current locale and determine if RTL
  final currentLocale = Localizations.localeOf(context).languageCode;
  final isRtl = currentLocale == 'ar';
  
  // For debugging
  print('HomeScreen building with locale: $currentLocale, is RTL: $isRtl');

  return Directionality(
    // Set text direction based on language
    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
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
                    Text(
                      AppLocalizations.of(context)?.appTitle ?? 'Word Maze',
                      style: const TextStyle(
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
                    Text(
                      AppLocalizations.of(context)?.tagline ?? 'Challenge Your Vocabulary',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF195B5B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildSelectionCard(
                      title: AppLocalizations.of(context)?.gameMode ?? 'Game Mode',
                      content: _buildGameModeSelector(),
                      icon: Icons.sports_esports,
                      iconColor: const Color(0xFF009688),
                    ),
                    _buildSelectionCard(
                      title: AppLocalizations.of(context)?.difficultyLevel ?? 'Difficulty Level',
                      content: _buildDifficultySelector(),
                      icon: Icons.speed,
                      iconColor: const Color(0xFFF57C00),
                    ),
                    _buildSelectionCard(
                      title: AppLocalizations.of(context)?.language ?? 'Language',
                      content: _buildLanguageSelector(),
                      icon: Icons.language,
                      iconColor: const Color(0xFF3F51B5),
                    ),
                    Padding(
  padding: const EdgeInsets.symmetric(vertical: 10.0),
 child: ElevatedButton.icon(
  icon: const Icon(Icons.refresh),
  label: const Text('Update Word Lists'),
  onPressed: () async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Updating word lists...\nPlease wait'),
          ],
        ),
      ),
    );
    
    try {
      // Try to refresh with a timeout
      final success = await WordListService.forceRefresh()
          .timeout(const Duration(seconds: 30));
      
      // Close loading indicator
      if (context.mounted) Navigator.of(context).pop();
      
      // Show detailed result
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Word lists updated successfully!' 
              : 'Failed to update word lists. Check your internet connection.'),
            duration: const Duration(seconds: 3),
            action: success ? null : SnackBarAction(
              label: 'Retry',
              onPressed: () {
                // Retry the refresh using the same logic - just copy it
                // instead of using "this.onPressed!()"
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Updating word lists...\nPlease wait'),
                      ],
                    ),
                  ),
                );
                
                WordListService.forceRefresh()
                  .timeout(const Duration(seconds: 30))
                  .then((success) {
                    // Close loading indicator
                    if (context.mounted) Navigator.of(context).pop();
                    
                    // Show result
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success 
                            ? 'Word lists updated successfully!' 
                            : 'Failed to update word lists. Check your internet connection.'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  })
                  .catchError((e) {
                    // Close loading indicator
                    if (context.mounted) Navigator.of(context).pop();
                    
                    // Show error
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          duration: const Duration(seconds: 5),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (context.mounted) Navigator.of(context).pop();
      
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  },
),


),

const SizedBox(height: 15),
TextButton(
  child: const Text('Test Connection'),
  onPressed: () async {
    try {
      final response = await http.get(
        Uri.parse('https://raw.githubusercontent.com/mansourdxb/Games-Data/main/test.json'),
      );
      
      if (response.statusCode == 200) {
        print('Test successful: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection successful: ${response.body}')),
        );
      } else {
        print('Test failed: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Test error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
),

const SizedBox(height: 30), // This is the original spacing before "Start Game" button

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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.startGame ?? 'Start Game',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.play_arrow, size: 28),
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
    ),
  );
}
}
