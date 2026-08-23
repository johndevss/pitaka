// lib/core/widgets/shared_axis_tab_switcher.dart

import 'package:flutter/material.dart';

/// A tab switcher that performs a directional horizontal shared-axis
/// transition between tab screens, while preserving the state of all child screens.
class SharedAxisTabSwitcher extends StatefulWidget {
  final int selectedIndex;
  final List<Widget> children;
  final Duration duration;

  const SharedAxisTabSwitcher({
    super.key,
    required this.selectedIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 260),
  });

  @override
  State<SharedAxisTabSwitcher> createState() => _SharedAxisTabSwitcherState();
}

class _SharedAxisTabSwitcherState extends State<SharedAxisTabSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _previousIndex;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _currentIndex = widget.selectedIndex;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..value = 1.0; // Initially fully arrived
  }

  @override
  void didUpdateWidget(SharedAxisTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _currentIndex = widget.selectedIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMovingRight = _currentIndex > _previousIndex;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value;
        final double curvedProgress = Curves.easeOutCubic.transform(progress);

        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (index) {
            final bool isCurrent = index == _currentIndex;
            final bool isPrevious =
                index == _previousIndex && _controller.isAnimating;

            // Hide offstage non-active screens
            final bool isOffstage = !isCurrent && !isPrevious;

            double opacity = 1.0;
            double dx = 0.0;

            if (isCurrent) {
              opacity = curvedProgress;
              final double startOffset = isMovingRight ? 28.0 : -28.0;
              dx = startOffset * (1.0 - curvedProgress);
            } else if (isPrevious) {
              opacity = 1.0 - curvedProgress;
              final double endOffset = isMovingRight ? -28.0 : 28.0;
              dx = endOffset * curvedProgress;
            }

            return Offstage(
              offstage: isOffstage,
              child: IgnorePointer(
                ignoring: !isCurrent,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: widget.children[index],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
