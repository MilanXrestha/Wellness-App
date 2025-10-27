import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StaticGradientBalls extends StatelessWidget {
  final bool isDarkMode;

  const StaticGradientBalls({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top left teal ball
        Positioned(
          top: 15.h,
          left: -5.w,
          child: _build3DBall(60.r, Colors.teal, isDark: isDarkMode),
        ),

        // Top right light blue ball (was purple before)
        Positioned(
          top: -1.h,
          right: -50.w,
          child: _build3DBall(100.r, Colors.lightBlueAccent, isDark: isDarkMode),
        ),

        // Bottom left dark blue ball
        Positioned(
          bottom: -20.h,
          left: -20.w,
          child: _build3DBall(90.r, Colors.blue.shade800, isDark: isDarkMode),
        ),

        // Bottom right red/pink ball (smaller now)
        Positioned(
          bottom: 60.h,
          right: -5.w,
          child: _build3DBall(60.r, Colors.pinkAccent, isDark: isDarkMode),
        ),

        // Yellow (amber) ball → moved up + centered
        Positioned(
          top: 150.h, // higher than before
          left: MediaQuery.of(context).size.width / 2 - 20.w, // centered
          child: _build3DBall(20.r, Colors.amber, isDark: isDarkMode),
        ),
      ],
    );
  }

  Widget _build3DBall(double size, Color color, {required bool isDark}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [
            color.withOpacity(0.9),
            color.withOpacity(0.6),
            color.withOpacity(0.2),
            isDark
                ? Colors.transparent
                : Colors.white.withOpacity(0.3), // contrast for light mode
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark
                  ? Colors.white.withOpacity(0.5) // highlight for dark mode
                  : Colors.black.withOpacity(0.2), // shadow feel for light mode
              Colors.transparent,
            ],
            stops: const [0.0, 0.6],
          ),
        ),
      ),
    );
  }
}
