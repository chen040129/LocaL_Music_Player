import 'package:flutter/material.dart';

class ThemeTransition extends StatefulWidget {
  final ThemeMode themeMode;
  final Widget child;

  const ThemeTransition({
    Key? key,
    required this.themeMode,
    required this.child,
  }) : super(key: key);

  @override
  State<ThemeTransition> createState() => _ThemeTransitionState();
}

class _ThemeTransitionState extends State<ThemeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  ThemeMode? _previousThemeMode;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _previousThemeMode = widget.themeMode;
  }

  @override
  void didUpdateWidget(ThemeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.themeMode != oldWidget.themeMode) {
      _previousThemeMode = oldWidget.themeMode;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + 0.7 * _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
