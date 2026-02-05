import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'language/app_localizations.dart';
import 'provider/news_provider.dart' show NewsProvider;
import '../component/bottombar.dart';
import '../pages/home_page.dart';

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
 
  PageController? _pageController;
  
  int _lastNewsCount = 0;
  final bool _isRefreshing = false;
  DateTime? _lastCheckTime;
  int _monitoringCycle = 0;
  OverlayEntry? _overlayEntry;

  int _currentPageIndex = 0;
  bool _isProgrammaticPageChange = false;

  @override
  void initState() {
    super.initState();

    print('🟢 [LandingPage] initState called');

    // ========== CHANGED: Only create controller if on home page ==========
    if (widget.currentIndex == 1) {
      _initializePageController();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.currentIndex == 1) {
        _initializeCategories();
        _scrollToSelectedCategory();
      }
      _initializeNewsMonitoring();
    });
  }

  @override
  void didUpdateWidget(LandingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // ========== FIXED: Handle page controller when switching tabs ==========
    if (oldWidget.currentIndex != 1 && widget.currentIndex == 1) {
      // User entered home page - create controller
      _initializePageController();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCategories();
        _scrollToSelectedCategory();
      });
    } else if (oldWidget.currentIndex == 1 && widget.currentIndex != 1) {
      // User left home page - dispose controller
      _pageController?.dispose();
      _pageController = null;
    }
  }
  void _initializePageController() {
    if (_pageController != null && _pageController!.hasClients) {
      _pageController!.dispose();
    }
    
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  void _initializeCategories() {
   
    if (_pageController == null || widget.currentIndex != 1) return;
    
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final categories = _getLocalizedCategories(context);
    
   
    final currentCategory = _getLocalizedCategoryName(newsProvider.selectedCategory, context);
    _currentPageIndex = categories.indexOf(currentCategory);
    
    if (_currentPageIndex == -1) _currentPageIndex = 0;
    

    _pageController?.jumpToPage(_currentPageIndex);
  }

  void _initializeNewsMonitoring() {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    _lastNewsCount = newsProvider.allNews.length;
    _lastCheckTime = DateTime.now();

    print(
      '🟢 [NewsMonitor] Initialized - Last count: $_lastNewsCount, Time: $_lastCheckTime',
    );

    _startNewsMonitoring();
  }

  void _startNewsMonitoring() {
    _monitoringCycle++;
    print(
      '🟢 [NewsMonitor] Starting cycle $_monitoringCycle at ${DateTime.now()}',
    );

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

    try {
      print('🟢 [NewsMonitor] 🔄 PERFORMING SILENT CHECK...');
      final newCount = await newsProvider.silentRefresh();

      if (newCount > 0) {
        print('🟢 [NewsMonitor] 🎉 $newCount NEW ARTICLES ADDED!');
        
        _showModernPopDown('$newCount new articles');
        _lastNewsCount = newsProvider.allNews.length;

        Future.delayed(const Duration(seconds: 3), () {
          _hideModernPopDown();
        });
      } else {
        print('🟢 [NewsMonitor] No new news — UI not refreshed');
      }
    } catch (e) {
      print('🔴 [NewsMonitor] Error during silent check: $e');
    }

    _lastCheckTime = currentTime;
    print('🟢 [NewsMonitor] Check completed, scheduling next check...');
    _startNewsMonitoring();
  }

  void _showModernPopDown(String message) {
    _hideModernPopDown();

    final overlayState = Overlay.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 50,
        left: screenWidth * 0.25,
        right: screenWidth * 0.25,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.01,
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

  void _onBottomNavTap(int index) {
    print(
      '🟢 [Nav] Bottom nav tapped - index: $index, current index: ${widget.currentIndex}',
    );

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

  List<String> _getLocalizedCategories(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return newsProvider.categories;

    return newsProvider.categories.map((englishCategory) {
      switch (englishCategory) {
        case 'My Feed':
          return localizations.myFeed;
        case 'Finance':
          return localizations.finance;
        case 'Timeline':
          return localizations.timeline;
        case 'Good News':
          return localizations.goodNews;
        case 'Top Stories':
          return localizations.topStories;
        case 'Trending':
          return localizations.trending;
        case 'Bookmarks':
          return localizations.bookmarks;
        case 'Unread':
          return localizations.unread;
        default:
          return englishCategory;
      }
    }).toList();
  }

  String _mapToEnglishCategory(String localizedCategory, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return localizedCategory;

    if (localizedCategory == localizations.myFeed) return 'My Feed';
    if (localizedCategory == localizations.finance) return 'Finance';
    if (localizedCategory == localizations.timeline) return 'Timeline';
    if (localizedCategory == localizations.goodNews) return 'Good News';
    if (localizedCategory == localizations.topStories) return 'Top Stories';
    if (localizedCategory == localizations.trending) return 'Trending';
    if (localizedCategory == localizations.bookmarks) return 'Bookmarks';
    if (localizedCategory == localizations.unread) return 'Unread';

    return localizedCategory;
  }

  void _scrollToSelectedCategory() {
    // Only scroll if we're on home page and controller exists
    if (widget.currentIndex != 1 || _pageController == null) return;
    
    _getLocalizedCategories(context);
    final selectedIndex = _currentPageIndex;

    if (selectedIndex != -1 && _categoriesScrollController.hasClients) {
      final itemWidth = MediaQuery.of(context).size.width * 0.15;
      final screenWidth = MediaQuery.of(context).size.width;
      final scrollOffset =
          (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

      _categoriesScrollController.animateTo(
        scrollOffset.clamp(
          0.0,
          _categoriesScrollController.position.maxScrollExtent,
        ),
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getLocalizedCategoryName(
    String englishCategory,
    BuildContext context,
  ) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return englishCategory;

    switch (englishCategory) {
      case 'My Feed':
        return localizations.myFeed;
      case 'Finance':
        return localizations.finance;
      case 'Timeline':
        return localizations.timeline;
      case 'Good News':
        return localizations.goodNews;
      case 'Top Stories':
        return localizations.topStories;
      case 'Trending':
        return localizations.trending;
      case 'Bookmarks':
        return localizations.bookmarks;
      case 'Unread':
        return localizations.unread;
      default:
        return englishCategory;
    }
  }

  void _onCategorySelected(int index, String category) {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final englishCategory = _mapToEnglishCategory(category, context);

    if (englishCategory == 'Bookmarks' && !newsProvider.hasBookmarks) {
      _showModernPopDown('No bookmarks yet');
      return;
    }

    print('🟢 [LandingPage] Category selected: $englishCategory at index $index');

    _isProgrammaticPageChange = true;

    // Update NewsProvider first
    newsProvider.setCategory(englishCategory);

    // Then update UI state
    setState(() {
      _currentPageIndex = index;
    });

    
    if (_pageController != null) {
      _pageController!.animateToPage(
        index,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ).then((_) {
        _isProgrammaticPageChange = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });
  }

  void _onPageChanged(int page) {
    if (page == _currentPageIndex || _isProgrammaticPageChange) return;
    
    print('🟢 [LandingPage] Page changed to: $page');

    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final categories = _getLocalizedCategories(context);
    
    if (page < categories.length) {
      final category = categories[page];
      final englishCategory = _mapToEnglishCategory(category, context);
      
      // Update the provider with the new category
      newsProvider.setCategory(englishCategory);
      
      setState(() {
        _currentPageIndex = page;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedCategory();
      });
    }
  }

  Widget _buildCategoryPages() {
    final categories = _getLocalizedCategories(context);
    final pageController = _pageController ?? PageController(initialPage: _currentPageIndex);
    
    return PageView.builder(
      controller: pageController,
      itemCount: categories.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        return HomePage();
      },
    );
  }

  Widget _buildCategoriesList() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final categories = _getLocalizedCategories(context);
        if (widget.currentIndex == 1) {
          final currentEnglishCategory = newsProvider.selectedCategory;
          final currentLocalizedCategory = _getLocalizedCategoryName(currentEnglishCategory, context);
          final currentIndexFromProvider = categories.indexOf(currentLocalizedCategory);
          
          if (currentIndexFromProvider != -1 && currentIndexFromProvider != _currentPageIndex && !_isProgrammaticPageChange) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _currentPageIndex = currentIndexFromProvider;
              });
              if (_pageController != null) {
                _pageController!.jumpToPage(currentIndexFromProvider);
              }
              _scrollToSelectedCategory();
            });
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToSelectedCategory();
          });
        }

        return SizedBox(
          height: screenWidth * 0.1,
          child: ListView.builder(
            controller: _categoriesScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = widget.currentIndex == 1 && index == _currentPageIndex;

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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
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
    _pageController?.dispose();
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
            if (widget.currentIndex == 1) _buildCategoriesList(),
            Expanded(
              child: widget.currentIndex == 1 
                  ? _buildCategoryPages()
                  : widget.child,
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