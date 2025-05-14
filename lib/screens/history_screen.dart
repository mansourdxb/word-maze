import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
        backgroundColor: Colors.teal,
      ),
      body: history.isEmpty
          ? const Center(child: Text('No history found.'))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final game = history[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('${game['player1Name']} vs ${game['player2Name'] ?? 'AI'}'),
                  subtitle: Text('Score: ${game['player1Score']} - ${game['player2Score'] ?? '-'} • Words: ${game['player1Words']}'),
                  trailing: Text(game['difficulty']),
                );
              },
            ),
    );
  }
}
