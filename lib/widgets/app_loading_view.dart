import 'package:flutter/material.dart';
import '../screens/theme.dart';

class AppLoadingView extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;
  final double width;
  final bool compact;

  const AppLoadingView({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.auto_awesome_rounded,
    this.accentColor,
    this.width = 320,
    this.compact = false,
  });

  @override
  State<AppLoadingView> createState() => _AppLoadingViewState();
}

class _AppLoadingViewState extends State<AppLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.96, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppTheme.primary;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulse.value,
          child: Container(
            width: widget.width,
            padding: EdgeInsets.all(widget.compact ? 20 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: widget.compact ? 78 : 92,
                      height: widget.compact ? 78 : 92,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                        backgroundColor: accent.withOpacity(0.16),
                      ),
                    ),
                    Container(
                      width: widget.compact ? 48 : 58,
                      height: widget.compact ? 48 : 58,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: accent,
                        size: widget.compact ? 24 : 30,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: widget.compact ? 14 : 20),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: widget.compact ? 6 : 8),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
