import 'package:flutter/material.dart';

/// 一个自带独立 TickerProvider 的 AnimatedSwitcher 包装组件
/// 解决 AnimatedSwitcher 在 Tooltip/IconButton 等
/// SingleTickerProviderStateMixin 组件子树中运行时的 ticker 冲突问题
class SmoothAnimatedSwitcher extends StatelessWidget {
  final Duration duration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final Widget Function(Widget child, Animation<double> animation) transitionBuilder;
  final Widget child;
  final StackFit layoutFit;

  const SmoothAnimatedSwitcher({
    Key? key,
    required this.duration,
    this.switchInCurve = Curves.easeInOut,
    this.switchOutCurve = Curves.easeInOut,
    required this.transitionBuilder,
    required this.child,
    this.layoutFit = StackFit.loose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _SmoothAnimatedSwitcherWrapper(
      duration: duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: transitionBuilder,
      layoutFit: layoutFit,
      child: child,
    );
  }
}

class _SmoothAnimatedSwitcherWrapper extends StatefulWidget {
  final Duration duration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final Widget Function(Widget child, Animation<double> animation) transitionBuilder;
  final Widget child;
  final StackFit layoutFit;

  const _SmoothAnimatedSwitcherWrapper({
    Key? key,
    required this.duration,
    required this.switchInCurve,
    required this.switchOutCurve,
    required this.transitionBuilder,
    required this.child,
    required this.layoutFit,
  }) : super(key: key);

  @override
  State<_SmoothAnimatedSwitcherWrapper> createState() => _SmoothAnimatedSwitcherWrapperState();
}

class _SmoothAnimatedSwitcherWrapperState extends State<_SmoothAnimatedSwitcherWrapper>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.duration,
      switchInCurve: widget.switchInCurve,
      switchOutCurve: widget.switchOutCurve,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.center,
          fit: widget.layoutFit,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: widget.transitionBuilder,
      child: widget.child,
    );
  }
}
