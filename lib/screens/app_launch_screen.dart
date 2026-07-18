import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

class AppLaunchScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const AppLaunchScreen({
    super.key,
    this.title = 'EduGrade',
    this.subtitle = 'Preparing your Working space',
  });

  @override
  State<AppLaunchScreen> createState() => _AppLaunchScreenState();
}

class _AppLaunchScreenState extends State<AppLaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF071A3A),
              Color(0xFF0F2A5A),
              Color(0xFF2563EB),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                _buildBackgroundGlow(),
                ..._buildStars(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: _controller.value * 2 * pi,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                              width: 1.4,
                            ),
                          ),
                          child: Center(
                            child: Transform.scale(
                              scale: 0.96 + (0.05 * sin(_controller.value * 2 * pi)),
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF93C5FD),
                                      Color(0xFFFFFFFF),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.24),
                                      blurRadius: 28,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 56,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildGradeCapsules(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 220,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            backgroundColor: Colors.white.withValues(alpha: 0.18),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF93C5FD),
                            ),
                            value: 0.55 + (0.25 * sin(_controller.value * 2 * pi)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Syncing student records and grading rules',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF60A5FA).withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    final stars = <Widget>[];

    for (int i = 0; i < 18; i++) {
      final left = (i * 53) % 360.0;
      final top = (i * 71) % 720.0 / 2.2;
      final size = i.isEven ? 5.0 : 3.5;
      final opacity = 0.3 + ((i % 5) * 0.12);
      final drift = sin(_controller.value * 2 * pi + i) * 4;

      stars.add(
        Positioned(
          left: left + 20,
          top: top + drift + 24,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return stars;
  }

  Widget _buildGradeCapsules() {
    final grades = ['EE', 'ME', 'AE', 'BE'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: grades.map((grade) {
        final index = grades.indexOf(grade);
        final offset = sin(_controller.value * 2 * pi + index) * 6;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Text(
              grade,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
