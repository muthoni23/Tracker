import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'auth/login_screen.dart';
import 'home/main_shell.dart';

/// Splash screen with the "StudyTrack" cover image / dark background.
///
/// To use your own background image (tracker.jpg):
/// 1. Copy it into  assets/images/splash_bg.jpg  in your Flutter project.
/// 2. Add to pubspec.yaml:
///      flutter:
///        assets:
///          - assets/images/splash_bg.jpg
/// The Image.asset call below already points at that path.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), _decideNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _decideNext() {
    if (!mounted) return;
    // Guarded: in a widget test (or if Firebase somehow isn't ready yet)
    // FirebaseAuth.instance can throw rather than just return null.
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => user != null ? const MainShell() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background image. Falls back to a plain navy
          // gradient if the asset hasn't been added yet, so the app
          // never crashes on a missing file.
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.splashNavy, Color(0xFF2B2560)],
                ),
              ),
            ),
          ),
          // Dark overlay so text stays legible over any photo.
          Container(color: Colors.black.withOpacity(0.35)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'StudyTrack',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plan · Focus · Achieve',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(flex: 3),
                  Text(
                    'Small steps\nlead to big dreams',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.favorite_border,
                      color: Colors.white.withOpacity(0.7), size: 18),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
