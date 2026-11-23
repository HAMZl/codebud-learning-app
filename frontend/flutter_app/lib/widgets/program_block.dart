import 'package:flutter/material.dart';

import '../models/command.dart';
import '../theme/app_theme.dart';
import 'command_block_widget.dart';

/// Renders any block in the program, recursing into Loop and If bodies.
class ProgramBlock extends StatelessWidget {
  const ProgramBlock({
    super.key,
    required this.item,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
    this.enabled = true,
  });

  final CommandItem item;
  final CommandItem? selected;
  final ValueChanged<CommandItem> onSelect;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isSelected = identical(selected, item);
    return switch (item.type) {
      BlockType.loop => _ContainerBlock(
          item: item,
          isSelected: isSelected,
          color: AppColors.loop,
          controls: _LoopControls(item: item, onChanged: onChanged, enabled: enabled),
          child: this,
        ),
      BlockType.ifBlock => _ContainerBlock(
          item: item,
          isSelected: isSelected,
          color: AppColors.condition,
          controls: _ConditionControls(item: item, onChanged: onChanged, enabled: enabled),
          child: this,
        ),
      _ => GestureDetector(
          onTap: enabled ? () => onSelect(item) : null,
          child: CommandBlock(type: item.type, isSelected: isSelected),
        ),
    };
  }
}

/// The shared look of Loop and If: controls on the left, a drop zone for the body on the right.
class _ContainerBlock extends StatelessWidget {
  const _ContainerBlock({
    required this.item,
    required this.isSelected,
    required this.color,
    required this.controls,
    required this.child,
  });

  final CommandItem item;
  final bool isSelected;
  final Color color;
  final Widget controls;
  final ProgramBlock child; // gives access to the callbacks without repeating them

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: child.enabled ? () => child.onSelect(item) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.selected : color, width: isSelected ? 3 : 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            controls,
            const SizedBox(width: 4),
            DragTarget<String>(
              onWillAcceptWithDetails: (d) => child.enabled && item.accepts(d.data),
              onAcceptWithDetails: (d) {
                item.body.add(CommandItem(type: d.data));
                child.onChanged();
              },
              builder: (context, candidates, _) => Container(
                constraints: const BoxConstraints(minWidth: 64, minHeight: 62),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: candidates.isNotEmpty ? color.withValues(alpha: 0.25) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color),
                ),
                child: item.body.isEmpty
                    ? Icon(Icons.add, color: color.withValues(alpha: 0.6))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final b in item.body)
                            ProgramBlock(
                              item: b,
                              selected: child.selected,
                              onSelect: child.onSelect,
                              onChanged: child.onChanged,
                              enabled: child.enabled,
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoopControls extends StatelessWidget {
  const _LoopControls({required this.item, required this.onChanged, required this.enabled});

  final CommandItem item;
  final VoidCallback onChanged;
  final bool enabled;

  void _change(int delta) {
    item.repeat = (item.repeat + delta).clamp(CommandItem.minRepeat, CommandItem.maxRepeat);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(
          icon: Icons.add,
          onTap: enabled && item.repeat < CommandItem.maxRepeat ? () => _change(1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.loop, size: 16, color: AppColors.loop),
              Text('${item.repeat}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        _RoundButton(
          icon: Icons.remove,
          onTap: enabled && item.repeat > CommandItem.minRepeat ? () => _change(-1) : null,
        ),
      ],
    );
  }
}

/// The If condition, shown as icons: tap the first to change what to look for
/// (rock / empty / star) and the second to change the direction.
class _ConditionControls extends StatelessWidget {
  const _ConditionControls({required this.item, required this.onChanged, required this.enabled});

  final CommandItem item;
  final VoidCallback onChanged;
  final bool enabled;

  static String _cycle(List<String> options, String current) =>
      options[(options.indexOf(current) + 1) % options.length];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(
          icon: Condition.targetIcon(item.target),
          tooltip: 'Look for: ${item.target}',
          onTap: enabled
              ? () {
                  item.target = _cycle(Condition.targets, item.target);
                  onChanged();
                }
              : null,
        ),
        const SizedBox(height: 4),
        _RoundButton(
          icon: Condition.directionIcon(item.direction),
          tooltip: 'Look: ${item.direction}',
          onTap: enabled
              ? () {
                  item.direction = _cycle(Condition.directions, item.direction);
                  onChanged();
                }
              : null,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap == null ? Colors.grey.shade200 : Colors.white,
          border: Border.all(color: Colors.black26),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.grey : Colors.black87),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
