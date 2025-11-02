import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'language/app_localizations.dart';
import 'provider/news_provider.dart' show NewsProvider;
import '../component/bottombar.dart';

class LandingPage extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const LandingPage({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _categoriesScrollController = ScrollController();
  final bool _showNewNewsIndicator = false;
  int _lastNewsCount = 0;
  bool _isRefreshing = false;
  int _lastHomeTapTime = 0;
  DateTime? _lastCheckTime;
  int _monitoringCycle = 0;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    
    print('🟢 [LandingPage] initState called');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
      _initializeNewsMonitoring();
    });
  }

  void _initializeNewsMonitoring() {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    _lastNewsCount = newsProvider.allNews.length;
    _lastCheckTime = DateTime.now();
    
    print('🟢 [NewsMonitor] Initialized - Last count: $_lastNewsCount, Time: $_lastCheckTime');
    
    _startNewsMonitoring();
  }

  void _startNewsMonitoring() {
    _monitoringCycle++;
    print('🟢 [NewsMonitor] Starting cycle $_monitoringCycle at ${DateTime.now()}');
    
    // Check for new news every 2 minutes
    Future.delayed(Duration(minutes: 2), () {
      if (mounted) {
        print('🟢 [NewsMonitor] 2 minutes elapsed, checking for new news...');
        _checkForNewNews();
      } else {
        print('🔴 [NewsMonitor] Widget not mounted, skipping check');
      }
    });
  }

  Future<void> _checkForNewNews() async {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final currentTime = DateTime.now();
    
    print('🟢 [NewsMonitor] Checking at $currentTime');
    print('🟢 [NewsMonitor] Last count: $_lastNewsCount');
    print('🟢 [NewsMonitor] Current page index: ${widget.currentIndex}, Is home page: ${widget.currentIndex == 1}');
    print('🟢 [NewsMonitor] Banner currently showing: $_showNewNewsIndicator');
    
    try {
      print('🟢 [NewsMonitor] 🔄 FETCHING FRESH DATA FROM SERVER...');
      
      // Actually fetch new data from server
      await newsProvider.refreshNews();
      
      // Give it a moment to update the provider state
      await Future.delayed(Duration(milliseconds: 500));
      
      final currentCount = newsProvider.allNews.length;
      print('🟢 [NewsMonitor] Fresh data fetched - Current count: $currentCount');
      
      if (currentCount > _lastNewsCount && widget.currentIndex == 1) {
        final newCount = currentCount - _lastNewsCount;
        print('🟢 [NewsMonitor] 🎉 NEW NEWS DETECTED! Count increased by $newCount');
        
        _showModernPopDown('News updated');
        _lastNewsCount = currentCount;
        
        // Auto hide after 3 seconds
        Future.delayed(Duration(seconds: 3), () {
          _hideModernPopDown();
        });
      } else {
        if (currentCount <= _lastNewsCount) {
          print('🟢 [NewsMonitor] No new news - count unchanged or decreased');
        } else {
          print('🟢 [NewsMonitor] New news detected but not on home page');
        }
        
        // Update last count even if no new news
        _lastNewsCount = currentCount;
      }
      
    } catch (e) {
      print('🔴 [NewsMonitor] Error fetching fresh data: $e');
    }
    
    _lastCheckTime = currentTime;
    print('🟢 [NewsMonitor] Check completed, starting next cycle');
    _startNewsMonitoring();
  }

  void _showModernPopDown(String message) {
    // Remove existing overlay if any
    _hideModernPopDown();
    
    final overlayState = Overlay.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: screenWidth * 0.1,
        right: screenWidth * 0.1,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.015,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: screenWidth * 0.05,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlayState.insert(_overlayEntry!);
  }

  void _hideModernPopDown() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    print('🟢 [Refresh] Manual refresh triggered');
    
    _showModernPopDown('Refreshing...');
    
    setState(() {
      _isRefreshing = true;
    });

    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    
    try {
      print('🟢 [Refresh] Calling newsProvider.refreshNews()');
      await newsProvider.refreshNews();
      
      // Update the count after refresh
      _lastNewsCount = newsProvider.allNews.length;
      
      // Show success message
      _hideModernPopDown();
      _showModernPopDown('News updated');
      
      print('🟢 [Refresh] Refresh completed - new count: $_lastNewsCount');
    } catch (e) {
      print('🔴 [Refresh] Error during refresh: $e');
      _hideModernPopDown();
      _showModernPopDown('Update failed');
    } finally {
      Future.delayed(Duration(seconds: 2), () {
        _hideModernPopDown();
      });
      
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        print('🟢 [Refresh] Refresh state reset');
      }
    }
  }

  void _onBottomNavTap(int index) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    print('🟢 [Nav] Bottom nav tapped - index: $index, current index: ${widget.currentIndex}');
    
    // If user taps home icon while already on home page, refresh news
    if (index == 1 && widget.currentIndex == 1) {
      // Check if it's a quick double-tap (within 500ms)
      if (currentTime - _lastHomeTapTime < 500) {
        print('🟢 [Nav] Home double-tap detected, triggering refresh');
        _handleRefresh();
      } else {
        print('🟢 [Nav] Single home tap, no refresh');
      }
      _lastHomeTapTime = currentTime;
    }
    
    switch (index) {
      case 0:
        context.go('/search');
        break;
      case 1:
        context.go('/home');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  // Categories methods
  List<String> _getLocalizedCategories(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return newsProvider.categories;
    
    return newsProvider.categories.map((englishCategory) {
      switch (englishCategory) {
        case 'My Feed': return localizations.myFeed;
        case 'Finance': return localizations.finance;
        case 'Timeline': return localizations.timeline;
        case 'Videos': return localizations.videos;
        case 'Good News': return localizations.goodNews;
        case 'Top Stories': return localizations.topStories;
        case 'Trending': return localizations.trending;
        case 'Bookmarks': return localizations.bookmarks;
        case 'Unread': return localizations.unread;
        default: return englishCategory;
      }
    }).toList();
  }

  String _mapToEnglishCategory(String localizedCategory, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return localizedCategory;
    
    if (localizedCategory == localizations.myFeed) return 'My Feed';
    if (localizedCategory == localizations.finance) return 'Finance';
    if (localizedCategory == localizations.timeline) return 'Timeline';
    if (localizedCategory == localizations.videos) return 'Videos';
    if (localizedCategory == localizations.goodNews) return 'Good News';
    if (localizedCategory == localizations.topStories) return 'Top Stories';
    if (localizedCategory == localizations.trending) return 'Trending';
    if (localizedCategory == localizations.bookmarks) return 'Bookmarks';
    if (localizedCategory == localizations.unread) return 'Unread';
    
    return localizedCategory;
  }

  void _scrollToSelectedCategory() {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final categories = _getLocalizedCategories(context);
    final selectedCategory = newsProvider.selectedCategory;
    
    final selectedLocalized = _getLocalizedCategoryName(selectedCategory, context);
    
    final selectedIndex = categories.indexOf(selectedLocalized);
    if (selectedIndex != -1 && _categoriesScrollController.hasClients) {
      final itemWidth = MediaQuery.of(context).size.width * 0.15;
      final screenWidth = MediaQuery.of(context).size.width;
      final scrollOffset = (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      
      _categoriesScrollController.animateTo(
        scrollOffset.clamp(0.0, _categoriesScrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getLocalizedCategoryName(String englishCategory, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return englishCategory;
    
    switch (englishCategory) {
      case 'My Feed': return localizations.myFeed;
      case 'Finance': return localizations.finance;
      case 'Timeline': return localizations.timeline;
      case 'Videos': return localizations.videos;
      case 'Good News': return localizations.goodNews;
      case 'Top Stories': return localizations.topStories;
      case 'Trending': return localizations.trending;
      case 'Bookmarks': return localizations.bookmarks;
      case 'Unread': return localizations.unread;
      default: return englishCategory;
    }
  }

  void _onCategorySelected(int index, String category) {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    
    final englishCategory = _mapToEnglishCategory(category, context);
    
    AppLocalizations.of(context);
    if (englishCategory == 'Bookmarks' && !newsProvider.hasBookmarks) {
      _showModernPopDown('No bookmarks yet');
      return;
    }
    
    newsProvider.setCategory(englishCategory);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });
  }

  Widget _buildCategoriesList() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final categories = _getLocalizedCategories(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedCategory();
        });

        return SizedBox(
          height: screenWidth * 0.1,
          child: ListView.builder(
            controller: _categoriesScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final englishSelectedCategory = newsProvider.selectedCategory;
              final localizedSelectedCategory = _getLocalizedCategoryName(englishSelectedCategory, context);
              final isSelected = localizedSelectedCategory == category;

              return GestureDetector(
                onTap: () => _onCategorySelected(index, category),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenWidth * 0.02,
                  ),
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.001),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey[300],
                      fontSize: isSelected
                          ? screenWidth * 0.04 
                          : screenWidth * 0.035,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    print('🟢 [LandingPage] dispose called');
    _hideModernPopDown();
    _categoriesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🟢 [LandingPage] build called - Refreshing: $_isRefreshing');
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8),
            if (widget.currentIndex == 1) 
              _buildCategoriesList(),
            Expanded(
              child: widget.child,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNavBar(
          currentIndex: widget.currentIndex,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }
}