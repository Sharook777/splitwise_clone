import 'package:flutter/material.dart';

/// A reusable animated route that combines a subtle slide-up with a fade-in.
/// The reverse (pop) animation slides down and fades out smoothly.
///
/// Usage:
///   Navigator.push(context, AnimatedPageRoute(page: const MyScreen()));
///
class AnimatedPageRoute extends PageRouteBuilder {
  final Widget page;

  AnimatedPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Forward: slide up + fade in
          var slideTween = Tween(
            begin: const Offset(0.0, 0.05),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

          var fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeIn));

          // When the screen is being pushed off by a new screen (secondary)
          var secondarySlide = Tween(
            begin: Offset.zero,
            end: const Offset(0.0, -0.03),
          ).chain(CurveTween(curve: Curves.easeInOut));

          var secondaryFade = Tween<double>(
            begin: 1.0,
            end: 0.6,
          ).chain(CurveTween(curve: Curves.easeInOut));

          // If this screen is being replaced by a new one pushed on top
          if (secondaryAnimation.value > 0) {
            return FadeTransition(
              opacity: secondaryAnimation.drive(secondaryFade),
              child: SlideTransition(
                position: secondaryAnimation.drive(secondarySlide),
                child: child,
              ),
            );
          }

          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(slideTween),
              child: child,
            ),
          );
        },
      );
}
