import 'package:flutter/material.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  List<String> commandSequence = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeBud Puzzle'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          Container(
            height: 250,
            width: 250,
            margin: const EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26, width: 2),
              color: Colors.grey[200],
            ),
            child: const Center(
              child: Text(
                'Puzzle Grid Placeholder',
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const Text("Available Moves:", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              Draggable<String>(
                data: 'Up',
                feedback: const CommandBlock(label: '🔼'),
                childWhenDragging: Opacity(
                  opacity: 0.4,
                  child: const CommandBlock(label: '🔼'),
                ),
                child: const CommandBlock(label: '🔼'),
              ),
              Draggable<String>(
                data: 'Down',
                feedback: const CommandBlock(label: '🔽'),
                childWhenDragging: Opacity(
                  opacity: 0.4,
                  child: const CommandBlock(label: '🔽'),
                ),
                child: const CommandBlock(label: '🔽'),
              ),
              Draggable<String>(
                data: 'Left',
                feedback: const CommandBlock(label: '◀️'),
                childWhenDragging: Opacity(
                  opacity: 0.4,
                  child: const CommandBlock(label: '◀️'),
                ),
                child: const CommandBlock(label: '◀️'),
              ),
              Draggable<String>(
                data: 'Right',
                feedback: const CommandBlock(label: '▶️'),
                childWhenDragging: Opacity(
                  opacity: 0.4,
                  child: const CommandBlock(label: '▶️'),
                ),
                child: const CommandBlock(label: '▶️'),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // 🎯 Drop zone for commands
          const Text("Command Sequence:", style: TextStyle(fontSize: 18)),
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DragTarget<String>(
              onAccept: (data) {
                setState(() {
                  commandSequence.add(data);
                });
              },
              builder: (context, candidateData, rejectedData) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: commandSequence.length,
                  itemBuilder: (context, index) {
                    String move = commandSequence[index];
                    String emoji = switch (move) {
                      'Up' => '🔼',
                      'Down' => '🔽',
                      'Left' => '◀️',
                      'Right' => '▶️',
                      _ => '❓',
                    };
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: CommandBlock(label: emoji),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ▶️ Play button
          ElevatedButton(
            onPressed: () {
              print("Playing sequence: $commandSequence");
              // Future: Trigger movement or animation
            },
            child: const Text("Play"),
          ),
        ],
      ),
    );
  }
}

// 🔲 Reusable Command Block Widget
class CommandBlock extends StatelessWidget {
  final String label;

  const CommandBlock({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 26))),
    );
  }
}
