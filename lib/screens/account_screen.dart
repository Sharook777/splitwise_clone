import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../services/session_service.dart';
import '../services/auth_service.dart';
import '../utils/page_transitions.dart';
import '../utils/nav_controller.dart';
import 'welcome_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFECECEC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: themeColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Container(
                  color: themeColor,
                  child: Column(
                    children: [
                      // Header Section
                      Container(
                        width: double.infinity,
                        color: themeColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildHeaderIcon(
                                    HugeIconsStrokeRounded.arrowLeft01,
                                    onTap: () => NavController.setIndex(0),
                                  ),
                                  _buildHeaderIcon(
                                    HugeIconsStrokeRounded.logout01,
                                    onTap: () async {
                                      await AuthService.signOut();
                                      if (context.mounted) {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          AnimatedPageRoute(
                                            page: const WelcomeScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Profile Image
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: FutureBuilder<String?>(
                                  future: SessionService.getUserName(),
                                  builder: (context, snapshot) {
                                    final initial =
                                        (snapshot.data ?? '').isNotEmpty
                                        ? snapshot.data![0].toUpperCase()
                                        : 'U';
                                    return CircleAvatar(
                                      radius: 45,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.8,
                                      ),
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          fontSize: 35,
                                          color: themeColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      // Content Container
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFECECEC),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(35),
                            topRight: Radius.circular(35),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Name and Email
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FutureBuilder<String?>(
                                        future: SessionService.getUserName(),
                                        builder: (context, snapshot) {
                                          return Text(
                                            snapshot.data ?? 'User Name',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<String?>(
                                        future: SessionService.getUserEmail(),
                                        builder: (context, snapshot) {
                                          return Text(
                                            snapshot.data ?? 'user@email.com',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Info Cards Grid
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.2,
                                children: [
                                  _buildInfoCard(
                                    'Security',
                                    HugeIconsStrokeRounded.security,
                                    Colors.orange[100] ?? Colors.orange,
                                    Colors.orange[700] ?? Colors.orange,
                                  ),
                                  _buildInfoCard(
                                    'Rate DUTCH',
                                    HugeIconsStrokeRounded.startUp01,
                                    Colors.amber[100] ?? Colors.amber,
                                    Colors.amber[700] ?? Colors.amber,
                                  ),
                                  _buildInfoCard(
                                    'Support',
                                    HugeIconsStrokeRounded.customerSupport,
                                    Colors.yellow[50] ?? Colors.yellow,
                                    Colors.yellow[700] ?? Colors.yellow,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 80), // bottom nav space
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(dynamic icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: HugeIcon(
          icon: icon,
          color: Colors.black,
          size: 24,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    dynamic icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.15),
        //     blurRadius: 10,
        //     offset: Offset(0, 0),
        //   ),
        // ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: HugeIcon(
              icon: icon,
              color: iconColor,
              size: 24,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 15, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
