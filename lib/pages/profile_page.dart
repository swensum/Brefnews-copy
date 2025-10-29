// profile_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../language/app_localizations.dart';
import '../provider/auth_provider.dart';
import '../provider/news_provider.dart';
import '../models/news_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Refresh auth status when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),

              // Top Right Settings & Feedback
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Feedback Container
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.007,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        context.push('/feedback');
                      },
                      child: Text(
                        localizations.feedback,
                        style: TextStyle(
                          color: Theme.of(context).hintColor, 
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.001),
                  // Settings Icon
                  IconButton(
                    onPressed: () {
                      context.push('/option');
                    },
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Theme.of(context).colorScheme.onSurface, 
                      size: screenWidth * 0.07,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),

              // Show User Profile if signed in, otherwise show Sign In Container
              if (authProvider.isSignedIn)
                // User Profile Section
                Center(
                  child: Column(
                    children: [
                      // Profile Image
                      CircleAvatar(
                        radius: screenWidth * 0.09,
                        backgroundColor: Theme.of(context).colorScheme.outline,
                        backgroundImage: authProvider.userPhotoUrl != null
                            ? NetworkImage(authProvider.userPhotoUrl!)
                            : null,
                        child: authProvider.userPhotoUrl == null
                            ? Icon(
                                Icons.person,
                                color:Theme.of(context).textTheme.bodyLarge?.color,
                                size: screenWidth * 0.1,
                              )
                            : null,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                  
                      // Username
                      Text(
                        authProvider.userName ?? 'User',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Edit Profile Button with Icon
                      Container(
                        width: screenWidth * 0.35,
                        height: screenHeight * 0.045,
                        decoration: BoxDecoration(
                          color:  Theme.of(context).colorScheme.outline,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            context.push('/edit-profile');
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                color: Theme.of(context).hintColor,
                                size: screenWidth * 0.04,
                              ),
                              SizedBox(width: screenWidth * 0.015),
                              Text(
                                localizations.editProfile,
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
               
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(74, 81, 122, 137),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color.fromARGB(56, 33, 149, 243)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFeatureRow(
                        context,
                        icon: Icons.person_outline,
                        title: localizations.getPersonalizedFeedOnAnyDevice,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildFeatureRow(
                        context,
                        icon: Icons.bookmark_border,
                        title: localizations.accessBookmarksOnAnyDevice,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Container(
                        width: double.infinity,
                        height: screenHeight * 0.06,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimary, 
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color.fromARGB(56, 33, 149, 243)),
                        ),
                        child: TextButton(
                          onPressed: () {
                            context.push('/signin');
                          },
                          child: Text(
                           localizations.signInNow,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: screenHeight * 0.04),

              // Saved Section Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.saved,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    width: screenWidth * 0.13,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),

              // Saved Items List
              Expanded(
                child: Consumer<NewsProvider>(
                  builder: (context, newsProvider, child) {
                    final bookmarkedNews = newsProvider.bookmarkedNews;
                    
                    if (bookmarkedNews.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              color: Theme.of(context).colorScheme.onSurface, 
                              size: screenWidth * 0.15,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              localizations.noSavedArticles,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface, 
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              localizations.tapTheBookmarkIconToSaveArticles,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: screenWidth * 0.037,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: bookmarkedNews.length,
                      itemBuilder: (context, index) {
                        final news = bookmarkedNews[index];
                        return _savedItem(
                          context,
                          news: news,
                          savedAt: newsProvider.getBookmarkDate(news),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context,
      {required IconData icon, required String title}) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Container(
          width: screenWidth * 0.1,
          height: screenWidth * 0.1,
          decoration: BoxDecoration(
            color: const Color.fromARGB(73, 142, 189, 206),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color:Theme.of(context).colorScheme.primary, 
              size: screenWidth * 0.06,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, 
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _savedItem(BuildContext context, {
    required News news,
    required DateTime savedAt,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    String formattedDate = _formatSavedDate(savedAt);

    return GestureDetector(
      onTap: () {
        context.push('/bookmarks', extra: news);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02, vertical: screenHeight * 0.015),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saved Date & Time
            Text(
              formattedDate,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleMedium?.color,
                fontSize: screenWidth * 0.033,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),

            // News content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: screenWidth * 0.042,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      news.imageUrl!,
                      width: screenWidth * 0.18,
                      height: screenWidth * 0.18,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: screenWidth * 0.18,
                          height: screenWidth * 0.18,
                          decoration: BoxDecoration(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.article,
                            color: Theme.of(context).colorScheme.outlineVariant, 
                            size: screenWidth * 0.08,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: screenWidth * 0.18,
                    height: screenWidth * 0.18,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.article,
                      color: Theme.of(context).colorScheme.onSurface, 
                      size: screenWidth * 0.08,
                    ),
                  ),
              ],
            ),

            SizedBox(height: screenHeight * 0.01),
            // Bar separator
            Container(
              width: double.infinity,
              height: 1,
              color: Theme.of(context).colorScheme.outline, 
            ),
          ],
        ),
      ),
    );
  }

  String _formatSavedDate(DateTime savedAt) {
    final day = savedAt.day.toString().padLeft(2, '0');
    final month = savedAt.month.toString().padLeft(2, '0');
    final year = savedAt.year.toString();
    final hour = savedAt.hour % 12 == 0 ? 12 : savedAt.hour % 12;
    final minute = savedAt.minute.toString().padLeft(2, '0');
    final period = savedAt.hour < 12 ? 'AM' : 'PM';

    return '$day/$month/$year - $hour:$minute $period';
  }
}