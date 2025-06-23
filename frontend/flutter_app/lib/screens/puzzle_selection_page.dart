import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/puzzle_button.dart';

class PuzzleSelectionPage extends StatefulWidget {
  final String title;
  final String category;

  const PuzzleSelectionPage({
    super.key,
    required this.title,
    required this.category,
  });

  @override
  State<PuzzleSelectionPage> createState() => _PuzzleSelectionPageState();
}

class _PuzzleSelectionPageState extends State<PuzzleSelectionPage> {
  List<Map<String, dynamic>> puzzles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPuzzles();
  }

  Future<void> fetchPuzzles() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/puzzles/${widget.category}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          puzzles = List<Map<String, dynamic>>.from(data['puzzles']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load puzzles');
      }
    } catch (e) {
      print('Error fetching puzzles: $e');
      setState(() => isLoading = false);
    }
  }

  Color getBackgroundColor() {
    switch (widget.category) {
      case 'sequence':
        return const Color(0xFF4A148C); // Deep Purple
      case 'loop':
        return const Color(0xFF00695C); // Teal
      case 'conditional':
        return const Color(0xFFBF360C); // Deep Orange
      default:
        return Colors.grey.shade800;
    }
  }

  Color getIconColor() {
    return Colors.white.withOpacity(0.95); // Light icon
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = getBackgroundColor();
    final iconColor = getIconColor();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
        title: Text(
          widget.title,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Image.asset(
              'assets/images/codebud_logo.png',
              height: 40,
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: puzzles.isEmpty
                  ? const Center(child: Text("No puzzles found."))
                  : ListView.separated(
                      itemCount: puzzles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final puzzle = puzzles[index];
                        return PuzzleButton(
                          label: puzzle['title'] ?? 'Puzzle ${index + 1}',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/puzzle',
                              arguments: puzzle['id'],
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
