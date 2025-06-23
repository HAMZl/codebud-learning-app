import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  final List<Color> cardColors = [
    Colors.pink.shade300,
    Colors.teal.shade300,
    Colors.orange.shade300,
  ];

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
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: puzzles.isEmpty
                  ? const Center(child: Text("No puzzles found."))
                  : GridView.builder(
                      itemCount: puzzles.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemBuilder: (context, index) {
                        final puzzle = puzzles[index];
                        final level = index + 1;

                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/puzzle',
                              arguments: {
                                'id': puzzle['id'],
                                'title': puzzle['title'],
                                'category': widget.category,
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color:
                                          cardColors[index % cardColors.length],
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$level',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Level $level',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: List.generate(
                                            3,
                                            (starIndex) => Icon(
                                              Icons.star,
                                              size: 24,
                                              color: starIndex < 1 + (level % 3)
                                                  ? Colors.amber
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
