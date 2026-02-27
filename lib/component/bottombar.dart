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
    final screenSize = MediaQuery.of(context).size;
    
    return Container(
      height: _calculateNavBarHeight(screenSize),
      decoration: const BoxDecoration(
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
            screenSize: screenSize,
          ),
          
          // Home Icon
          _buildNavItem(
            icon: Icons.home,
            index: 1,
            isActive: currentIndex == 1,
            label: localizations.home,
            screenSize: screenSize,
          ),
          
          // Profile Icon or Profile Picture
          _buildProfileNavItem(
            index: 2,
            isActive: currentIndex == 2,
            label: localizations.profile,
            screenSize: screenSize,
          ),
        ],
      ),
    );
  }

  double _calculateNavBarHeight(Size screenSize) {
    // Adaptive height based on screen size and platform
    if (screenSize.width > 1200) {
      return 60; // iPad Pro landscape, desktop
    } else if (screenSize.width > 600) {
      return 50; // iPad, tablet
    } else {
      // For phones, use a percentage of screen height
      return screenSize.height * 0.07; // 7% of screen height
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required bool isActive,
    required String label,
    required Size screenSize,
  }) {
    final iconSize = _calculateIconSize(screenSize);
    final padding = _calculateIconPadding(screenSize);
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isActive ? Colors.white : Colors.grey,
            ),
            SizedBox(height: _calculateLabelSpacing(screenSize)),
            // Optional: Add label for larger screens
            if (screenSize.width > 600)
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontSize: _calculateFontSize(screenSize),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem({
    required int index,
    required bool isActive,
    required String label,
    required Size screenSize,
  }) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isSignedIn = authProvider.isSignedIn;
        final userPhotoUrl = authProvider.userPhotoUrl;

        return GestureDetector(
          onTap: () => onTap(index),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _calculateIconPadding(screenSize),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSignedIn && userPhotoUrl != null && userPhotoUrl.isNotEmpty)
                  // Show profile picture when signed in
                  Container(
                    width: _calculateProfileImageSize(screenSize),
                    height: _calculateProfileImageSize(screenSize),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? Colors.white : Colors.grey,
                        width: _calculateBorderWidth(screenSize),
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        userPhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: _calculateIconSize(screenSize),
                            color: isActive ? Colors.white : Colors.grey,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Icon(
                            Icons.person,
                            size: _calculateIconSize(screenSize),
                            color: isActive ? Colors.white : Colors.grey,
                          );
                        },
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.person,
                    size: _calculateIconSize(screenSize),
                    color: isActive ? Colors.white : Colors.grey,
                  ),
                
                SizedBox(height: _calculateLabelSpacing(screenSize)),
                
                // Optional: Add label for larger screens
                if (screenSize.width > 600)
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontSize: _calculateFontSize(screenSize),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Calculate icon size based on screen width
  double _calculateIconSize(Size screenSize) {
    if (screenSize.width > 1200) {
      return 32; // Large screens
    } else if (screenSize.width > 600) {
      return 28; // Tablets
    } else {
      // For phones, use responsive calculation
      return screenSize.width * 0.06; // 6% of screen width
    }
  }

  // Calculate profile image size
  double _calculateProfileImageSize(Size screenSize) {
    final iconSize = _calculateIconSize(screenSize);
    return iconSize * 1.2; // Slightly larger than icons
  }

  // Calculate icon padding for better touch targets
  double _calculateIconPadding(Size screenSize) {
    if (screenSize.width > 1200) {
      return 32;
    } else if (screenSize.width > 600) {
      return 24;
    } else {
      return screenSize.width * 0.05; // 5% of screen width
    }
  }

  // Calculate spacing between icon and label
  double _calculateLabelSpacing(Size screenSize) {
    if (screenSize.width > 600) {
      return 4;
    }
    return 0;
  }

  // Calculate font size for labels
  double _calculateFontSize(Size screenSize) {
    if (screenSize.width > 1200) {
      return 14;
    } else if (screenSize.width > 600) {
      return 12;
    } else {
      return 10;
    }
  }

  // Calculate border width for profile image
  double _calculateBorderWidth(Size screenSize) {
    return screenSize.width > 600 ? 2.0 : 1.5;
  }
}