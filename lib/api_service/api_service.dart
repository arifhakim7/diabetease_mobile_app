import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _apiKey = '';
  static const String _url = '';

  Future<String> fetchDailyTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchedTime = prefs.getInt('lastFetchedTime');
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Check if 24 hours have passed since last fetch
      if (lastFetchedTime == null ||
          currentTime - lastFetchedTime >= 24 * 60 * 60 * 1000) {
        // 24 hours in milliseconds
        // Fetch a new tip
        final response = await http.post(
          Uri.parse(_url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: json.encode({
            'model': 'gpt-3.5-turbo',
            'prompt': 'Give a daily diabetes tip.',
            'max_tokens': 100,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final tip = responseData['choices'][0]['text'].trim();

          // Store the new tip and update the fetch time
          prefs.setString('dailyTip', tip);
          prefs.setInt('lastFetchedTime', currentTime);

          return tip;
        } else {
          // Log detailed error information
          print('Failed to fetch tip. Status Code: ${response.statusCode}');
          print('Response Body: ${response.body}');
          throw Exception('Failed to fetch tip');
        }
      } else {
        // Return the cached tip if within 24 hours
        final cachedTip = prefs.getString('dailyTip');
        if (cachedTip != null) {
          return cachedTip;
        } else {
          throw Exception('No cached tip found');
        }
      }
    } catch (error) {
      // Log the error message
      print('Error: $error');
      throw Exception('Failed to fetch daily tip: $error');
    }
  }
}
