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

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });
  }

  // FIXED: Get ALL categories including dynamic ones
  List<String> _getLocalizedCategories(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return newsProvider.categories; // Use actual categories from provider
    
    // Map ALL categories (both static and dynamic) to localized versions
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

  // FIXED: Map ALL localized categories back to English
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
    
    // Map the selected category to localized version for comparison
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

  // Helper method to get localized name for a single category
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
    
    // Map the localized category back to English for the provider
    final englishCategory = _mapToEnglishCategory(category, context);
    
    // Check if it's bookmarks category
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
    
    print('🟢 [LandingPage] Setting category: $englishCategory');
    newsProvider.setCategory(englishCategory);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });
  }

  void _onBottomNavTap(int index) {
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

  @override
  void dispose() {
    _categoriesScrollController.dispose();
    super.dispose();
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
              
              // Get the English version of the current selected category
              final englishSelectedCategory = newsProvider.selectedCategory;
              // Get the localized version of the selected category
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
                          ? screenWidth * 0.045 
                          : screenWidth * 0.04,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8),
            if (widget.currentIndex == 1) _buildCategoriesList(),
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