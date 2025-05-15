// lib/screens/player_setup_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'game_screen.dart';
import '../models/game_mode.dart';
import '../models/difficulty.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlayerSetupScreen extends StatefulWidget {
  final GameMode gameMode;
  final Difficulty difficulty;
  final String languageCode; // Add this


   const PlayerSetupScreen({
    Key? key,
    required this.gameMode,
    required this.difficulty,
    required this.languageCode, // Add this
  }) : super(key: key);

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  int currentPlayer = 1;

  final TextEditingController _nameController = TextEditingController();
  String? selectedAvatar;
  File? customImage;

  String? player1Name;
  String? player1Avatar;
  String? player2Name;
  String? player2Avatar;

  void _pickCustomImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        customImage = File(picked.path);
        selectedAvatar = null;
      });
    }
  }

  void _nextOrStartGame() {
  if (_nameController.text.isEmpty || (selectedAvatar == null && customImage == null)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        AppLocalizations.of(context)?.selectAvatar ?? 'Please enter your name and select an avatar'
      )),
    );
    return;

    }

    if (widget.gameMode == GameMode.versusPlayer && currentPlayer == 1) {
      player1Name = _nameController.text;
      player1Avatar = customImage?.path ?? selectedAvatar!;
      _nameController.clear();
      selectedAvatar = null;
      customImage = null;
      setState(() => currentPlayer = 2);
    } else {
      if (widget.gameMode == GameMode.versusPlayer) {
        player2Name = _nameController.text;
        player2Avatar = customImage?.path ?? selectedAvatar!;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            gameMode: widget.gameMode,
            difficulty: widget.difficulty,
            player1Name: player1Name ?? _nameController.text,
            player1AvatarPath: player1Avatar ?? (customImage?.path ?? selectedAvatar!),
            player2Name: widget.gameMode == GameMode.versusAI ? "AI" : player2Name,
            player2AvatarPath: widget.gameMode == GameMode.versusAI ? "assets/images/ai_avatar.png" : player2Avatar,
            //languageCode: 'en', // Add this for now, you'll need to pass it from HomeScreen later
            languageCode: widget.languageCode, // Use the language passed from HomeScreen


          ),
        ),
      );
    }
  }

void _startAsGuest() {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => GameScreen(
        gameMode: widget.gameMode,
        difficulty: widget.difficulty,
        player1Name: AppLocalizations.of(context)?.guest ?? 'Guest',
        player1AvatarPath: 'assets/images/guest_avatar.png',
      player2Name: widget.gameMode == GameMode.versusAI 
    ? AppLocalizations.of(context)?.versusAI ?? 'AI' 
    : null,
        player2AvatarPath: widget.gameMode == GameMode.versusAI 
            ? 'assets/images/ai_avatar.png' 
            : null,
        languageCode: widget.languageCode,
      ),
    ),
  );
}

@override
Widget build(BuildContext context) {
  // Get current locale and determine if RTL
  final currentLocale = Localizations.localeOf(context).languageCode;
  final isRtl = currentLocale == 'ar';
  
  return Directionality(
    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(widget.gameMode == GameMode.versusPlayer
            ? (currentPlayer == 1 
                ? AppLocalizations.of(context)?.player1Setup ?? 'Player 1 Setup'
                : AppLocalizations.of(context)?.player2Setup ?? 'Player 2 Setup')
            : AppLocalizations.of(context)?.playerSetup ?? 'Player Setup'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.enterName ?? 'Enter your name',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.teal, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)?.selectAvatar ?? 'Choose Avatar:', 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAvatarOption('assets/images/boy_avatar.png'),
                  _buildAvatarOption('assets/images/girl_avatar.png'),
                  _buildUploadOption(),
                ],
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: _nextOrStartGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC149),
                    foregroundColor: const Color(0xFF195B5B),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    (widget.gameMode == GameMode.versusPlayer && currentPlayer == 1)
                        ? AppLocalizations.of(context)?.nextPlayer ?? 'Next Player'
                        : AppLocalizations.of(context)?.startGame ?? 'Start Game',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              if (widget.gameMode == GameMode.versusAI || widget.gameMode == GameMode.solo)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: _startAsGuest,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.teal, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.continueAsGuest ?? 'Continue as Guest',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.person_outline, color: Colors.teal, size: 26),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildAvatarOption(String imagePath) {
    bool isSelected = selectedAvatar == imagePath;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAvatar = imagePath;
          customImage = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 4 : 2,
          ),
        ),
        child: CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage(imagePath),
          backgroundColor: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildUploadOption() {
    bool isSelected = customImage != null;
    return GestureDetector(
      onTap: _pickCustomImage,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 4 : 2,
          ),
        ),
        child: CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade200,
          child: isSelected
              ? ClipOval(
                  child: Image.file(
                    customImage!,
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  ),
                )
              : ClipOval(
                  child: Image.asset(
                    'assets/images/Upload_photo.png',
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  ),
                ),
        ),
      ),
    );
  }
}
