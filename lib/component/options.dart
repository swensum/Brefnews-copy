import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../language/app_localizations.dart';
import '../provider/auth_provider.dart';
import '../provider/themeprovider.dart';
import '../provider/language_provider.dart';
import '../provider/news_provider.dart';
class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  bool _isSignedIn = false;
  String _signedInMethod = '';
  String? _userName;
  String? _userEmail;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    setState(() {
      _isSignedIn = authProvider.isSignedIn;
      if (authProvider.isSignedIn) {
        _signedInMethod = authProvider.signInMethod ?? ''; // Use the new getter
        _userName = authProvider.userName;
        _userEmail = authProvider.userEmail;
        _userPhotoUrl = authProvider.userPhotoUrl;
      }
    });
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signOut();

    if (success && context.mounted) {
      setState(() {
        _isSignedIn = false;
        _signedInMethod = '';
        _userName = null;
        _userEmail = null;
        _userPhotoUrl = null;
      });

      _showLogoutSuccessDialog();
    }
  }

  void _showLogoutSuccessDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final overlayState = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: screenHeight * 0.18,
        left: screenWidth * 0.3,
        right: screenWidth * 0.3,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.002,
              vertical: screenWidth * 0.02,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Signed out successfully!',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    // Insert the overlay
    overlayState.insert(overlayEntry);

    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Widget _getAuthMethodIcon() {
    switch (_signedInMethod) {
      case 'google':
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
            fit: BoxFit.contain,
          ),
        );
      case 'phone':
        return const Icon(Icons.phone, color: Colors.green, size: 24);
      case 'email':
        return Icon(Icons.email, color: Colors.blue[700], size: 24);
      default:
        return const Icon(Icons.person, color: Colors.grey, size: 24);
    }
  }

  // Add this method for language bottom sheet
  void _showLanguageBottomSheet() {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final localizations = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: screenHeight * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.language,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Current language display
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Current: ${languageProvider.currentLanguageName}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Language list
            Expanded(
              child: ListView.builder(
                itemCount: languageProvider.supportedLanguageNames.length,
                itemBuilder: (context, index) {
                  final languageName =
                      languageProvider.supportedLanguageNames[index];
                  final languageCode =
                      languageProvider.supportedLanguageCodes[index];

                  return GestureDetector(
                    onTap: () async {
                      await languageProvider.setLanguage(languageCode);
                      if (!context.mounted) return;
                      final newsProvider = Provider.of<NewsProvider>(
                        context,
                        listen: false,
                      );
                      await newsProvider.setLanguage(languageCode);
                      if (!context.mounted) return;
                      // Show snackbar for restart recommendation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Language changed to $languageName. Some text may require app restart.',
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              languageName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),

                          // Checkmark for current language
                          if (languageProvider.currentLanguage == languageCode)
                            Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeleteAccount() {
  
  // Show confirmation dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(
        'Delete Account',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close confirmation dialog
            _performAccountDeletion();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _performAccountDeletion() async {
  
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Deleting your account...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.deleteAccount();

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      
      if (success) {
        // Update local state
        setState(() {
          _isSignedIn = false;
          _signedInMethod = '';
          _userName = null;
          _userEmail = null;
          _userPhotoUrl = null;
        });

        // Show success message
        _showDeleteSuccessDialog();
      } else {
        // Show error message
        _showDeleteErrorDialog();
      }
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      _showDeleteErrorDialog();
    }
  }
}

void _showDeleteSuccessDialog() {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final overlayState = Overlay.of(context);

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: screenHeight * 0.18,
      left: screenWidth * 0.3,
      right: screenWidth * 0.3,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.002,
            vertical: screenWidth * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Account deleted successfully!',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  overlayState.insert(overlayEntry);

  Future.delayed(Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

void _showDeleteErrorDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Deletion Failed',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Failed to delete your account. Please try again later or contact support.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'OK',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;

    // Check if current language is English
    final bool isEnglish = languageProvider.currentLanguage == 'en';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  elevation: 0,
  leading: IconButton(
    icon: Icon(
      Icons.arrow_back,
      color: Theme.of(context).colorScheme.onSurface,
      size: screenWidth > 600 ? 38 : screenWidth * 0.06, // Fixed size for iPad
    ),
    onPressed: () => Navigator.of(context).pop(),
  ),
  title: Container(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width > 600 
          ? MediaQuery.of(context).size.width * 0.7 // 70% width on iPad
          : double.infinity, 
    ),
    child: Text(
      localizations.options,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.bold,
        fontSize: screenWidth > 600 ? 28 : screenWidth * 0.045, // Fixed font size for iPad
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
  ),
  centerTitle: false,
  actions: [
    if (_isSignedIn)
      Padding(
        padding: EdgeInsets.only(
          right: screenWidth > 600 ? 16 : screenWidth * 0.04,
        ),
        child: PopupMenuButton<String>(
          icon: CircleAvatar(
            radius: screenWidth > 600 ? 20 : screenWidth * 0.04,
            backgroundColor: Colors.blue[100],
            child: _userPhotoUrl != null
                ? CircleAvatar(
                    radius: screenWidth > 600 ? 20 : screenWidth * 0.04,
                    backgroundImage: NetworkImage(_userPhotoUrl!),
                  )
                : Stack(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                        size: screenWidth > 600 ? 22 : screenWidth * 0.05,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: _getAuthMethodIcon(),
                        ),
                      ),
                    ],
                  ),
  ),
  onSelected: (value) {
    if (value == 'delete') {
        _handleDeleteAccount();
    } else if (value == 'logout') {
      _handleLogout();
    }
  },
  itemBuilder: (BuildContext context) => [
    if (_userName != null)
      PopupMenuItem<String>(
        value: 'profile',
        enabled: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                  color: Colors.black,
                ),
              ),
              if (_userEmail != null)
                Text(
                  _userEmail!,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[800],
                  ),
                ),
            ],
          ),
        ),
      ),
    // Add Delete Account option here
    PopupMenuItem<String>(
      value: 'delete',
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Delete Account', 
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    ),
    PopupMenuItem<String>(
      value: 'logout',
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text(
              localizations.logout,
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    ),
  ],
  color: Theme.of(context).colorScheme.onPrimary,
),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          
            if (!_isSignedIn)
              GestureDetector(
                onTap: () {
                  context.push('/signin');
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading
                      Text(
                        localizations.saveYourPreferences,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),

                      // Subtitle
                      Text(
                        localizations.signInToSave,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: screenWidth * 0.038,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Row(
                        children: [
                          // Sign In Button
                          Container(
                            width: screenWidth * 0.2,
                            height: screenHeight * 0.07,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimary,
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.01,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                localizations.signIn,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.3),

                          Row(
                            children: [
                              // Google Icon
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: screenWidth * 0.003,
                                  ),
                                ),
                                child: Image.network(
                                  'https://developers.google.com/identity/images/g-logo.png',
                                  width: screenWidth * 0.06,
                                  height: screenWidth * 0.06,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),

                              // Mobile Icon
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: screenWidth * 0.003,
                                  ),
                                ),
                                child: Icon(
                                  Icons.mail,
                                  color: Colors.blue,
                                  size: screenWidth * 0.06,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),

// Apple Icon - Only show on Apple devices
if (defaultTargetPlatform == TargetPlatform.iOS || 
    defaultTargetPlatform == TargetPlatform.macOS)
  Container(
    padding: EdgeInsets.all(screenWidth * 0.02),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.grey[300]!,
        width: screenWidth * 0.003,
      ),
    ),
    child: Icon(
      Icons.apple,
      color: Colors.black,
      size: screenWidth * 0.06,
    ),
  ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            Column(
              children: [
                _buildListOptionWithValue(
                  context,
                  icon: Icons.language,
                  title: localizations.language,
                  value: languageProvider.currentLanguageName,
                  showDivider: true,
                  onTap: _showLanguageBottomSheet,
                ),

                // Notifications
                _buildListOption(
                  context,
                  icon: Icons.notifications,
                  title: localizations.notifications,
                  showDivider: true,
                  onTap: () {
                    // Navigate to Notification Settings Page
                    context.push('/notification');
                  },
                ),

                // Your Preference - Only show if language is English
                if (isEnglish)
                  _buildListOption(
                    context,
                    icon: Icons.settings,
                    title: localizations.yourPreference,
                    showDivider: true,
                    onTap: () {
                      // Navigate to PreferencePage
                      context.push('/preference');
                    },
                  ),

                // Night Mode with subtitle
                Container(
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.04,
                    top: screenHeight * 0.03,
                    bottom: screenHeight * 0.02,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.nightlight_round,
                        color: Theme.of(context).colorScheme.primary,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.nightMode,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              localizations.nightModeDescription,
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                // White Container Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.14,
                    right: screenWidth * 0.04,
                    bottom: screenHeight * 0.03,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(55, 227, 227, 227),
                  ),
                  child: Column(
                    children: [
                      // Share this App
                      _buildWhiteContainerOption(
                        context,
                        title: localizations.shareThisApp,
                        onTap: () {},
                      ),

                      // Rate this App
                      _buildWhiteContainerOption(
                        context,
                        title: localizations.rateThisApp,
                        onTap: () {},
                      ),

                      // Feedback
                      _buildWhiteContainerOption(
                        context,
                        title: localizations.feedback,
                        onTap: () {
                          // Navigate to FeedbackPage
                          context.push('/feedback');
                        },
                      ),

                      // Terms & Conditions
                      _buildWhiteContainerOption(
                        context,
                        title: localizations.termsConditions,
                         onTap: () {
                          context.push('/terms-conditions');
                        },
                      ),

                      // Privacy
                      _buildWhiteContainerOption(
                        context,
                        title: localizations.privacy,
                        onTap: () {
                          // Navigate to PrivacyPolicyPage
                          context.push('/privacy');
                        },
                      ),
                       _buildWhiteContainerOption(
                        context,
                        title: localizations.contact,
                        onTap: () {
                          
                          context.push('/contact');
                        },
                      ),
                    ],

                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: screenWidth * 0.04,
          right: screenWidth * 0.04,
          top: screenHeight * 0.03,
          bottom: screenHeight * 0.03,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: showDivider
                ? BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: screenWidth * 0.002,
                  )
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: screenWidth * 0.06,
            ),
            SizedBox(width: screenWidth * 0.04),
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              size: screenWidth * 0.04,
            ),
          ],
        ),
      ),
    );
  }

  // New method for options with values (like language)
  Widget _buildListOptionWithValue(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: screenWidth * 0.04,
          right: screenWidth * 0.04,
          top: screenHeight * 0.03,
          bottom: screenHeight * 0.03,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: showDivider
                ? BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: screenWidth * 0.002,
                  )
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: screenWidth * 0.06,
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            // Current language value
            Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              size: screenWidth * 0.04,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteContainerOption(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.028),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: screenWidth * 0.04,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ],
        ),
      ),
    );
  }
}