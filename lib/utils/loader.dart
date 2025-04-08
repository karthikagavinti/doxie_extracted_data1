import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ZoomiesLoader extends StatefulWidget {
  final double size;
  final double dotSize;
  final Color color;
  final double speed;
  
  const ZoomiesLoader({
    Key? key,
    this.size = 80,
    this.dotSize = 5,
    this.color = Colors.blue, // Using your app's primary color
    this.speed = 1.4,
  }) : super(key: key);

  @override
  State<ZoomiesLoader> createState() => _ZoomiesLoaderState();
}

class _ZoomiesLoaderState extends State<ZoomiesLoader> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  
  @override
  void initState() {
    super.initState();
    
    // Create multiple animation controllers for different dots
    _controllers = List.generate(8, (index) {
      return AnimationController(
        duration: Duration(milliseconds: (1500 / widget.speed).round()),
        vsync: this,
      )..repeat(reverse: true);
    });
    
    // Stagger the animations
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].value = i / _controllers.length;
    }
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(8, (index) {
          final angle = index * (2 * pi / 8);
          return AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              // Calculate the scale and position based on the animation value
              final scale = 0.5 + _controllers[index].value;
              final distance = widget.size / 3 * _controllers[index].value;
              
              return Positioned(
                left: widget.size / 2 + cos(angle) * distance - widget.dotSize,
                top: widget.size / 2 + sin(angle) * distance - widget.dotSize,
                child: Container(
                  width: widget.dotSize * 2,
                  height: widget.dotSize * 2,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 600.ms,
                  delay: (index * 75).ms,
                  curve: Curves.easeInOut,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}