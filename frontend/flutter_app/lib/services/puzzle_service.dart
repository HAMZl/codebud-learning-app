import '../models/command.dart';
import '../models/puzzle.dart';
import 'api_client.dart';

class ProgressResult {
  final int stars;
  final int bestStars;
  const ProgressResult({required this.stars, required this.bestStars});
}

class PuzzleService {
  PuzzleService(this._api);

  final ApiClient _api;

  Future<List<PuzzleSummary>> fetchCategory(String category) async {
    final data = await _api.get('/api/puzzles/$category', auth: true);
    return (data['puzzles'] as List).map((p) => PuzzleSummary.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<Puzzle> fetchPuzzle(String id) async {
    final data = await _api.get('/api/puzzle/$id');
    return Puzzle.fromJson(data);
  }

  Future<Map<String, CategoryProgress>> fetchProgress() async {
    final data = await _api.get('/api/progress', auth: true);
    final cats = data['categories'] as Map<String, dynamic>? ?? const {};
    return cats.map((k, v) => MapEntry(k, CategoryProgress.fromJson(v as Map<String, dynamic>)));
  }

  /// Sends the winning program. The server replays it and decides the stars.
  Future<ProgressResult> saveProgress(Puzzle puzzle, List<CommandItem> program) async {
    final data = await _api.post(
      '/api/progress',
      {'puzzle_id': puzzle.id, 'program': program.map((b) => b.toJson()).toList()},
      auth: true,
    );
    final stars = data['stars'] as int? ?? 0;
    return ProgressResult(stars: stars, bestStars: data['best_stars'] as int? ?? stars);
  }
}
