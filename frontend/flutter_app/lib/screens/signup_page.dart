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
  bool isError = false;

  // Validation function
  bool validateFields() {
    if (parentNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        childNameController.text.isEmpty ||
        childAgeController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        isError = true;
        message = "Please fill in all required fields.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required.'),
          backgroundColor: Colors.red,
        ),
      );
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
      isError = false;
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
        Uri.parse(
          'http://127.0.0.1:5000/signup',
        ), // CHANGE TO YOUR BACKEND URL IF NEEDED
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

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
          isError = true;
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
        isError = true;
        message = 'Network error. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  InputDecoration styledInputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.lightBlueAccent),
      labelText: label,
      filled: true,
      fillColor: Colors.deepPurple.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo at top right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image.asset('assets/images/codebud_logo.png', height: 60),
                  ],
                ),
                const SizedBox(height: 16),

                Center(
                  child: Text(
                    'Create an Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  '👩 Parent Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: parentNameController,
                  decoration: styledInputDecoration(
                    'Parent Name',
                    Icons.person,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: styledInputDecoration('Email', Icons.email),
                ),

                const SizedBox(height: 32),
                Text(
                  '🧒 Child Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: childNameController,
                  decoration: styledInputDecoration(
                    'Child Name',
                    Icons.child_care,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: childAgeController,
                  keyboardType: TextInputType.number,
                  decoration: styledInputDecoration(
                    'Child Age',
                    Icons.calendar_today,
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  '🔑 Account Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: usernameController,
                  decoration: styledInputDecoration(
                    'Username',
                    Icons.account_circle,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: styledInputDecoration('Password', Icons.lock),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                          onPressed: handleSignUp,
                          child: const Text('Sign Up'),
                        ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isError ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
