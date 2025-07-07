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
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.purple,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.purpleAccent.withAlpha((0.2 * 255).round()),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.loop),
                IconButton(
                  icon: Icon(
                    Icons.remove,
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
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    loopCommand.repeatCount++;
                    onUpdate();
                  },
                ),
              ],
            ),
            Container(
              height: 40,
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
                                horizontal: 0,
                              ),
                              child: GestureDetector(
                                onTap: onSelect,
                                child: CommandBlock(
                                  icon: IconMapper.getIcon(cmd.type),
                                  label: cmd.type,
                                  isSelected: isSelected,
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
