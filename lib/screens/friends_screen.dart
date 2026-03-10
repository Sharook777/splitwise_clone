import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIconsStrokeRounded.user,
                    size: 80,
                    color: themeColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No friends yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite friends to start splitting expenses!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
