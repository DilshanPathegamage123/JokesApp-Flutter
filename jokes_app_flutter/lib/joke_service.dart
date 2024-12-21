import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class JokeService {
  final Dio _dio = Dio();

  // To fetch jokes from the API
  Future<List<Map<String, dynamic>>> fetchJokes() async {
    try {
      final response =
      await _dio.get('https://v2.jokeapi.dev/joke/Any?amount=5');
      if (response.statusCode == 200) {
        final List<dynamic> jokesJsonList = response.data['jokes'];
        final jokes = jokesJsonList.cast<Map<String, dynamic>>();
        await cacheJokes(jokes);
        return jokes;
      } else {
        throw Exception("Failed to load jokes");
      }
    } catch (e) {
      print("Error fetching jokes: $e");
      return await loadCachedJokes();
    }
  }

  // To cache jokes in the shared preferences
  Future<void> cacheJokes(List<Map<String, dynamic>> jokes) async {
    final prefs = await SharedPreferences.getInstance();
    final jokesJson = jsonEncode(jokes);
    await prefs.setString('cached_jokes', jokesJson);
  }

  // To load cached jokes from the shared preferences
  Future<List<Map<String, dynamic>>> loadCachedJokes() async {
    final prefs = await SharedPreferences.getInstance();
    final jokesJson = prefs.getString('cached_jokes');
    if (jokesJson != null) {
      final List<dynamic> jokesList = jsonDecode(jokesJson);
      return jokesList.cast<Map<String, dynamic>>();
    } else {
      return[];
    }
    }

    // To save favorite jokes in the shared preferences
  Future<void> cacheFavoriteJokes(Set<Map<String, dynamic>> favoriteJokes) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteJokesJson = jsonEncode(favoriteJokes.toList());
    await prefs.setString('favorite_jokes', favoriteJokesJson);
  }

  // To load favorite jokes from the shared preferences
  Future<Set<Map<String, dynamic>>> loadFavoriteJokes() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteJokesJson = prefs.getString('favorite_jokes');
    if (favoriteJokesJson != null) {
      final List<dynamic> favoriteJokesList = jsonDecode(favoriteJokesJson);
      return favoriteJokesList.cast<Map<String, dynamic>>().toSet();
    } else {
      return {};
    }
  }
}

