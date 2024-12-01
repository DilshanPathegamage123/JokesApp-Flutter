import 'package:dio/dio.dart';

class JokeService {
  final Dio _dio = Dio();
  final String _apiUrl = 'https://v2.jokeapi.dev/joke/Any';

  Future<List<Map<String, dynamic>>> fetchJokes() async {
    try {
      final response = await _dio.get(
        _apiUrl,
        queryParameters: {'amount':8},
      );

      if (response.data['error'] == false) {
        return List<Map<String, dynamic>>.from(response.data['jokes']);
      } else {
        throw Exception('Failed to fetch jokes');
      }
    } catch (e) {
      throw Exception('Error fetching jokes: $e');
    }
  }
}