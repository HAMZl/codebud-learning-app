import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/puzzle.dart';

class PuzzleService {
  static const _baseUrl = 'https://codebud-learning-app.onrender.com/api';

  static Future<Puzzle?> fetchPuzzle(String id) async {
    final res = await http.get(Uri.parse('$_baseUrl/puzzle/$id'));
    if (res.statusCode == 200) {
      return Puzzle.fromJson(json.decode(res.body));
    }
    return null;
  }

  static Future<bool> saveProgress(
    String token,
    Puzzle puzzle,
    int stars,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/progress'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'puzzle_id': puzzle.id,
        'stars': stars,
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }),
    );
    return res.statusCode == 200;
  }
}
