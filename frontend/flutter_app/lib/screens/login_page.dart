import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.deepPurple),
              SizedBox(height: 24),
              Text('Welcome back 👋', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {}, child: Text('Forgot password?')),
              ),
              SizedBox(height: 24),
              ElevatedButton(onPressed: () {}, child: Text('Log In')),
              SizedBox(height: 16),
              Text(message, style: TextStyle(color: Colors.red)),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? "),
                  TextButton(onPressed: () {Navigator.pushNamed(context, '/signup');}, child: Text('Sign up')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
