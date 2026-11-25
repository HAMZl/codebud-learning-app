import 'point.dart';

/// A full puzzle, as returned by `GET /api/puzzle/<id>`.
class Puzzle {
  final String id;
  final String title;
  final String category;
  final int gridSize;
  final Point start;
  final Point goal;
  final List<Point> obstacles;

  /// Number of blocks that earns 3 stars.
  final int par;

  /// The next puzzle in the same category, if there is one.
  final PuzzleRef? next;

  /// Extra boards where the rocks (and maybe the star) are somewhere else.
  /// One program has to solve every board, which is what makes If blocks useful.
  final List<BoardVariant> variants;

  const Puzzle({
    required this.id,
    required this.title,
    required this.category,
    required this.gridSize,
    required this.start,
    required this.goal,
    required this.obstacles,
    required this.par,
    this.next,
    this.variants = const [],
  });

  /// This puzzle's main board followed by its variants, each as a puzzle of its own.
  List<Puzzle> get boards => [
        this,
        for (final v in variants)
          Puzzle(
            id: id,
            title: title,
            category: category,
            gridSize: gridSize,
            start: v.start ?? start,
            goal: v.goal ?? goal,
            obstacles: v.obstacles,
            par: par,
          ),
      ];

  factory Puzzle.fromJson(Map<String, dynamic> j) => Puzzle(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? 'Puzzle',
        category: j['category'] as String,
        gridSize: j['gridSize'] as int,
        start: Point.fromList(j['start'] as List),
        goal: Point.fromList(j['goal'] as List),
        obstacles: (j['obstacles'] as List? ?? const []).map((e) => Point.fromList(e as List)).toList(),
        par: (j['par'] as int?) ?? 6,
        next: j['next'] is Map<String, dynamic> ? PuzzleRef.fromJson(j['next'] as Map<String, dynamic>) : null,
        variants:
            (j['variants'] as List? ?? const []).map((v) => BoardVariant.fromJson(v as Map<String, dynamic>)).toList(),
      );

  bool isBlocked(Point p) => p.row < 0 || p.col < 0 || p.row >= gridSize || p.col >= gridSize || obstacles.contains(p);
}

class BoardVariant {
  final Point? start;
  final Point? goal;
  final List<Point> obstacles;

  const BoardVariant({this.start, this.goal, this.obstacles = const []});

  factory BoardVariant.fromJson(Map<String, dynamic> j) => BoardVariant(
        start: j['start'] is List ? Point.fromList(j['start'] as List) : null,
        goal: j['goal'] is List ? Point.fromList(j['goal'] as List) : null,
        obstacles: (j['obstacles'] as List? ?? const []).map((e) => Point.fromList(e as List)).toList(),
      );
}

class PuzzleRef {
  final String id;
  final String title;
  const PuzzleRef({required this.id, required this.title});

  factory PuzzleRef.fromJson(Map<String, dynamic> j) =>
      PuzzleRef(id: j['id'] as String, title: (j['title'] as String?) ?? '');
}

/// A puzzle in a category list, with the player's best result.
class PuzzleSummary {
  final String id;
  final String title;
  final int bestStars;

  const PuzzleSummary({required this.id, required this.title, required this.bestStars});

  bool get completed => bestStars > 0;

  factory PuzzleSummary.fromJson(Map<String, dynamic> j) {
    var stars = j['best_stars'] as int?;
    // Older backends only send a list of colours.
    stars ??= (j['stars'] as List? ?? const []).where((s) => s == 'yellow').length;
    return PuzzleSummary(id: j['id'] as String, title: (j['title'] as String?) ?? '', bestStars: stars);
  }
}

/// Stars earned per category, for the home screen.
class CategoryProgress {
  final int total;
  final int completed;
  final int stars;
  final int maxStars;

  const CategoryProgress({this.total = 0, this.completed = 0, this.stars = 0, this.maxStars = 0});

  factory CategoryProgress.fromJson(Map<String, dynamic> j) => CategoryProgress(
        total: j['total'] as int? ?? 0,
        completed: j['completed'] as int? ?? 0,
        stars: j['stars'] as int? ?? 0,
        maxStars: j['max_stars'] as int? ?? 0,
      );
}
