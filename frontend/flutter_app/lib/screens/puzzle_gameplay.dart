import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../widgets/puzzle_grid.dart';
import '../widgets/success_popup_widget.dart';

class Puzzle {
  final String id;
  final String title;
  final int gridSize;
  final Point start;
  final Point goal;
  final List<Point> obstacles;
  final List<int> starMoves;
  final String category;

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

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
    id: json['id'],
    title: json['title'],
    gridSize: json['gridSize'],
    start: Point.fromList(json['start']),
    goal: Point.fromList(json['goal']),
    obstacles: List<List<dynamic>>.from(
      json['obstacles'],
    ).map((e) => Point.fromList(e)).toList(),
    starMoves: List<int>.from(json['starMoves'] ?? [6, 8, 10]),
    category: json['category'],
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
  List<CommandItem> commandSequence = [];
  CommandItem? selectedCommand;
  final GlobalKey<PuzzleGridState> gridKey = GlobalKey<PuzzleGridState>();
  final storage = FlutterSecureStorage();
  int moveCounter = 0;

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
    moveCounter = 0;

    Future<void> execute(List<CommandItem> cmds) async {
      for (final cmd in cmds) {
        if (cmd.type == 'Loop') {
          for (int i = 0; i < cmd.repeatCount; i++) {
            await execute(cmd.nested);
          }
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
          Point next = switch (cmd.type) {
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
            setState(() {
              moveCounter++;
            });
            gridKey.currentState?.updateRobot(pos);
          }
        }
      }
    }

    await execute(commandSequence);

    if (pos == currentPuzzle!.goal) {
      int earnedStars = 0;
      final sortedStarMoves = List<int>.from(currentPuzzle!.starMoves)..sort();
      for (int i = 0; i < sortedStarMoves.length; i++) {
        if (moveCounter <= sortedStarMoves[i]) {
          earnedStars = 3 - i;
          break;
        }
      }

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
              'stars': earnedStars,
              'status': 'completed',
              'updated_at': DateTime.now().toIso8601String(),
            }),
          );
          if (response.statusCode != 200) {
            print('❌ Failed to save progress: ${response.body}');
          }
        } catch (e) {
          print('❌ Error saving progress: $e');
        }
      }

      final match = RegExp(r'^([a-zA-Z]+)(\d+)$').firstMatch(currentPuzzle!.id);
      String nextPuzzleId = currentPuzzle!.id;
      String nextPuzzleTitle = puzzleTitle;
      if (match != null) {
        String prefix = match.group(1)!;
        int number = int.parse(match.group(2)!);
        nextPuzzleId = '$prefix${number + 1}';
        nextPuzzleTitle = 'Level ${number + 1}';
      }

      final checkUri = Uri.parse(
        'http://127.0.0.1:5000/api/puzzle/$nextPuzzleId',
      );
      final checkResponse = await http.get(checkUri);
      bool nextPuzzleExists = checkResponse.statusCode == 200;

      showDialog(
        context: context,
        builder: (context) => SuccessPopup(
          level: puzzleTitle,
          earnedStars: earnedStars,
          onRetry: () {
            Navigator.pushNamed(
              context,
              '/puzzle',
              arguments: {
                'id': puzzleId,
                'title': puzzleTitle,
                'category': currentPuzzle!.category,
              },
            );
          },
          onNext: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(
              context,
              '/puzzle',
              arguments: {
                'id': nextPuzzleId,
                'title': nextPuzzleTitle,
                'category': currentPuzzle!.category,
              },
            );
          },
          onCategorySelect: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(
              context,
              '/${currentPuzzle!.category}s',
            );
          },
          showNextButton: nextPuzzleExists,
        ),
      );
    }
  }

  void resetSequence() {
    setState(() {
      commandSequence.clear();
      selectedCommand = null;
      moveCounter = 0;
      gridKey.currentState?.updateRobot(currentPuzzle!.start);
    });
  }

  void deleteSelected() {
    if (selectedCommand == null) return;
    setState(() {
      commandSequence.remove(selectedCommand);
      selectedCommand = null;
    });
  }

  IconData _iconFor(String move) {
    switch (move) {
      case 'Up':
        return Icons.arrow_upward;
      case 'Down':
        return Icons.arrow_downward;
      case 'Left':
        return Icons.arrow_back;
      case 'Right':
        return Icons.arrow_forward;
      case 'Loop':
        return Icons.loop;
      default:
        return Icons.help;
    }
  }

  List<Widget> _buildDraggableBlocks() {
    if (currentPuzzle == null) return [];

    const moves = {
      'Up': Icons.arrow_upward,
      'Down': Icons.arrow_downward,
      'Left': Icons.arrow_back,
      'Right': Icons.arrow_forward,
    };
    final blocks = moves.entries.map((entry) {
      return Draggable<String>(
        data: entry.key,
        feedback: CommandBlock(icon: entry.value),
        childWhenDragging: Opacity(
          opacity: 0.4,
          child: CommandBlock(icon: entry.value),
        ),
        child: CommandBlock(icon: entry.value),
      );
    }).toList();

    if (currentPuzzle!.category.toLowerCase() == 'loop') {
      blocks.add(
        Draggable<String>(
          data: 'Loop',
          feedback: CommandBlock(icon: Icons.loop),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: CommandBlock(icon: Icons.loop),
          ),
          child: CommandBlock(icon: Icons.loop),
        ),
      );
    }

    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              '/${currentPuzzle!.category}s',
            );
          },
        ),
        title: Text(puzzleTitle),
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
                    starMoves: currentPuzzle!.starMoves,
                    category: currentPuzzle!.category,
                    moveCount: moveCounter,
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
                  Container(
                    height: 120,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
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
                          if (data == 'Loop') {
                            commandSequence.add(
                              CommandItem(
                                type: 'Loop',
                                repeatCount: 2,
                                nested: [],
                              ),
                            );
                          } else {
                            commandSequence.add(CommandItem(type: data));
                          }
                        });
                      },
                      builder: (context, candidateData, rejectedData) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: commandSequence.length,
                          itemBuilder: (context, index) {
                            final cmd = commandSequence[index];
                            if (cmd.type == 'Loop') {
                              return LoopBlockWidget(
                                loopCommand: cmd,
                                isSelected: selectedCommand == cmd,
                                onSelect: () =>
                                    setState(() => selectedCommand = cmd),
                                onUpdate: () => setState(() {}),
                              );
                            }
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedCommand = cmd),
                              child: CommandBlock(
                                icon: _iconFor(cmd.type),
                                isSelected: selectedCommand == cmd,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
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
                        onPressed: selectedCommand == null
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
}

class CommandBlock extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  const CommandBlock({super.key, required this.icon, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.black,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: Center(child: Icon(icon, size: 32)),
    );
  }
}

class LoopBlockWidget extends StatelessWidget {
  final CommandItem loopCommand;
  final VoidCallback onUpdate;
  final VoidCallback onSelect;
  final bool isSelected;

  const LoopBlockWidget({
    super.key,
    required this.loopCommand,
    required this.onUpdate,
    required this.onSelect,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.purple,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.purpleAccent.withOpacity(0.2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.loop),
                Text(' x${loopCommand.repeatCount}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    loopCommand.repeatCount++;
                    onUpdate();
                  },
                ),
              ],
            ),
            Container(
              height: 60,
              width: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DragTarget<String>(
                onAccept: (data) {
                  loopCommand.nested.add(CommandItem(type: data));
                  onUpdate();
                },
                builder: (context, candidateData, rejectedData) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: loopCommand.nested
                          .map(
                            (cmd) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: GestureDetector(
                                onTap: () => onSelect(),
                                child: CommandBlock(
                                  icon: IconsMap[cmd.type] ?? Icons.help,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, IconData> IconsMap = {
    'Up': Icons.arrow_upward,
    'Down': Icons.arrow_downward,
    'Left': Icons.arrow_back,
    'Right': Icons.arrow_forward,
    'Loop': Icons.loop,
  };
}
