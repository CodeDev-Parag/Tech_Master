import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';

final motivationServiceProvider = Provider<MotivationService>((ref) {
  return MotivationService();
});

class MotivationService {
  final String _boxName = 'motivation_box';

  final List<String> _localQuotes = [
    "The only way to do great work is to love what you do. - Steve Jobs",
    "Believe you can and you're halfway there. - Theodore Roosevelt",
    "Your time is limited, don't waste it living someone else's life. - Steve Jobs",
    "The future belongs to those who believe in the beauty of their dreams. - Eleanor Roosevelt",
    "Success is not final, failure is not fatal: It is the courage to continue that counts. - Winston Churchill",
    "Don't watch the clock; do what it does. Keep going. - Sam Levenson",
    "The secret of getting ahead is getting started. - Mark Twain",
    "It always seems impossible until it's done. - Nelson Mandela",
    "Quality is not an act, it is a habit. - Aristotle",
    "Dream big and dare to fail. - Norman Vaughan",
  ];

  Future<String> getDailyQuote() async {
    final box = await Hive.openBox(_boxName);
    final lastDateStr = box.get('last_date');
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    // Note: To test "Daily" change, you can comment out this check
    if (lastDateStr == todayStr) {
      return box.get('current_quote', defaultValue: _localQuotes.first);
    }

    // Try fetching from backend
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.backendBaseUrl}/quote'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final backendQuote = data['quote'];

        // Save new daily quote
        await box.put('last_date', todayStr);
        await box.put('current_quote', backendQuote);
        return backendQuote;
      }
    } catch (e) {
      // Backend failed, fall back to local
      print('DEBUG: Quote backend fetch failed: $e');
    }

    // Fallback Local Logic
    final random = Random();
    final newQuote = _localQuotes[random.nextInt(_localQuotes.length)];
    await box.put('last_date', todayStr);
    await box.put('current_quote', newQuote);
    return newQuote;
  }
}
