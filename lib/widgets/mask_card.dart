import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 蒙版卡片组件
/// 使用半透明蒙罩实现卡片效果，主题切换时只改变背景色
class MaskCard extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? accentColor; // 强调色，用于高亮边框和阴影

  const MaskCard({
    Key? key,
    required this.child,
    this.isSelected = false,
    this.isHovered = false,
    this.onTap,
    this.onDoubleTap,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    this.accentColor,
  }) : super(key: key);

  @override
  State<MaskCard> createState() => _MaskCardState();
}

class _MaskCardState extends State<MaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(MaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isSelected || widget.isHovered) !=
        (oldWidget.isSelected || oldWidget.isHovered)) {
      if (widget.isSelected || widget.isHovered) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || widget.isHovered;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              // 柔和的阴影，使边界更模糊
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
              if (isActive)
                BoxShadow(
                  color: (widget.accentColor ?? Theme.of(context).colorScheme.primary)
                      .withOpacity(0.25 * _animation.value),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                // 模糊的蒙罩层（放在底部，不阻挡交互）
                if (isActive)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: (widget.accentColor ?? Theme.of(context).colorScheme.primary)
                            .withOpacity(0.08 * _animation.value),
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                      ),
                    ),
                  ),
                // 内容（放在顶部，可以交互）
                Padding(
                  padding: widget.padding ?? EdgeInsets.zero,
                  child: widget.child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
