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
  bool _showNewNewsIndicator = false;
  int _newNewsCount = 0;
  int _lastNewsCount = 0;
  bool _isRefreshing = false;
  int _lastHomeTapTime = 0;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
      _initializeNewsMonitoring();
    });
  }

  void _initializeNewsMonitoring() {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    _lastNewsCount = newsProvider.allNews.length;
    _startNewsMonitoring();
  }

  void _startNewsMonitoring() {
    // Check for new news every 2 minutes
    Future.delayed(Duration(minutes: 2), () {
      if (mounted) {
        _checkForNewNews();
      }
    });
  }

  void _checkForNewNews() {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final currentCount = newsProvider.allNews.length;
    
    if (currentCount > _lastNewsCount && widget.currentIndex == 1) {
      final newCount = currentCount - _lastNewsCount;
      _showNewNewsIndicator = true;
      _newNewsCount = newCount;
      _lastNewsCount = currentCount;
      
      if (mounted) {
        setState(() {});
      }
      
      // Auto hide after 8 seconds
      Future.delayed(Duration(seconds: 8), () {
        if (mounted && _showNewNewsIndicator) {
          setState(() {
            _showNewNewsIndicator = false;
          });
        }
      });
    }
    
    _startNewsMonitoring();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
      _showNewNewsIndicator = false;
    });

    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    
    try {
      newsProvider.refreshNews();
      
      // Wait for refresh to complete
      await Future.delayed(Duration(seconds: 2));
      
      _lastNewsCount = newsProvider.allNews.length;
    } catch (e) {
      // Silent fail - no snackbar
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _onBottomNavTap(int index) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // If user taps home icon while already on home page, refresh news
    if (index == 1 && widget.currentIndex == 1) {
      // Check if it's a quick double-tap (within 500ms)
      if (currentTime - _lastHomeTapTime < 500) {
        _handleRefresh();
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
    
    final localizations = AppLocalizations.of(context);
    if (englishCategory == 'Bookmarks' && !newsProvider.hasBookmarks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations?.signInToSave ?? 'No bookmarks yet! Save some articles first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    newsProvider.setCategory(englishCategory);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });
  }

  Widget _buildNewNewsIndicator() {
    if (!_showNewNewsIndicator) return SizedBox.shrink();
    
    final screenWidth = MediaQuery.of(context).size.width;
    final localizations = AppLocalizations.of(context);
    
    return GestureDetector(
      onTap: _handleRefresh,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.025,
        ),
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.015,
        ),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(color: Colors.blue.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: screenWidth * 0.02,
              spreadRadius: screenWidth * 0.005,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.new_releases,
                    color: Colors.white,
                    size: screenWidth * 0.045,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_newNewsCount ${localizations?.newNewsAvailable ?? 'New News Available'}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tap to refresh',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              Icons.refresh,
              color: Colors.blue.shade600,
              size: screenWidth * 0.05,
            ),
          ],
        ),
      ),
    );
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
    _categoriesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 8),
                if (widget.currentIndex == 1) ...[
                  _buildCategoriesList(),
                  _buildNewNewsIndicator(),
                ],
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
            
            // Modern refresh indicator - like Facebook/Instagram
            if (_isRefreshing)
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Refreshing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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