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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Parent Name
              Text('Create an account', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 24),
              Text('Parent Information', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 24),
              TextField(
                controller: parentNameController,
                decoration: const InputDecoration(
                  labelText: 'Parent Name',
                ),
              ),
              const SizedBox(height: 16),
              // Email
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Text('Child Information', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 24),
              // Child Name
              TextField(
                controller: childNameController,
                decoration: const InputDecoration(
                  labelText: 'Child Name',
                ),
              ),
              const SizedBox(height: 16),
              // Child Age
              TextField(
                controller: childAgeController,
                decoration: const InputDecoration(
                  labelText: 'Child Age',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Username
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 24),
              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // You can add validation here before proceeding
                    setState(() {
                      message = 'Sign up successful!'; // Placeholder
                    });
                  },
                  child: const Text('Sign Up'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.green),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? "),
                  TextButton(onPressed: () {Navigator.pushNamed(context, '/login');}, child: Text('Login')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
