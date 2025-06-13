import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController parentNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController childNameController = TextEditingController();
  final TextEditingController childAgeController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String message = '';
  bool isLoading = false;

  // Validation function
  bool validateFields() {
    if (parentNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        childNameController.text.isEmpty ||
        childAgeController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        message = "Please fill in all required fields.";
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required.')));
      return false;
    }
    return true;
  }

  // Function to handle sign up
  Future<void> handleSignUp() async {
    if (!validateFields()) return;

    setState(() {
      isLoading = true;
      message = '';
    });

    final body = {
      "parent_name": parentNameController.text.trim(),
      "email": emailController.text.trim(),
      "child_name": childNameController.text.trim(),
      "child_age": childAgeController.text.trim(),
      "username": usernameController.text.trim(),
      "password": passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // ADD THIS CHECK before using context/setState after await!
      if (!mounted) return;

      final data = jsonDecode(response.body);
      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Account created! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/login',
              arguments: data['message'] ?? 'Account created! Please login.',
            );
          }
        });
      } else {
        setState(() {
          message = data['message'] ?? 'Sign up failed!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        message = 'Network error. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Create an account',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: parentNameController,
                decoration: const InputDecoration(labelText: 'Parent Name *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: childNameController,
                decoration: const InputDecoration(labelText: 'Child Name *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: childAgeController,
                decoration: const InputDecoration(labelText: 'Child Age *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password *'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: handleSignUp,
                        child: const Text('Sign Up'),
                      ),
                    ),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(color: Colors.red)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
