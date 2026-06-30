import 'package:flutter/material.dart';

/// An animation wrapper that fades and slides up the child widget,
/// with a staggered delay based on its index.
class StaggeredEntranceAnimation extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final double slideOffset;

  const StaggeredEntranceAnimation({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = 0.1,
  });

  @override
  State<StaggeredEntranceAnimation> createState() => _StaggeredEntranceAnimationState();
}

class _StaggeredEntranceAnimationState extends State<StaggeredEntranceAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, widget.slideOffset),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Dynamic delay based on grid index. Cap the index to prevent long lag on large lists.
    final delayMs = (widget.index % 12) * 45;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A tactile animation wrapper that scales down slightly when pressed
/// and springs back up when released, giving excellent tactile feedback.
class ScaleBouncePressReaction extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const ScaleBouncePressReaction({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
  });

  @override
  State<ScaleBouncePressReaction> createState() => _ScaleBouncePressReactionState();
}

class _ScaleBouncePressReactionState extends State<ScaleBouncePressReaction> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget animatedChild = ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: animatedChild,
      );
    } else {
      return Listener(
        onPointerDown: (_) => _controller.forward(),
        onPointerUp: (_) => _controller.reverse(),
        onPointerCancel: (_) => _controller.reverse(),
        behavior: HitTestBehavior.opaque,
        child: animatedChild,
      );
    }
  }
}
