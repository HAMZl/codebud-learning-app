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
  bool isConsentGiven = false;

  bool validateFields() {
    if (parentNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        childNameController.text.isEmpty ||
        childAgeController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        !isConsentGiven) {
      setState(() {
        isError = true;
        message = "Please complete all fields and provide consent.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

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
        Uri.parse('http://127.0.0.1:5000/signup'),
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
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
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
                const SizedBox(height: 16),

                Center(
                  child: Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Divider(height: 32, thickness: 1),

                const Text('👩 Parent Information',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: styledInputDecoration('Parent Email', Icons.email),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration:
                  styledInputDecoration('Password', Icons.lock_outline),
                ),

                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Password must be at least 8 characters and include:\n"
                        "• 1 uppercase letter (A–Z)\n"
                        "• 1 lowercase letter (a–z)\n"
                        "• 1 number (0–9)\n"
                        "• 1 special character (!, @, #, etc.)",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 24),

                const Text('🧒 Child Information',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                TextField(
                  controller: childNameController,
                  decoration:
                  styledInputDecoration("Child's Name", Icons.child_care),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: childAgeController,
                  keyboardType: TextInputType.number,
                  decoration:
                  styledInputDecoration("Child's Age", Icons.cake),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Checkbox(
                      value: isConsentGiven,
                      onChanged: (value) {
                        setState(() {
                          isConsentGiven = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        "Yes, I want to receive updates and news about CodeBud.",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Create Account",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Column(
                    children: [
                      const Text(
                        "By creating an account you agree to the ",
                        style: TextStyle(fontSize: 12),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: const [
                          Text("Privacy Policy",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline)),
                          Text(" and ",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black)),
                          Text("Terms of Use",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
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
