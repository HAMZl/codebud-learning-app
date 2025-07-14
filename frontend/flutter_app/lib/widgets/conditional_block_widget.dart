import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import 'command_block_widget.dart';
import '../utils/icon_mapper.dart';

class ConditionalBlockWidget extends StatefulWidget {
  final CommandItem conditionalCommand;
  final bool isSelected;
  final VoidCallback onSelect;

  const ConditionalBlockWidget({
    super.key,
    required this.conditionalCommand,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<ConditionalBlockWidget> createState() => _ConditionalBlockWidgetState();
}

class _ConditionalBlockWidgetState extends State<ConditionalBlockWidget> {
  late String localTarget;
  late String localDirection;

  final availableTargets = ['goal', 'obstacle', 'empty'];
  final availableDirections = ['up', 'down', 'left', 'right'];

  @override
  void initState() {
    super.initState();
    final parts = (widget.conditionalCommand.condition ?? 'goal_up').split('_');
    localTarget = parts[0];
    localDirection = parts.length > 1 ? parts[1] : 'up';
  }

  void _updateLocalTarget(String? newTarget) {
    if (newTarget == null) return;
    setState(() {
      localTarget = newTarget;
      // Do NOT update parent command immediately
    });
  }

  void _updateLocalDirection(String? newDir) {
    if (newDir == null) return;
    setState(() {
      localDirection = newDir;
      // Do NOT update parent command immediately
    });
  }

  @override
  void dispose() {
    // Sync the condition back once user leaves widget (optional)
    widget.conditionalCommand.condition = '${localTarget}_$localDirection';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSelect,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isSelected ? Colors.blue : Colors.orange,
            width: widget.isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.orange.shade100,
        ),
        child: Row(
          children: [
            const Icon(Icons.question_mark, size: 16),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 28,
                  width: 60,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: localTarget,
                    style: const TextStyle(fontSize: 12),
                    items: availableTargets
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: _updateLocalTarget,
                  ),
                ),
                SizedBox(
                  height: 28,
                  width: 60,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: localDirection,
                    style: const TextStyle(fontSize: 12),
                    items: availableDirections
                        .map(
                          (dir) =>
                              DropdownMenuItem(value: dir, child: Text(dir)),
                        )
                        .toList(),
                    onChanged: _updateLocalDirection,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              height: 68,
              width: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DragTarget<String>(
                onAccept: (data) {
                  setState(() {
                    widget.conditionalCommand.nested.add(
                      CommandItem(type: data),
                    );
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: widget.conditionalCommand.nested
                          .map(
                            (cmd) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: GestureDetector(
                                onTap: widget.onSelect,
                                child: CommandBlock(
                                  icon: IconMapper.getIcon(cmd.type),
                                  label: IconMapper.getLabel(cmd.type),
                                  isSelected: widget.isSelected,
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
}
