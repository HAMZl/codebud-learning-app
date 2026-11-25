import '../models/command.dart';
import '../models/puzzle.dart';
import 'api_client.dart';
import 'auth_service.dart';

class ProgressResult {
  final int stars;
  final int bestStars;
  const ProgressResult({required this.stars, required this.bestStars});
}

/// Puzzles and progress. Progress belongs to the child who is playing ([AuthService.activeChild]).
class PuzzleService {
  PuzzleService(this._api, this._auth);

  final ApiClient _api;
  final AuthService _auth;

  String _childQuery(String? childId) {
    final id = childId ?? _auth.activeChild?.id;
    return id == null ? '' : '?child_id=${Uri.encodeQueryComponent(id)}';
  }

  Future<List<PuzzleSummary>> fetchCategory(String category) async {
    final data = await _api.get('/api/puzzles/$category${_childQuery(null)}', auth: true);
    return (data['puzzles'] as List).map((p) => PuzzleSummary.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<Puzzle> fetchPuzzle(String id) async {
    final data = await _api.get('/api/puzzle/$id');
    return Puzzle.fromJson(data);
  }

  /// Stars per category, for the playing child or for [childId].
  Future<Map<String, CategoryProgress>> fetchProgress({String? childId}) async {
    final data = await _api.get('/api/progress${_childQuery(childId)}', auth: true);
    final cats = data['categories'] as Map<String, dynamic>? ?? const {};
    return cats.map((k, v) => MapEntry(k, CategoryProgress.fromJson(v as Map<String, dynamic>)));
  }

  /// Erases a child's progress for one category, or everything when [category] is null. Parents only.
  Future<int> resetProgress({required String childId, String? category}) => _auth.asParent((token) async {
        final query = '?child_id=${Uri.encodeQueryComponent(childId)}${category == null ? '' : '&category=$category'}';
        final data = await _api.delete('/api/progress$query', bearer: token);
        return data['removed'] as int? ?? 0;
      });

  /// Sends the winning program. The server replays it on every board and decides the stars.
  Future<ProgressResult> saveProgress(Puzzle puzzle, List<CommandItem> program) async {
    final child = _auth.activeChild;
    final data = await _api.post(
      '/api/progress',
      {
        'puzzle_id': puzzle.id,
        if (child != null) 'child_id': child.id,
        'program': program.map((b) => b.toJson()).toList(),
      },
      auth: true,
    );
    final stars = data['stars'] as int? ?? 0;
    return ProgressResult(stars: stars, bestStars: data['best_stars'] as int? ?? stars);
  }
}
