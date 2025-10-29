import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../language/app_localizations.dart';
import '../provider/auth_provider.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
      final localizations = AppLocalizations.of(context)!;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Search Icon
          _buildNavItem(
            icon: Icons.search,
            index: 0,
            isActive: currentIndex == 0,
            label: localizations.search,
          ),
          
          // Home Icon
          _buildNavItem(
            icon: Icons.home,
            index: 1,
            isActive: currentIndex == 1,
            label: localizations.home,
          ),
          
          // Profile Icon or Profile Picture
          _buildProfileNavItem(
            index: 2,
            isActive: currentIndex == 2,
            label: localizations.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required bool isActive,
    required String label,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileNavItem({
  required int index,
  required bool isActive,
  required String label,
}) {
  return Consumer<AuthProvider>(
    builder: (context, authProvider, child) {
      final isSignedIn = authProvider.isSignedIn;
      final userPhotoUrl = authProvider.userPhotoUrl;

      // Debug prints
      print('🔐 BottomNavBar - isSignedIn: $isSignedIn');
      print('🔐 BottomNavBar - userPhotoUrl: $userPhotoUrl');

      return GestureDetector(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSignedIn && userPhotoUrl != null && userPhotoUrl.isNotEmpty)
              // Show profile picture when signed in
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.network(
                    userPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Error loading profile image: $error');
                      return Icon(
                        Icons.person,
                        size: 20,
                        color: isActive ? Colors.white : Colors.grey,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        print('✅ Profile image loaded successfully');
                        return child;
                      }
                      print('🔄 Loading profile image...');
                      return Icon(
                        Icons.person,
                        size: 20,
                        color: isActive ? Colors.white : Colors.grey,
                      );
                    },
                  ),
                ),
              )
            else if (isSignedIn)
              // Show person icon when signed in but no profile picture
              Icon(
                Icons.person,
                size: 26,
                color: isActive ? Colors.white : Colors.grey,
              )
            else
              // Show regular person icon when not signed in
              Icon(
                Icons.person,
                size: 26,
                color: isActive ? Colors.white : Colors.grey,
              ),
          ],
        ),
      );
    },
  );
}}