import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../widgets/puzzle_grid.dart';

class Puzzle {
  final String id;
  final String title;
  final int gridSize;
  final Point start;
  final Point goal;
  final List<Point> obstacles;

  Puzzle({
    required this.id,
    required this.title,
    required this.gridSize,
    required this.start,
    required this.goal,
    required this.obstacles,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
    id: json['id'],
    title: json['title'],
    gridSize: json['gridSize'],
    start: Point.fromList(json['start']),
    goal: Point.fromList(json['goal']),
    obstacles: List<List<dynamic>>.from(
      json['obstacles'],
    ).map((e) => Point.fromList(e)).toList(),
  );
}

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late String puzzleId;
  late String puzzleTitle;
  Puzzle? currentPuzzle;
  bool isLoading = true;
  List<String> commandSequence = [];
  int? selectedIndex;
  final GlobalKey<PuzzleGridState> gridKey = GlobalKey<PuzzleGridState>();
  final storage = FlutterSecureStorage();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      puzzleId = args['id'] ?? 'unknown';
      puzzleTitle = args['title'] ?? 'Untitled Puzzle';
      fetchPuzzle(puzzleId);
    } else {
      puzzleId = 'unknown';
      puzzleTitle = 'Unknown';
    }
  }

  Future<void> fetchPuzzle(String id) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/puzzle/$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentPuzzle = Puzzle.fromJson(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load puzzle');
      }
    } catch (e) {
      print('Error fetching puzzle: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> playCommands() async {
    if (currentPuzzle == null || gridKey.currentState == null) return;

    Point pos = currentPuzzle!.start;

    for (String move in commandSequence) {
      await Future.delayed(const Duration(milliseconds: 500));

      Point next = switch (move) {
        'Up' => Point(pos.row - 1, pos.col),
        'Down' => Point(pos.row + 1, pos.col),
        'Left' => Point(pos.row, pos.col - 1),
        'Right' => Point(pos.row, pos.col + 1),
        _ => pos,
      };

      final inBounds =
          next.row >= 0 &&
          next.col >= 0 &&
          next.row < currentPuzzle!.gridSize &&
          next.col < currentPuzzle!.gridSize;

      final isBlocked = currentPuzzle!.obstacles.contains(next);

      if (inBounds && !isBlocked) {
        pos = next;
        gridKey.currentState?.updateRobot(pos);
      }
    }

    if (pos == currentPuzzle!.goal) {
      // 🔐 Save puzzle progress via API
      final token = await storage.read(key: 'jwt_token');
      if (token != null) {
        try {
          final response = await http.post(
            Uri.parse('http://127.0.0.1:5000/api/progress'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'puzzle_id': currentPuzzle!.id,
              'status': 'completed',
              'stars': 3,
              'updated_at': DateTime.now().toIso8601String(),
            }),
          );

          if (response.statusCode != 200) {
            print('❌ Failed to save progress: ${response.body}');
          } else {
            print('✅ Progress saved successfully.');
          }
        } catch (e) {
          print('❌ Error saving progress: $e');
        }
      } else {
        print('❗ JWT token not found.');
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Success!"),
          content: const Text("CodeBud reached the goal! 🎉"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void resetSequence() {
    setState(() {
      commandSequence.clear();
      selectedIndex = null;
    });
  }

  void deleteSelected() {
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < commandSequence.length) {
      setState(() {
        commandSequence.removeAt(selectedIndex!);
        selectedIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(puzzleTitle),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentPuzzle == null
          ? const Center(child: Text("Failed to load puzzle."))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  PuzzleGrid(
                    key: gridKey,
                    gridSize: currentPuzzle!.gridSize,
                    start: currentPuzzle!.start,
                    goal: currentPuzzle!.goal,
                    obstacles: currentPuzzle!.obstacles,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Available Moves:",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: _buildDraggableBlocks(),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Command Sequence:",
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(
                    height: 80,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DragTarget<String>(
                        onAccept: (data) {
                          setState(() {
                            commandSequence.add(data);
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: commandSequence.length,
                            itemBuilder: (context, index) {
                              final move = commandSequence[index];
                              final emoji = switch (move) {
                                'Up' => '🔼',
                                'Down' => '🔽',
                                'Left' => '◀️',
                                'Right' => '▶️',
                                _ => '❓',
                              };
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                },
                                child: CommandBlock(
                                  label: emoji,
                                  isSelected: selectedIndex == index,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: commandSequence.isEmpty
                            ? null
                            : playCommands,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: commandSequence.isEmpty
                              ? Colors.grey
                              : Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Play"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: commandSequence.isEmpty
                            ? null
                            : resetSequence,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Reset"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: selectedIndex == null
                            ? null
                            : deleteSelected,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildDraggableBlocks() {
    const moves = {'Up': '🔼', 'Down': '🔽', 'Left': '◀️', 'Right': '▶️'};

    return moves.entries.map((entry) {
      return Draggable<String>(
        data: entry.key,
        feedback: CommandBlock(label: entry.value),
        childWhenDragging: Opacity(
          opacity: 0.4,
          child: CommandBlock(label: entry.value),
        ),
        child: CommandBlock(label: entry.value),
      );
    }).toList();
  }
}

class CommandBlock extends StatelessWidget {
  final String label;
  final bool isSelected;

  const CommandBlock({super.key, required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.black,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 25))),
    );
  }
}
