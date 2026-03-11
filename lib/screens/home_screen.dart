import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../utils/page_transitions.dart';
import 'friends_screen.dart';
import 'groups_screen.dart';
import 'account_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // "Home" is index 1

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildSelectedScreen(themeColor)),
            // Custom Floating Navigation Bar
            Container(
              margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, HugeIconsStrokeRounded.home09, 'Home'),
                  _buildNavItem(1, HugeIconsStrokeRounded.userGroup, 'Groups'),
                  _buildNavItem(2, HugeIconsStrokeRounded.user, 'Friends'),
                  _buildProfileNavItem(3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, dynamic icon, String label) {
    final isActive = _selectedIndex == index;
    final themeColor = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? themeColor.withOpacity(1.0)
                    : Colors.transparent,
              ),
              child: AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: HugeIcon(
                  icon: icon,
                  size: 24.0,
                  color: isActive ? Colors.white : Colors.black54,
                  strokeWidth: 2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? themeColor : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(int index) {
    final isActive = _selectedIndex == index;
    final themeColor = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // border: Border.all(
                //   color: isActive ? themeColor : Colors.transparent,
                //   width: 2,
                // ),
              ),
              child: FutureBuilder<String?>(
                future: SessionService.getUserName(),
                builder: (context, snapshot) {
                  final initial = snapshot.data?.isNotEmpty == true
                      ? snapshot.data![0].toUpperCase()
                      : 'U';
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: themeColor.withOpacity(
                      isActive ? 1.0 : 0.1,
                    ),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : themeColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Account',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? themeColor : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(Color themeColor) {
    return Padding(
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
                if (mounted) {
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
    );
  }

  Widget _buildSelectedScreen(Color themeColor) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent(themeColor);
      case 1:
        return const GroupsScreen();
      case 2:
        return const FriendsScreen();
      case 3:
        return AccountScreen(
          onBack: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      default:
        return _buildHomeContent(themeColor);
    }
  }
}
