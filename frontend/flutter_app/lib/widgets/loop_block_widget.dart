import 'package:flutter/material.dart';
import 'command_block_widget.dart';
import '../models/puzzle.dart';
import '../utils/icon_mapper.dart';

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
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.green,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.lightGreenAccent.withAlpha((0.2 * 255).round()),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Loop icon + +/- buttons
            Column(
              children: [
                const Icon(Icons.loop, size: 16),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove,
                        size: 12,
                        color: loopCommand.repeatCount > 2
                            ? Colors.black
                            : Colors.grey,
                      ),
                      onPressed: loopCommand.repeatCount > 2
                          ? () {
                              loopCommand.repeatCount--;
                              onUpdate();
                            }
                          : null,
                    ),
                    Text('${loopCommand.repeatCount}'),
                    IconButton(
                      icon: const Icon(Icons.add, size: 12),
                      onPressed: () {
                        loopCommand.repeatCount++;
                        onUpdate();
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 0),

            // Right: Scrollable nested command sequence
            Container(
              height: 68,
              width: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DragTarget<String>(
                onAccept: (data) {
                  loopCommand.nested.add(CommandItem(type: data));
                  onUpdate();
                },
                builder: (context, candidateData, rejectedData) {
                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: loopCommand.nested.map((cmd) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: onSelect,
                              child: CommandBlock(
                                icon: IconMapper.getIcon(cmd.type),
                                label: cmd.type,
                                isSelected: isSelected,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
