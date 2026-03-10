import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../utils/page_transitions.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              FutureBuilder<String?>(
                future: SessionService.getUserName(),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? 'User';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey,',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey[900],
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // Placeholder content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 80,
                        color: themeColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No expenses yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start splitting bills with your friends!',
                        style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),

              // Clear session button
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        AnimatedPageRoute(page: const WelcomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: Icon(
                    Icons.logout_rounded,
                    color: Colors.red[400],
                    size: 20,
                  ),
                  label: Text(
                    'Clear Session',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
