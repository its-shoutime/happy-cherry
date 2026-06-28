import 'package:flutter/material.dart';
import 'package:pixel_ui/pixel_ui.dart';

import 'app_theme.dart';
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
      backgroundColor: AppTheme.backgroundPink,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarPink,
        foregroundColor: AppTheme.textDark,
        title: Text(
          'Owner login',
          style: AppTheme.pixelText(fontSize: 20, color: AppTheme.textDark),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              style: AppTheme.pixelText(fontSize: 16, color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: 'Email or username',
                labelStyle: AppTheme.pixelText(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: true,
              style: AppTheme.pixelText(fontSize: 16, color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: AppTheme.pixelText(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
            ),

            const SizedBox(height: 20),

            PixelButton(
              logicalWidth: 40,
              logicalHeight: 12,
              width: 220,
              pressChildOffset: const Offset(0, 1),
              onPressed: _login,
              semanticsLabel: 'Login',
              child: Text(
                'Login',
                style: AppTheme.buttonLabel(AppTheme.textDark),
              ),
            ),

            const SizedBox(height: 12),

            PixelButton(
              logicalWidth: 40,
              logicalHeight: 12,
              width: 220,
              pressChildOffset: const Offset(0, 1),
              onPressed: _signUp,
              semanticsLabel: 'Sign up',
              child: Text(
                'Sign up',
                style: AppTheme.buttonLabel(AppTheme.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
