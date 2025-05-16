import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WordListService {
  // Replace with your GitHub Pages URLs
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
  
  // Get word list for the specified language
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
    
    // Try to fetch from network
    try {
      final url = languageCode == 'en' ? englishWordsUrl : arabicWordsUrl;
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Cache the response
        await prefs.setString(cacheKey, response.body);
        await prefs.setInt(lastUpdatedKey, now);
        
        print('Downloaded word list for $languageCode');
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load word list');
      }
    } catch (e) {
      print('Error fetching word list: $e');
      
      // Try to use cached data even if expired
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        print('Using expired cached word list for $languageCode');
        return json.decode(cachedData);
      }
      
      // If no cached data, use bundled assets
      throw Exception('No word list available for $languageCode');
    }
  }
  
  // Force refresh word lists
  static Future<bool> forceRefresh() async {
    try {
      final enData = await http.get(Uri.parse(englishWordsUrl));
      final arData = await http.get(Uri.parse(arabicWordsUrl));
      
      if (enData.statusCode == 200 && arData.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now().millisecondsSinceEpoch;
        
        await prefs.setString(englishCacheKey, enData.body);
        await prefs.setString(arabicCacheKey, arData.body);
        await prefs.setInt(lastUpdatedKey, now);
        
        print('Word lists refreshed successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Error refreshing word lists: $e');
      return false;
    }
  }
  
  // Check if updates are available
  static Future<bool> checkForUpdates() async {
    try {
      // Implement a version checking mechanism if needed
      return false;
    } catch (e) {
      return false;
    }
  }
}