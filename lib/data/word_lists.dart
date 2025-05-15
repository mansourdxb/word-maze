import 'dart:convert';
import 'package:flutter/services.dart';

class WordLists {
  // Using static to ensure we have a single instance
  static final WordLists _instance = WordLists._internal();
  factory WordLists() => _instance;
  WordLists._internal();

  // Initialize with empty maps to avoid null errors
  final Map<String, List<String>> easy = {};
  final Map<String, List<String>> medium = {};
  final Map<String, List<String>> hard = {};
  
  // Track which languages have been loaded
  final Set<String> loadedLanguages = {};

  Future<void> load(String languageCode) async {
    // Skip if already loaded
    if (loadedLanguages.contains(languageCode)) {
      print('Words for $languageCode already loaded');
      return;
    }

    try {
      final path = 'assets/words/${languageCode}_words.json';
      print('Loading words from $path');
      
      final data = await rootBundle.loadString(path);
      final jsonData = json.decode(data);

      // Add to existing maps instead of replacing them
      easy[languageCode] = List<String>.from(jsonData['easy']);
      medium[languageCode] = List<String>.from(jsonData['medium']);
      hard[languageCode] = List<String>.from(jsonData['hard']);
      
      // Mark as loaded
      loadedLanguages.add(languageCode);
      
      print('Successfully loaded ${easy[languageCode]?.length ?? 0} easy words for $languageCode');
    } catch (e) {
      print('Error loading words for $languageCode: $e');
      // Create empty lists for this language to avoid null errors
      easy[languageCode] = [];
      medium[languageCode] = [];
      hard[languageCode] = [];
    }
  }
}