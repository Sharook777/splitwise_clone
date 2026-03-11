import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_screen.dart';
import '../utils/page_transitions.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        // backgroundColor: Colors.red,
        body: Column(
          children: [
            // Top Graphic Section
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // The main illustration
                    Positioned(
                      bottom:
                          0, // Align it towards the bottom of the curved orange area
                      left: 0,
                      right: 0,
                      top: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        child: Image.asset(
                          'assets/images/onboarding_banner.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Content Section
            Expanded(
              flex: 5,
              child: SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30.0,
                    vertical: 30.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Split Expenses Smarter',
                            style: TextStyle(
                              fontSize: 32,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                              color: themeColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Go out together. Pay your share.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            'Track every cent. Settle every debt.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              AnimatedPageRoute(page: const SignupScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'GO DUTCH',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // A tiny bit of the bottom background showing the beige color (like the image edges)
          ],
        ),
      ),
    );
  }
}
