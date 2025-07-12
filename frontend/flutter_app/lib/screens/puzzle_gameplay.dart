import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../widgets/puzzle_grid.dart';
import '../widgets/success_popup_widget.dart';
import '../widgets/command_block_widget.dart';
import '../widgets/loop_block_widget.dart';
import '../widgets/conditional_block_widget.dart';

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
  final ScrollController _availMovesCtrl = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      puzzleId = args['id'] ?? 'unknown';
      puzzleTitle = args['title'] ?? 'Untitled Puzzle';
      _loadPuzzle();
    }
  }

  bool _evaluateCondition(String condition, Point pos) {
    final parts = condition.split('_');
    if (parts.length != 2) return false;

    final target = parts[0]; // goal, obstacle, empty
    final direction = parts[1]; // up, down, left, right

    // Determine the forward point based on direction
    Point forward = pos;
    switch (direction) {
      case 'up':
        forward = Point(pos.row - 1, pos.col);
        break;
      case 'down':
        forward = Point(pos.row + 1, pos.col);
        break;
      case 'left':
        forward = Point(pos.row, pos.col - 1);
        break;
      case 'right':
        forward = Point(pos.row, pos.col + 1);
        break;
      default:
        return false; // Invalid direction
    }

    final inBounds =
        forward.row >= 0 &&
        forward.col >= 0 &&
        forward.row < currentPuzzle!.gridSize &&
        forward.col < currentPuzzle!.gridSize;

    final isBlocked = currentPuzzle!.obstacles.contains(forward);
    final isGoalAhead = forward == currentPuzzle!.goal;

    return switch (target) {
      'goal' => isGoalAhead,
      'obstacle' => isBlocked,
      'empty' => inBounds && !isBlocked && !isGoalAhead,
      _ => false, // Invalid target
    };
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
      print('Error loading puzzle: $e');
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
        } else if (cmd.type == 'If') {
          final condition = cmd.condition ?? '';
          final shouldExecute = _evaluateCondition(condition, pos);
          if (shouldExecute) {
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
        await PuzzleService.saveProgress(token, currentPuzzle!, earnedStars);
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

    final blocks = <Widget>[];
    if (currentPuzzle?.category.toLowerCase() == 'loop') {
      blocks.insert(
        0,
        Draggable<String>(
          data: 'Loop',
          feedback: CommandBlock(icon: Icons.loop, label: 'Loop'),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: CommandBlock(icon: Icons.loop, label: 'Loop'),
          ),
          child: CommandBlock(icon: Icons.loop, label: 'Loop'),
        ),
      );
    }

    if (currentPuzzle!.category.toLowerCase() == 'conditional') {
      blocks.add(
        Draggable<String>(
          data: 'If',
          feedback: CommandBlock(icon: Icons.help_outline, label: 'If'),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: CommandBlock(icon: Icons.help_outline, label: 'If'),
          ),
          child: CommandBlock(icon: Icons.help_outline, label: 'If'),
        ),
      );
    }

    const moveMap = {
      'Up': {'icon': Icons.arrow_upward, 'label': 'Up'},
      'Down': {'icon': Icons.arrow_downward, 'label': 'Down'},
      'Left': {'icon': Icons.arrow_back, 'label': 'Left'},
      'Right': {'icon': Icons.arrow_forward, 'label': 'Right'},
    };

    blocks.addAll(
      moveMap.entries.map((entry) {
        return Draggable<String>(
          data: entry.key,
          feedback: CommandBlock(
            icon: entry.value['icon'] as IconData,
            label: entry.value['label'] as String,
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: CommandBlock(
              icon: entry.value['icon'] as IconData,
              label: entry.value['label'] as String,
            ),
          ),
          child: CommandBlock(
            icon: entry.value['icon'] as IconData,
            label: entry.value['label'] as String,
          ),
        );
      }),
    );
    return blocks;
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA726),
        foregroundColor: Colors.white,
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
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  _buildAvailableMoves(),
                  const SizedBox(height: 12),
                  _buildCommandSequence(),
                  const SizedBox(height: 12),
                  _buildControlButtons(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  Widget _buildAvailableMoves() => Container(
    width: double.infinity,
    height: 100, // Reduced height
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(12), // Reduced padding
    decoration: _cardDecoration(const Color(0xFFFFA726)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Moves:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ), // Slightly smaller text
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Scrollbar(
            controller: _availMovesCtrl,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _availMovesCtrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: _buildDraggableBlocks()
                    .map(
                      (chip) => Padding(
                        padding: const EdgeInsets.only(
                          right: 12,
                        ), // Reduced spacing
                        child: chip,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  final ScrollController _commandScrollCtrl =
      ScrollController(); // add this in your state

  @override
  void dispose() {
    _availMovesCtrl.dispose();
    _commandScrollCtrl.dispose(); // dispose this too
    super.dispose();
  }

  Widget _buildCommandSequence() => Container(
    width: double.infinity,
    height: 134, // Reduced height
    margin: const EdgeInsets.symmetric(horizontal: 16), // Reduced margin
    padding: const EdgeInsets.all(12), // Reduced padding
    decoration: _cardDecoration(const Color(0xFFFFA726)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Move Sequence:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ), // Smaller text
        ),
        const SizedBox(height: 8), // Less vertical space
        SizedBox(
          height: 74, // Reduced from 90
          child: DragTarget<String>(
            onAccept: (data) {
              setState(() {
                if (data == 'Loop') {
                  commandSequence.add(
                    CommandItem(type: 'Loop', repeatCount: 2, nested: []),
                  );
                } else if (data == 'If' &&
                    currentPuzzle!.category.toLowerCase() == 'conditional') {
                  commandSequence.add(
                    CommandItem(type: 'If', condition: 'goal_up', nested: []),
                  );
                } else {
                  commandSequence.add(CommandItem(type: data));
                }
              });

              Future.delayed(const Duration(milliseconds: 300), () {
                if (_commandScrollCtrl.hasClients) {
                  _commandScrollCtrl.animateTo(
                    _commandScrollCtrl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            },
            builder: (context, _, __) => Scrollbar(
              controller: _commandScrollCtrl,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _commandScrollCtrl,
                scrollDirection: Axis.horizontal,
                itemCount: commandSequence.length,
                itemBuilder: (context, index) {
                  final cmd = commandSequence[index];
                  if (cmd.type == 'Loop') {
                    return LoopBlockWidget(
                      loopCommand: cmd,
                      isSelected: selectedCommand == cmd,
                      onSelect: () => setState(() => selectedCommand = cmd),
                      onUpdate: () => setState(() {}),
                    );
                  }

                  if (cmd.type == 'If') {
                    return ConditionalBlockWidget(
                      conditionalCommand: cmd,
                      isSelected: selectedCommand == cmd,
                      onSelect: () => setState(() => selectedCommand = cmd),
                    );
                  }

                  final iconData = IconMapper.getIconAndLabel(cmd.type);
                  return GestureDetector(
                    onTap: () => setState(() => selectedCommand = cmd),
                    child: CommandBlock(
                      icon: iconData['icon'],
                      label: iconData['label'],
                      isSelected: selectedCommand == cmd,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildControlButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ElevatedButton(
        onPressed: commandSequence.isEmpty ? null : playCommands,
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
        onPressed: commandSequence.isEmpty ? null : resetSequence,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: const Text("Reset"),
      ),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: selectedCommand == null ? null : deleteSelected,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        child: const Text("Delete"),
      ),
    ],
  );
}
