// lib/core/utils/page_transitions.dart

import 'package:flutter/material.dart';

/// A modal page route that slides up smoothly from the bottom over the current screen.
/// Features a transparent backdrop so the underlying dashboard remains visible during slide enter and exit.
class SmoothModalRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothModalRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black26,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeOutCubic,
          );

          final slideAnim = Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnim);

          return SlideTransition(position: slideAnim, child: child);
        },
      );
}

/// A forward page route transition (right-to-left slide with smooth cubic curve).
/// Ideal for detail views (e.g. Account Details, Categories Screen).
class SmoothSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothSlideRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeOutCubic,
          );

          final slideAnim = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnim);

          return SlideTransition(position: slideAnim, child: child);
        },
      );
}
