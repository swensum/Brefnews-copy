import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/email.dart';

import '../component/bookmark.dart';
import '../component/editprofile.dart';
import '../component/feedback.dart';
import '../component/feedbackdetail.dart';
import '../component/headlinelist.dart';
import '../component/headlines.dart';
import '../component/notification.dart';
import '../component/options.dart';
import '../component/signin.dart';
import '../component/topics_detail_page.dart';
import '../landingpage.dart';
import '../models/news_model.dart';
import '../options/language.dart';
import '../options/preference.dart';
import '../pages/profile_page.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';

import '../pages/splashscreen.dart';
import '../repositories/notificationsetting.dart';
import '../utilities/topic.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Zoom-out animation
              return ScaleTransition(
                scale: Tween<double>(
                  begin: 1.2,  
                  end: 1.0,   
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutQuart, 
                  ),
                ),
                child: child,
              );
            },
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return LandingPageWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: HomePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: child,
                  );
                },
              );
            },
          ),
         
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const SearchPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: child,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const ProfilePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: child,
                  );
                },
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/feedback',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const FeedbackPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
       GoRoute(
      path: '/feedback-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return NewFeedbackPage(
          onFeedbackSubmitted: extra?['onFeedbackSubmitted'],
          newsHeadline: extra?['newsHeadline'] ?? '',
        );
      },
    ),
      GoRoute(
        path: '/notification',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const NotificationSettingsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/option',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const OptionsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const EditProfilePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/signin',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SignInPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/email-signin',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const EmailSignInPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/topic',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AllTopicsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
       GoRoute(
        path: '/language',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LanguagePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/preference',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const PreferencePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
GoRoute(
  path: '/notifications',
  pageBuilder: (context, state) {
    final news = state.extra as News?;
    return CustomTransitionPage(
      key: state.pageKey,
      child: NotificationPage(initialNews: news),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0), // Right to left
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  },
),
      
      // Topics Detail route with sliding animation
      GoRoute(
        path: '/topics-detail',
        pageBuilder: (context, state) {
          final extraData = state.extra as Map<String, dynamic>;
          final topic = extraData['topic'] as Map<String, dynamic>;
          final initialNews = extraData['initialNews'] as News?;
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: TopicsDetailPage(
              topic: topic,
              initialNews: initialNews,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
      
      // Bookmarks route with sliding animation
      GoRoute(
        path: '/bookmarks',
        pageBuilder: (context, state) {
          final news = state.extra as News?; 
          return CustomTransitionPage(
            key: state.pageKey,
            child: BookmarkPage(initialNews: news),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          );
        },
      ),
     GoRoute(
  path: '/headlines',
  pageBuilder: (context, state) {
    final extraData = state.extra as Map<String, dynamic>;
    final headline = extraData['headline'] as Map<String, dynamic>; // Change 'topic' to 'headline'
    final initialNews = extraData['initialNews'] as News?;
    
    return CustomTransitionPage(
      key: state.pageKey,
      child: HeadlinesDetailPage(
        headline: headline, // Add the required headline parameter
        initialNews: initialNews,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  },
),
GoRoute(
  path: '/headlines-listing',
  pageBuilder: (context, state) {
    final extraData = state.extra as Map<String, dynamic>;
    final initialHeadline = extraData['initialHeadline'] as Map<String, dynamic>;
    final allHeadlines = extraData['allHeadlines'] as List<Map<String, dynamic>>;
    
    return CustomTransitionPage(
      key: state.pageKey,
      child: HeadlinesListingPage(
        initialHeadline: initialHeadline,
        allHeadlines: allHeadlines,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  },
),
    ],
  );
}

class LandingPageWrapper extends StatefulWidget {
  final Widget child;

  const LandingPageWrapper({super.key, required this.child});

  @override
  State<LandingPageWrapper> createState() => _LandingPageWrapperState();
}

class _LandingPageWrapperState extends State<LandingPageWrapper> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    // Listen to route changes to update bottom nav
    final route = GoRouterState.of(context).matchedLocation;
    
    // Update current index based on route
    if (route == '/home') {
      _currentIndex = 1;
    } else if (route == '/search') {
      _currentIndex = 0;
    } else if (route == '/profile') {
      _currentIndex = 2;
    }

    return LandingPage(
      currentIndex: _currentIndex,
      child: widget.child,
    );
  }
}