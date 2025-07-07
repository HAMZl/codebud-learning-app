import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../widgets/puzzle_grid.dart';
import '../widgets/success_popup_widget.dart';
import '../widgets/command_block_widget.dart';
import '../widgets/loop_block_widget.dart';

import '../models/puzzle.dart';
import '../models/point.dart';

import '../services/puzzle_service.dart';

import '../utils/icon_mapper.dart';

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
      _loadPuzzle(); // call properly
    } else {
      puzzleId = 'unknown';
      puzzleTitle = 'Unknown';
    }
  }

  Future<void> _loadPuzzle() async {
    setState(() => isLoading = true);
    try {
      final puzzle = await PuzzleService.fetchPuzzle(puzzleId);
      setState(() {
        currentPuzzle = puzzle;
        isLoading = false;
      });
    } catch (e) {
      printToConsole('Error loading puzzle: $e');
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
          final success = await PuzzleService.saveProgress(
            token,
            currentPuzzle!,
            earnedStars,
          );
          if (!success) {
            printToConsole('❌ Failed to save progress');
          }
        } catch (e) {
          printToConsole('❌ Error saving progress: $e');
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
                                icon: IconMapper.getIcon(cmd.type),
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
