import 'package:flutter/material.dart';

import 'game_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      await _showMessage('Enter username and password.');
      return;
    }

    final normalizedUsername = username.toLowerCase();
    final success = await GameState.loginUser(normalizedUsername, password);
    if (!success) {
      await _showMessage('Login failed. Check your username and password.');
    }
  }

  Future<void> _signUp() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      await _showMessage('Enter username and password.');
      return;
    }

    final normalizedUsername = username.toLowerCase();
    final created = await GameState.registerUser(normalizedUsername, password);
    if (!created) {
      await _showMessage('That username is already taken or invalid.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Email or username'),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              child: const Text('Login'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _signUp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              child: const Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
