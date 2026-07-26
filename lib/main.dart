import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:happy_cherry/app/app_theme.dart';
import 'package:happy_cherry/app/audio_manager.dart';
import 'package:happy_cherry/features/home/home_page.dart';
import 'package:happy_cherry/firebase_options.dart';
import 'package:happy_cherry/app/loading_screen.dart';
import 'package:happy_cherry/features/auth/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Happy Cherry',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final Future<void> _startupFuture = _initialize();

  Future<void> _initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      await FirebaseFirestore.instance.enableNetwork();
    } catch (error, stackTrace) {
      // Don't block startup if persistence settings fail on a given platform.
      debugPrint('Firestore setup warning: $error\n$stackTrace');
    }
    await AudioManager.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundPink,
            body: Center(
              child: Text(
                'Failed to start Happy Cherry.',
                style: AppTheme.pixelText(
                  fontSize: 18,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            final user = snapshot.data;
            if (user == null) {
              return const LoginPage();
            }

            return HomePage(userId: user.uid, onLogout: _handleLogout);
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    await AudioManager.instance.stopBgm();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error, stackTrace) {
      debugPrint('Error during sign out: $error\n$stackTrace');
    }
  }
}
