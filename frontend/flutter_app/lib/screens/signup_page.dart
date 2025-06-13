import 'package:flutter/material.dart';

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
                    Image.asset(
                      'assets/images/codebud_logo.png',
                      height: 60,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Center(
                  child: Text(
                    'Create an Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 32),
                Text('👩 Parent Information', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                TextField(
                  controller: parentNameController,
                  decoration: styledInputDecoration('Parent Name', Icons.person),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: styledInputDecoration('Email', Icons.email),
                ),

                const SizedBox(height: 32),
                Text('🧒 Child Information', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                TextField(
                  controller: childNameController,
                  decoration: styledInputDecoration('Child Name', Icons.child_care),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: childAgeController,
                  keyboardType: TextInputType.number,
                  decoration: styledInputDecoration('Child Age', Icons.calendar_today),
                ),

                const SizedBox(height: 32),
                Text('🔑 Account Details', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                TextField(
                  controller: usernameController,
                  decoration: styledInputDecoration('Username', Icons.account_circle),
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: () {
                      setState(() {
                        message = 'Sign up successful!';
                      });

                      Future.delayed(const Duration(seconds: 1), () {
                        Navigator.pushReplacementNamed(context, '/login');
                      });
                    },
                    child: const Text('Sign Up'),

                  ),
                ),

                const SizedBox(height: 16),
                Center(child: Text(message, style: const TextStyle(color: Colors.green))),
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
