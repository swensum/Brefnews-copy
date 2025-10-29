import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/authservice.dart';
import '../language/app_localizations.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _currentUsername;
  String? _currentBio;
  String? _userPhotoUrl;
  String? _userNameFromAuth;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user data from AuthService
      final userData = await AuthService.getCurrentUser();
      if (userData != null) {
        _userNameFromAuth = userData['displayName'];
        _userPhotoUrl = userData['photoURL'];
      }

      // Get profile data from Supabase
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('user_profiles')
            .select('username, bio')
            .eq('id', user.id)
            .maybeSingle(); 

      if (response != null) {
        _currentUsername = response['username'];
        _currentBio = response['bio'];
      } else {
        _currentUsername = null;
        _currentBio = null;
      }
        _usernameController.text = _currentUsername ?? _userNameFromAuth ?? '';
        _bioController.text = _currentBio ?? '';
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final updates = {
          'id': user.id,
          'username': _usernameController.text.trim(),
          'bio': _bioController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Upsert the profile data
        await _supabase
            .from('user_profiles')
            .upsert(updates);

        // Show success dialog
        if (mounted) {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
void _showSuccessDialog() {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final overlayState = Overlay.of(context);
final localizations = AppLocalizations.of(context)!;
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: screenHeight * 0.08,
      left: screenWidth * 0.3,
      right: screenWidth * 0.3,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02,
            vertical: screenWidth * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            localizations.profileUpdate,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  // Show overlay first
  overlayState.insert(overlayEntry);

  
  Future.delayed(Duration(milliseconds: 1500), () {
    overlayEntry.remove();
    if (mounted) {
      context.pop();
    }
  });
}
  String? _validateUsername(String? value) {
    final localizations = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return localizations.pleaseEnterUsername;
    }
    if (value.length > 20) {
      return localizations.usernameLengthError;
    }
    if (!RegExp(r'^[a-zA-Z0-9_ ]+$').hasMatch(value)) {
      return localizations.usernameFormatError;
    }
    return null;
  }

  String? _validateBio(String? value) {
     final localizations = AppLocalizations.of(context)!;
    if (value != null && value.length > 120) {
      return localizations.bioLengthError;
    }
    return null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
 final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
            size: screenWidth * 0.06,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          localizations.editProfile,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.045,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.02),

                    // Profile Image (from Google - read only)
                    CircleAvatar(
                      radius: screenWidth * 0.12,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _userPhotoUrl != null
                          ? NetworkImage(_userPhotoUrl!)
                          : null,
                      child: _userPhotoUrl == null
                          ? Icon(
                              Icons.person,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              size: screenWidth * 0.1,
                            )
                          : null,
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // Name Field
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        localizations.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    TextFormField(
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface,),
                      controller: _usernameController,
                      cursorColor: Theme.of(context).colorScheme.onSurface, 
                      decoration: InputDecoration(
                        hintText: localizations.enterYourName,
                        hintStyle: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.02,
                        ),
                      ),
                      validator: _validateUsername,
                      maxLength: 20,
                      buildCounter: (context,
                          {required currentLength, required isFocused, maxLength}) {
                        return Text(
                          '$currentLength/$maxLength',
                          style: TextStyle(
                            color: currentLength > maxLength!
                                ? Colors.red
                                : Colors.grey,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Bio Field
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        localizations.yourBio,
                        style: TextStyle(
                          color:Theme.of(context).colorScheme.onSurface, 
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    TextFormField(
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, ),
                      controller: _bioController,
                      cursorColor: Theme.of(context).colorScheme.onSurface, 
                      decoration: InputDecoration(
                        hintText: localizations.bioPlaceholder,
                         hintStyle: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline,),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary,),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.02,
                        ),
                      ),
                      validator: _validateBio,
                      maxLines: 4,
                      maxLength: 120,
                      buildCounter: (context,
                          {required currentLength, required isFocused, maxLength}) {
                        return Text(
                          '$currentLength/$maxLength',
                          style: TextStyle(
                            color: currentLength > maxLength!
                                ? Colors.red
                                : Colors.grey,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.08),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.06,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Theme.of(context).colorScheme.outline,
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary,),
                                ),
                              )
                            : Text(
                                localizations.updateProfile,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}