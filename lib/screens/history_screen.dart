import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('game_history') ?? [];
    final parsed = rawList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    setState(() {
      history = parsed.reversed.toList(); // Show latest first
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get current locale and determine if RTL
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isRtl = currentLocale == 'ar';
    
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.gameHistory ?? 'Game History'),
          backgroundColor: Colors.teal,
        ),
        body: history.isEmpty
            ? Center(
                child: Text(AppLocalizations.of(context)?.noHistoryFound ?? 'No history found.'),
              )
            : ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final game = history[index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                   title: Text(
  '${game['player1Name']} vs ${game['player2Name'] ?? AppLocalizations.of(context)?.versusAI ?? 'AI'}',
),

subtitle: Text(
  (AppLocalizations.of(context)?.historyScore as String? ?? 'Score: {score1} - {score2} • Words: {words}')
    .replaceAll('{score1}', game['player1Score'].toString())
    .replaceAll('{score2}', game['player2Score']?.toString() ?? '-')
    .replaceAll('{words}', game['player1Words'].toString()),
),



                    trailing: Text(
                      _getLocalizedDifficulty(context, game['difficulty']) ?? game['difficulty'],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String? _getLocalizedDifficulty(BuildContext context, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppLocalizations.of(context)?.easy;
      case 'medium':
        return AppLocalizations.of(context)?.medium;
      case 'hard':
        return AppLocalizations.of(context)?.hard;
      default:
        return difficulty;
    }
  }
}