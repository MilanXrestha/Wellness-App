// Heart animation helper classes
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HeartAnimation {
  final double xOffset;
  final double size;

  HeartAnimation({required this.xOffset, required this.size});
}

class HeartWidget extends StatelessWidget {
  final Animation<double> animation;
  final double size;

  const HeartWidget({super.key, required this.animation, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        final yOffset = -progress * 300.h;
        final opacity = 1.0 - progress;
        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Icon(
              Icons.favorite,
              color: Colors.redAccent.withOpacity(0.8),
              size: size.sp,
            ),
          ),
        );
      },
    );
  }
}
