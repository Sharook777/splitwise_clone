import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../services/session_service.dart';
import '../services/auth_service.dart';
import '../utils/page_transitions.dart';
import 'welcome_screen.dart';

class AccountScreen extends StatelessWidget {
  final VoidCallback onBack;
  const AccountScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: themeColor,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true, // extend behind app bar
        extendBody: true, // extend behind bottom nav bar
        backgroundColor: Colors.white, // this color bleeds into status bar
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: themeColor,
                  // borderRadius: const BorderRadius.only(
                  //   bottomLeft: Radius.circular(40),
                  //   bottomRight: Radius.circular(40),
                  // ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHeaderIcon(
                              HugeIconsStrokeRounded.arrowLeft01,
                              onTap: onBack,
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
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: FutureBuilder<String?>(
                            future: SessionService.getUserName(),
                            builder: (context, snapshot) {
                              final initial = snapshot.data?.isNotEmpty == true
                                  ? snapshot.data![0].toUpperCase()
                                  : 'U';
                              return CircleAvatar(
                                radius: 45,
                                backgroundColor: themeColor.withValues(
                                  alpha: 0.1,
                                ),
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: 35,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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

                        // Stats
                      ],
                    ),

                    const SizedBox(height: 25),

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
                          Colors.orange[100]!,
                          Colors.orange[700]!,
                        ),
                        _buildInfoCard(
                          'Rate DUTCH',
                          HugeIconsStrokeRounded.startUp01,
                          Colors.amber[100]!,
                          Colors.amber[700]!,
                        ),
                        _buildInfoCard(
                          'Support',
                          HugeIconsStrokeRounded.customerSupport,
                          Colors.yellow[50]!,
                          Colors.yellow[700]!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          color: Colors.white.withValues(alpha: 0.8),
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
