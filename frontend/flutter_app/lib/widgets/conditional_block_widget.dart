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
  late String target;
  late String direction;

  final availableTargets = ['goal', 'obstacle', 'empty'];
  final availableDirections = ['up', 'down', 'left', 'right'];

  @override
  void initState() {
    super.initState();
    final parts = (widget.conditionalCommand.condition ?? 'goal_up').split('_');
    target = parts[0];
    direction = parts.length > 1 ? parts[1] : 'up';
  }

  void _updateCommandCondition() {
    widget.conditionalCommand.condition = '${target}_$direction';
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
            color: widget.isSelected ? Colors.blue : Colors.green,
            width: widget.isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.lightGreenAccent.withAlpha((0.2 * 255).round()),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.question_mark, size: 24),
            const SizedBox(width: 4),

            // Dropdown column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 28,
                  width: 80,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: target,
                    style: const TextStyle(fontSize: 12),
                    items: availableTargets
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          target = val;
                          _updateCommandCondition();
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  height: 28,
                  width: 80,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: direction,
                    style: const TextStyle(fontSize: 12),
                    items: availableDirections
                        .map(
                          (dir) => DropdownMenuItem(
                            value: dir,
                            child: Text(dir, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          direction = val;
                          _updateCommandCondition();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Command sequence (DragTarget)
            Container(
              height: 80,
              width: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
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
