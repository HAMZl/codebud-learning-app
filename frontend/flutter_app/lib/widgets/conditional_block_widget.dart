import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import 'command_block_widget.dart';
import '../utils/icon_mapper.dart';

class ConditionalBlockWidget extends StatelessWidget {
  final CommandItem conditionalCommand;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onUpdate;

  const ConditionalBlockWidget({
    super.key,
    required this.conditionalCommand,
    required this.isSelected,
    required this.onSelect,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    const availableConditions = ['goalAhead', 'obstacleAhead', 'emptyAhead'];

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.green,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.lightGreenAccent.withOpacity(0.2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.question_mark),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: conditionalCommand.condition,
                  items: availableConditions
                      .map(
                        (condition) => DropdownMenuItem<String>(
                          value: condition,
                          child: Text(condition),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      conditionalCommand.condition = value;
                      onUpdate();
                    }
                  },
                ),
              ],
            ),
            Container(
              height: 40,
              width: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DragTarget<String>(
                onAccept: (data) {
                  conditionalCommand.nested.add(CommandItem(type: data));
                  onUpdate();
                },
                builder: (context, candidateData, rejectedData) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: conditionalCommand.nested
                          .map(
                            (cmd) => GestureDetector(
                              onTap: onSelect,
                              child: CommandBlock(
                                icon: IconMapper.getIcon(cmd.type),
                                label: cmd.type,
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
