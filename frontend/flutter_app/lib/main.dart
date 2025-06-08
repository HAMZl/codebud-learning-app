import 'package:flutter/material.dart';

void main() {
  runApp(CodeBudApp());
}

class CodeBudApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeBud',
      home: Scaffold(
        appBar: AppBar(title: Text('CodeBud')),
        body: Center(child: Text('Welcome to CodeBud!')),
      ),
    );
  }
}
