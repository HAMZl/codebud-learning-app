import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/puzzle_grid.dart'; // ✅ Reuse Point + PuzzleGrid

// -------- Puzzle Data Model (Minimal) --------
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

// -------- Puzzle Screen Widget --------
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late final String puzzleId;
  late final String puzzleTitle;
  Puzzle? currentPuzzle;
  bool isLoading = true;
  List<String> commandSequence = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$puzzleTitle'),
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
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _buildDraggableBlocks(),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Command Sequence:",
                    style: TextStyle(fontSize: 18),
                  ),
                  Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.all(8),
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: CommandBlock(label: emoji),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      print("Playing sequence for $puzzleId: $commandSequence");
                      // TODO: Add animation or backend update here
                    },
                    child: const Text("Play"),
                  ),
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

// -------- Command Block Widget --------
class CommandBlock extends StatelessWidget {
  final String label;

  const CommandBlock({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 26))),
    );
  }
}
