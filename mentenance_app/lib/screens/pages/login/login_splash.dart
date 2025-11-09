import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mentenance_app/core/constant/constant.dart';
import 'package:mentenance_app/screens/pages/home/home_page.dart';

class LoginSplash extends StatefulWidget {
  const LoginSplash({super.key});

  @override
  State<LoginSplash> createState() => _LoginSplashState();
}

class _LoginSplashState extends State<LoginSplash>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _colorController;

  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    // Listener للانتقال بعد انتهاء العداد
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const TasksPage(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Color _blendHSV(Color a, Color b, double t) {
    return HSVColor.lerp(
      HSVColor.fromColor(a),
      HSVColor.fromColor(b),
      t,
    )!.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _colorController,
        builder: (context, child) {
          double t = _colorController.value;
          double blend = 0.5 + 0.5 * sin(t * 2 * pi);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _blendHSV(AppColors.primary, AppColors.secondary, blend),
                  _blendHSV(AppColors.secondary, AppColors.primary, blend),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(),
                _buildLogo(),
                const SizedBox(height: 30),
                const Text(
                  "مرحباً أحمد محمد علي",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "فني صيانة أول",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 50),
                _buildGears(),
                const SizedBox(height: 30),
                const Text(
                  "جاري تحميل البيانات",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 20),
                _ProgressIndicator(animation: _progressAnimation),
                const SizedBox(height: 8),
                _ProgressText(animation: _progressAnimation),
                const SizedBox(height: 40),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.build, color: Colors.white, size: 50),
                      SizedBox(width: 10),
                      Text(
                        "نجهز أدوات الصيانة...",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(Icons.qr_code, size: 60, color: Colors.blue),
    );
  }

  Widget _buildGears() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _rotationController,
          child: const Icon(Icons.settings, color: Colors.white, size: 90),
        ),
        Transform.translate(
          offset: const Offset(-25, 20),
          child: RotationTransition(
            turns: Tween<double>(
              begin: 0,
              end: -1,
            ).animate(_rotationController),
            child: const Icon(Icons.settings, color: Colors.white70, size: 70),
          ),
        ),
      ],
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final Animation<double> animation;
  const _ProgressIndicator({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return LinearProgressIndicator(
          value: animation.value,
          backgroundColor: Colors.white24,
          color: Colors.white,
          minHeight: 6,
        );
      },
    );
  }
}

class _ProgressText extends StatelessWidget {
  final Animation<double> animation;
  const _ProgressText({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Text(
          "${(animation.value * 100).toInt()}%",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        );
      },
    );
  }
}

// صفحة الهوم
