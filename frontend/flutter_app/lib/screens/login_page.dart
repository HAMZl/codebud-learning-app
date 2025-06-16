import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String message = '';
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String? successMsg =
        ModalRoute.of(context)?.settings.arguments as String?;
    if (successMsg != null && successMsg.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
        );
      });
    }
  }

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final body = {
      "username": usernameController.text.trim(),
      "password": passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (!mounted) return;

      final data = jsonDecode(response.body);

      setState(() => isLoading = false);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => message = data['message'] ?? 'Login failed!');
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
      backgroundColor: Colors.white, // Matches LaunchPage
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Icon(Icons.lock, size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot password?'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            onPressed: handleLogin,
                            child: const Text('Log In'),
                          ),
                  ),

                  const SizedBox(height: 16),
                  Text(message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
