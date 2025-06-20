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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                              arguments: {
                                'id': puzzle['id'],
                                'title': puzzle['title'],
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
