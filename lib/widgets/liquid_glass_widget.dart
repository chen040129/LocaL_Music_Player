import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassWidget extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final bool enabled;

  const LiquidGlassWidget({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
    this.enabled = true,
  });

  @override
  State<LiquidGlassWidget> createState() => _LiquidGlassWidgetState();
}

class _LiquidGlassWidgetState extends State<LiquidGlassWidget> {
  FragmentShader? shader;
  Offset? mousePosition;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await FragmentProgram.fromAsset('shaders/liquidglass.frag');
      if (mounted) {
        setState(() {
          shader = program.fragmentShader();
        });
      }
    } catch (e) {
      debugPrint('Failed to load shader: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !mounted) {
      return widget.child;
    }

    return MouseRegion(
      onHover: (event) {
        setState(() {
          mousePosition = event.position;
        });
      },
      child: CustomPaint(
        painter: _LiquidGlassPainter(
          shader: shader,
          borderRadius: widget.borderRadius,
          mousePosition: mousePosition,
        ),
        child: widget.child,
      ),
    );
  }
}

class _LiquidGlassPainter extends CustomPainter {
  final FragmentShader? shader;
  final double borderRadius;
  final Offset? mousePosition;

  _LiquidGlassPainter({
    required this.shader,
    required this.borderRadius,
    this.mousePosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mousePosition == null || shader == null) return;

    final pixelRatio = MediaQueryData.fromWindow(WidgetsBinding.instance.window).devicePixelRatio;

    // Set resolution uniform
    shader!.setFloat(0, size.width * pixelRatio);
    shader!.setFloat(1, size.height * pixelRatio);

    // Set mouse position uniform
    shader!.setFloat(2, mousePosition!.dx * pixelRatio);
    shader!.setFloat(3, mousePosition!.dy * pixelRatio);

    // Create an image from the canvas to use as texture input
    final recorder = PictureRecorder();
    final tempCanvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Draw the background as a simple color for the texture
    tempCanvas.drawRRect(rrect, Paint()..color = Colors.white.withOpacity(0.1));

    final picture = recorder.endRecording();
    final image = picture.toImageSync(size.width.ceil(), size.height.ceil());

    // Set the sampler uniform with the image
    shader!.setImageSampler(0, image);

    final paint = Paint()
      ..shader = shader!
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);
    image.dispose();
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter oldDelegate) {
    return oldDelegate.mousePosition != mousePosition ||
        oldDelegate.borderRadius != borderRadius;
  }
}
