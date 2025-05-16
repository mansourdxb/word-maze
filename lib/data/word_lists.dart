import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show min, Random;

class WordListService {
  // Updated URLs to use raw GitHub content
  static const String englishWordsUrl = 
      'https://raw.githubusercontent.com/mansourdxb/Games-Data/main/en_words.json';
  static const String arabicWordsUrl = 
      'https://raw.githubusercontent.com/mansourdxb/Games-Data/main/ar_words.json';
  
  // Cache keys
  static const String englishCacheKey = 'word_list_en';
  static const String arabicCacheKey = 'word_list_ar';
  static const String lastUpdatedKey = 'word_list_last_updated';
  
  // Cache duration (1 day in milliseconds)
  static const int cacheDuration = 24 * 60 * 60 * 1000;
  
  // Get word list for the specified language with detailed error reporting
  static Future<Map<String, dynamic>> getWordList(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = languageCode == 'en' ? englishCacheKey : arabicCacheKey;
    final lastUpdated = prefs.getInt(lastUpdatedKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if cache is valid
    if (now - lastUpdated < cacheDuration) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        print('Using cached word list for $languageCode');
        return json.decode(cachedData);
      }
    }
    
    // Try to fetch from network with detailed logging
    try {
      final url = languageCode == 'en' ? englishWordsUrl : arabicWordsUrl;
      print('Fetching word list from: $url');
      
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15)); // Add timeout
      
      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('Response body (first 100 chars): ${response.body.substring(0, min(100, response.body.length))}...');
        
        try {
          // Try to parse the JSON to ensure it's valid
          final decodedData = json.decode(response.body);
          
          // Validate structure
          if (!_validateWordList(decodedData)) {
            throw FormatException('Invalid word list format');
          }
          
          // Cache the valid response
          await prefs.setString(cacheKey, response.body);
          await prefs.setInt(lastUpdatedKey, now);
          
          print('Successfully downloaded and cached word list for $languageCode');
          return decodedData;
        } catch (parseError) {
          print('Error parsing JSON response: $parseError');
          throw FormatException('Invalid JSON response: $parseError');
        }
      } else {
        print('Failed HTTP request. Response body: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: Failed to load word list');
      }
    } catch (e) {
      print('Network error fetching word list: $e');
      
      // Try to use cached data even if expired
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        print('Using expired cached word list for $languageCode');
        return json.decode(cachedData);
      }
      
      // If no cached data, rethrow the error
      rethrow;
    }
  }
  
  // Validate the structure of the word list
  static bool _validateWordList(Map<String, dynamic> data) {
    return data.containsKey('easy') && 
           data.containsKey('medium') && 
           data.containsKey('hard') &&
           data['easy'] is List &&
           data['medium'] is List &&
           data['hard'] is List;
  }
  
  // Force refresh word lists with better error handling
  static Future<bool> forceRefresh() async {
    bool success = true;
    String errorMessage = '';
    
    try {
      print('Starting forced refresh of word lists...');
      
      // Try English word list
      try {
        print('Fetching English word list...');
        final enData = await http.get(Uri.parse(englishWordsUrl))
            .timeout(const Duration(seconds: 15));
        
        print('English word list status code: ${enData.statusCode}');
        
        if (enData.statusCode == 200) {
          final decodedData = json.decode(enData.body);
          if (_validateWordList(decodedData)) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(englishCacheKey, enData.body);
            print('English word list updated successfully');
          } else {
            success = false;
            errorMessage += 'Invalid English word list format. ';
          }
        } else {
          success = false;
          errorMessage += 'Failed to fetch English word list (HTTP ${enData.statusCode}). ';
        }
      } catch (e) {
        success = false;
        errorMessage += 'Error with English word list: $e. ';
        print('Error refreshing English word list: $e');
      }
      
      // Try Arabic word list
      try {
        print('Fetching Arabic word list...');
        final arData = await http.get(Uri.parse(arabicWordsUrl))
            .timeout(const Duration(seconds: 15));
        
        print('Arabic word list status code: ${arData.statusCode}');
        
        if (arData.statusCode == 200) {
          final decodedData = json.decode(arData.body);
          if (_validateWordList(decodedData)) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(arabicCacheKey, arData.body);
            print('Arabic word list updated successfully');
          } else {
            success = false;
            errorMessage += 'Invalid Arabic word list format. ';
          }
        } else {
          success = false;
          errorMessage += 'Failed to fetch Arabic word list (HTTP ${arData.statusCode}). ';
        }
      } catch (e) {
        success = false;
        errorMessage += 'Error with Arabic word list: $e. ';
        print('Error refreshing Arabic word list: $e');
      }
      
      // Update timestamp if at least one list was updated
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(lastUpdatedKey, now);
        print('Word lists refresh timestamp updated');
      } else {
        print('Word lists refresh failed: $errorMessage');
      }
      
      return success;
    } catch (e) {
      print('Critical error refreshing word lists: $e');
      return false;
    }
  }
}

// Added WordLists class to work with the word list data
class WordLists {
  // Maps to store word lists for different languages and difficulty levels
  Map<String, List<String>> easy = {};
  Map<String, List<String>> medium = {};
  Map<String, List<String>> hard = {};
  
  // Singleton pattern ensures we have only one instance of WordLists
  static final WordLists _instance = WordLists._internal();
  
  // Factory constructor returns the singleton instance
  factory WordLists() => _instance;
  
  // Private constructor for the singleton
  WordLists._internal();
  
  // Load word lists for a specific language
  Future<void> load(String languageCode) async {
    try {
      // Get word data from the service
      final wordData = await WordListService.getWordList(languageCode);
      
      // Populate the maps with the retrieved data
      if (wordData.containsKey('easy')) {
        easy[languageCode] = List<String>.from(wordData['easy']);
        print('Loaded ${easy[languageCode]?.length ?? 0} easy words for $languageCode');
      }
      
      if (wordData.containsKey('medium')) {
        medium[languageCode] = List<String>.from(wordData['medium']);
        print('Loaded ${medium[languageCode]?.length ?? 0} medium words for $languageCode');
      }
      
      if (wordData.containsKey('hard')) {
        hard[languageCode] = List<String>.from(wordData['hard']);
        print('Loaded ${hard[languageCode]?.length ?? 0} hard words for $languageCode');
      }
    } catch (e) {
      print('Error loading word lists for $languageCode: $e');
      
      // Initialize with empty lists if loading fails
      easy[languageCode] = [];
      medium[languageCode] = [];
      hard[languageCode] = [];
    }
  }
  
  // Check if lists for a language are loaded
  bool isLoaded(String languageCode) {
    return easy.containsKey(languageCode) && 
           medium.containsKey(languageCode) && 
           hard.containsKey(languageCode);
  }
  
  // Get a random word from a specific difficulty and language
  String getRandomWord(String languageCode, String difficulty) {
    List<String> wordPool;
    
    switch (difficulty.toLowerCase()) {
      case 'easy':
        wordPool = easy[languageCode] ?? [];
        break;
      case 'medium':
        wordPool = medium[languageCode] ?? [];
        break;
      case 'hard':
        wordPool = hard[languageCode] ?? [];
        break;
      default:
        wordPool = easy[languageCode] ?? [];
    }
    
    if (wordPool.isEmpty) {
      return 'no_words_available';
    }
    
    final random = Random();
    return wordPool[random.nextInt(wordPool.length)];
  }
}