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
    // Show message if passed from sign up page
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
        Uri.parse('http://127.0.0.1:5000/login'), // Change this!
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (!mounted) return;

      final data = jsonDecode(response.body);

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200 && data['success'] == true) {
        // Login success: redirect or show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // TODO: Redirect to your home/dashboard page, for example:
        // Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          message = data['message'] ?? 'Login failed!';
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 24),
              Text(
                'Welcome back 👋',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password *'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: handleLogin,
                      child: const Text('Log In'),
                    ),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text('Sign up'),
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
