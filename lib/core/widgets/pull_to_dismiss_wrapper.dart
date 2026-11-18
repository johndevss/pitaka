// lib/core/widgets/pull_to_dismiss_wrapper.dart

import 'package:flutter/material.dart';
import 'package:pitaka/core/utils/haptic_engine.dart';

/// A wrapper widget that adds a top drag indicator pill and enables
/// downward pull-to-dismiss gesture physics for modal screens.
class PullToDismissWrapper extends StatefulWidget {
  final Widget child;
  final double dismissThreshold;
  final VoidCallback? onDismissed;
  final bool showDragHandle;

  const PullToDismissWrapper({
    super.key,
    required this.child,
    this.dismissThreshold = 120.0,
    this.onDismissed,
    this.showDragHandle = true,
  });

  @override
  State<PullToDismissWrapper> createState() => _PullToDismissWrapperState();
}

class _PullToDismissWrapperState extends State<PullToDismissWrapper>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late AnimationController _animController;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animController.addListener(() {
      setState(() {
        _dragOffset = _anim.value;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    FocusScope.of(context).unfocus();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 400.0);
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset > widget.dismissThreshold || velocity > 800) {
      HapticEngine.light();
      if (widget.onDismissed != null) {
        widget.onDismissed!();
      } else {
        Navigator.of(context).pop();
      }
    } else if (_dragOffset > 0) {
      // Animate back to top (0.0)
      _anim = Tween<double>(begin: _dragOffset, end: 0.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dragProgress = (_dragOffset / 250.0).clamp(0.0, 1.0);
    final barrierAlpha = 0.25 * (1.0 - dragProgress);

    return Stack(
      children: [
        // Backdrop dimming scrim that fades out as user drags down
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: barrierAlpha)),
        ),
        // Translating modal sheet container
        GestureDetector(
          onVerticalDragStart: _onVerticalDragStart,
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          behavior: HitTestBehavior.translucent,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Column(
              children: [
                if (widget.showDragHandle)
                  Container(
                    color: const Color(0xFFF5F7F5),
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
