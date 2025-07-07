import 'point.dart';

class Puzzle {
  final String id, title, category;
  final int gridSize;
  final Point start, goal;
  final List<Point> obstacles;
  final List<int> starMoves;

  Puzzle({
    required this.id,
    required this.title,
    required this.gridSize,
    required this.start,
    required this.goal,
    required this.obstacles,
    required this.starMoves,
    required this.category,
  });

  factory Puzzle.fromJson(Map<String, dynamic> j) => Puzzle(
    id: j['id'],
    title: j['title'],
    gridSize: j['gridSize'],
    start: Point.fromList(j['start']),
    goal: Point.fromList(j['goal']),
    obstacles: (j['obstacles'] as List).map((e) => Point.fromList(e)).toList(),
    starMoves: List<int>.from(j['starMoves'] ?? [6, 8, 10]),
    category: j['category'],
  );
}

class CommandItem {
  final String type;
  int repeatCount;
  List<CommandItem> nested;

  CommandItem({
    required this.type,
    this.repeatCount = 1,
    this.nested = const [],
  });
}
