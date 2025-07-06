import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../widgets/puzzle_grid.dart';
import '../widgets/success_popup_widget.dart';

// ────────── Data model ──────────
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
        obstacles:
            (j['obstacles'] as List).map((e) => Point.fromList(e)).toList(),
        starMoves: List<int>.from(j['starMoves'] ?? [6, 8, 10]),
        category: j['category'],
      );
}

// ────────── Screen ──────────
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late String puzzleId, puzzleTitle;

  Puzzle? currentPuzzle;
  bool isLoading = true;

  final List<String> commandSequence = [];
  int? selectedIndex;

  final gridKey = GlobalKey<PuzzleGridState>();
  final storage = FlutterSecureStorage();

  final _availMovesCtrl = ScrollController();

  String _arrowLabel(String move) => switch (move) {
        'Up' => '↑ Up',
        'Down' => '↓ Down',
        'Left' => '← Left',
        'Right' => '→ Right',
        _ => move,
      };

  @override
  void dispose() {
    _availMovesCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    puzzleId = args?['id'] ?? 'unknown';
    puzzleTitle = args?['title'] ?? 'Untitled Puzzle';
    fetchPuzzle(puzzleId);
  }

  Future<void> fetchPuzzle(String id) async {
    try {
      final res =
          await http.get(Uri.parse('http://127.0.0.1:5000/api/puzzle/$id'));
      if (res.statusCode == 200) {
        setState(() {
          currentPuzzle = Puzzle.fromJson(json.decode(res.body));
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  // playCommands / _saveProgress / _showSuccessPopup left unchanged …

  void resetSequence() {
    setState(() {
      commandSequence.clear();
      selectedIndex = null;
      gridKey.currentState?.updateRobot(currentPuzzle!.start);
    });
  }

  void deleteSelected() {
    if (selectedIndex != null && selectedIndex! < commandSequence.length) {
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
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(puzzleTitle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                    starMoves: currentPuzzle!.starMoves,
                    category: currentPuzzle!.category,
                  ),
                  const SizedBox(height: 20),

                  // Available Moves
                  _buildAvailableMoves(),

                  const SizedBox(height: 10),

                  // Move Sequence
                  _buildMoveSequence(),

                  const SizedBox(height: 10),

                  // Controls
                  _buildControls(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ────────── UI helpers ──────────
  Widget _buildAvailableMoves() => Container(
        width: double.infinity,
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(Colors.deepPurple),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available Moves:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: Scrollbar(
                controller: _availMovesCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _availMovesCtrl,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: _buildDraggableBlocks()
                        .map((chip) => Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: chip,
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildMoveSequence() => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(Colors.deepPurple),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Move Sequence : ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 90,
              child: DragTarget<String>(
                onWillAccept: (_) => true,
                onAccept: (d) => setState(() => commandSequence.add(d)),
                builder: (context, _, __) => commandSequence.isEmpty
                    ? const Center(
                        child: Text(
                          'Drag and Drop Available Moves  to add to sequence.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: commandSequence.length,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => setState(() => selectedIndex = i),
                          child: CommandBlock(
                            label: _arrowLabel(commandSequence[i]),
                            isSelected: selectedIndex == i,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      );

  Widget _buildControls() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: commandSequence.isEmpty ? null : () {},
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    commandSequence.isEmpty ? Colors.grey : Colors.orange),
            child: const Text('Play'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: commandSequence.isEmpty ? null : resetSequence,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: selectedIndex == null ? null : deleteSelected,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            child: const Text('Delete'),
          ),
        ],
      );

  BoxDecoration _cardDecoration(Color borderColor) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      );

  List<Widget> _buildDraggableBlocks() {
    const moves = {
      'Up': '↑ Up',
      'Down': '↓ Down',
      'Left': '← Left',
      'Right': '→ Right',
    };
    return moves.entries
        .map((e) => Draggable<String>(
              data: e.key,
              feedback: CommandBlock(label: e.value),
              childWhenDragging:
                  Opacity(opacity: 0.4, child: CommandBlock(label: e.value)),
              child: CommandBlock(label: e.value),
            ))
        .toList();
  }
}

// ────────── CommandBlock ──────────
class CommandBlock extends StatelessWidget {
  final String label;
  final bool isSelected;
  const CommandBlock({super.key, required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final arrow = RegExp(r'[↑↓→←]').stringMatch(label) ?? '';
    final direction = label.replaceAll(RegExp(r'[↑↓→←]'), '').trim();
    return Container(
      width: 90,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withOpacity(0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.purpleAccent,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: Center(
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '$arrow ',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            TextSpan(
              text: direction,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ]),
        ),
      ),
    );
  }
}
