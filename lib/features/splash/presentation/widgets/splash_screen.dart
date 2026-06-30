import 'dart:async';
import 'package:flutter/material.dart';
import 'package:coffee_pos/features/checkout/presentation/widgets/pos_dashboard.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onThemeToggled;
  final bool isDarkMode;
  final VoidCallback onLocaleToggled;
  final Locale activeLocale;

  const SplashScreen({
    super.key,
    required this.onThemeToggled,
    required this.isDarkMode,
    required this.onLocaleToggled,
    required this.activeLocale,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;

  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  double _loadingProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    // 1. Logo Elastic Scale-in and Spin Animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoRotate = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    // 2. Text Brand Name Fade-in and Slide-up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Start UI Animations
    _logoController.forward();
    _textController.forward();

    // 3. Simulated Loading Progress Indicator (reaches 100% in 2.2 seconds)
    const stepDuration = Duration(milliseconds: 22);
    _progressTimer = Timer.periodic(stepDuration, (timer) {
      setState(() {
        if (_loadingProgress < 1.0) {
          _loadingProgress += 0.01;
        } else {
          _loadingProgress = 1.0;
          _progressTimer?.cancel();
          _navigateToDashboard();
        }
      });
    });
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PosDashboard(
          onThemeToggled: widget.onThemeToggled,
          isDarkMode: widget.isDarkMode,
          onLocaleToggled: widget.onLocaleToggled,
          activeLocale: widget.activeLocale,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Premium dark brown/espresso theme for the loading experience
    const bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1B1411), // Dark Coffee Bean
        Color(0xFF0F0A08), // Rich Espresso
      ],
    );

    const goldAccent = Color(0xFFD4AF37); // Classic Gold Branding

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: bgGradient,
        ),
        child: Stack(
          children: [
            // Branding & Center Logo
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotate.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: goldAccent.withAlpha(40),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                        border: Border.all(
                          color: goldAccent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.local_cafe_rounded,
                              color: goldAccent,
                              size: 70,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Animated Shop Text
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFade,
                        child: FractionalTranslation(
                          translation: _textSlide.value,
                          child: child,
                        ),
                      );
                    },
                    child: const Column(
                      children: [
                        Text(
                          'RAKSA COFFEE',
                          style: TextStyle(
                            color: goldAccent,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3.5,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'PREMIUM COFFEE & BLENDS',
                          style: TextStyle(
                            color: Color(0xFFBCA697),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Loading Progress Bar at the bottom
            Positioned(
              bottom: 60,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  // Progress line
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _loadingProgress,
                      minHeight: 3,
                      backgroundColor: Colors.white.withAlpha(15),
                      valueColor: const AlwaysStoppedAnimation<Color>(goldAccent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress text percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INITIALISING POS...',
                        style: TextStyle(
                          color: Colors.white.withAlpha(80),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      Text(
                        '${(_loadingProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: goldAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
