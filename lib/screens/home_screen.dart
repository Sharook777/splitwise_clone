import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../services/session_service.dart';
import '../utils/nav_controller.dart';
import 'dashboard_screen.dart';
import 'friends_screen.dart';
import 'groups_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: ValueListenableBuilder<int>(
        valueListenable: NavController.selectedIndex,
        builder: (context, index, _) {
          return _buildSelectedScreen(index);
        },
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          height: 75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: NavController.selectedIndex,
            builder: (context, selectedIndex, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    0,
                    HugeIconsStrokeRounded.home09,
                    'Home',
                    selectedIndex,
                  ),
                  _buildNavItem(
                    1,
                    HugeIconsStrokeRounded.userGroup,
                    'Groups',
                    selectedIndex,
                  ),
                  _buildNavItem(
                    2,
                    HugeIconsStrokeRounded.user,
                    'Friends',
                    selectedIndex,
                  ),
                  _buildProfileNavItem(3, selectedIndex),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    dynamic icon,
    String label,
    int selectedIndex,
  ) {
    final isActive = selectedIndex == index;
    final themeColor = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          NavController.setIndex(index);
        },
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
                color: isActive ? themeColor : Colors.transparent,
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

  Widget _buildProfileNavItem(int index, int selectedIndex) {
    final isActive = selectedIndex == index;
    final themeColor = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          NavController.setIndex(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(shape: BoxShape.circle),
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

  Widget _buildSelectedScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const GroupsScreen();
      case 2:
        return const FriendsScreen();
      case 3:
        return const AccountScreen();
      default:
        return const DashboardScreen();
    }
  }
}
