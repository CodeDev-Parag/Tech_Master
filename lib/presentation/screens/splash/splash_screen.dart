import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                    const Color(0xFF312E81),
                  ]
                : [
                    const Color(0xFF6366F1),
                    const Color(0xFF8B5CF6),
                    const Color(0xFFA78BFA),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // App Name
              Text(
                'Task Master',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.3, delay: 300.ms, duration: 500.ms),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'AI-Powered Productivity',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms)
                  .slideY(begin: 0.3, delay: 500.ms, duration: 500.ms),

              const SizedBox(height: 60),

              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  delay: 800.ms,
                  duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
