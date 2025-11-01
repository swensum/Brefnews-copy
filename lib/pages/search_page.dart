import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../language/app_localizations.dart';
import '../provider/news_provider.dart';
import '../models/news_model.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _showSearchScreen = false;
  List<News> _searchResults = [];
  int _currentTopicIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  void _loadTopics() {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    newsProvider.fetchTopics().then((_) {
      if (newsProvider.topics.isNotEmpty) {
        final firstTopic = newsProvider.topics[0];
        final topicName = firstTopic['name'] as String;
        newsProvider.fetchNewsByTopic(topicName);
      }
    });
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

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final allNews = newsProvider.allNews;
    final topicNews = newsProvider.topicNews;
    final allAvailableNews = [...allNews, ...topicNews];
    final uniqueNews = <News>[];
    final seenIds = <String>{};

    for (final news in allAvailableNews) {
      if (!seenIds.contains(news.id)) {
        uniqueNews.add(news);
        seenIds.add(news.id);
      }
    }

    final results = uniqueNews.where((news) {
      final searchQuery = query.toLowerCase();

      final titleMatch = news.title.toLowerCase().contains(searchQuery);
      final categoryMatch = news.category.toLowerCase().contains(searchQuery);
      final sourceMatch = news.source.toLowerCase().contains(searchQuery);
      final summaryMatch = news.summary.toLowerCase().contains(searchQuery);
      final categoriesMatch = news.categories.any(
        (cat) => cat.toLowerCase().contains(searchQuery),
      );

      return titleMatch ||
          categoryMatch ||
          sourceMatch ||
          summaryMatch ||
          categoriesMatch;
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchResults.clear();
      _showSearchScreen = false;
    });
  }

  void _handleTopicTap(Map<String, dynamic> topic, BuildContext context) {
    context.push(
      '/topics-detail',
      extra: {'topic': topic, 'initialNews': null},
    );
  }

  void _handleCategoryTap(String englishCategory, BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    print('🟢 [SearchPage] Handling category tap: $englishCategory');
    switch (englishCategory) {
      case 'My Feed':
        newsProvider.setCategory('My Feed');

        newsProvider.loadNews().then((_) {
          if (!context.mounted) return;
          context.go('/home');
        });
        break;

      case 'Bookmarks':
        if (newsProvider.hasBookmarks) {
          newsProvider.addDynamicCategory('Bookmarks');
          newsProvider.setCategory('Bookmarks');
          context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No bookmarks yet! Save some articles first.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        break;

      case 'Top Stories':
      case 'Trending':
      case 'Unread':
        newsProvider.addDynamicCategory(englishCategory);
        newsProvider.setCategory(englishCategory);
        context.go('/home');
        break;

      default:
        newsProvider.addDynamicCategory(englishCategory);
        newsProvider.setCategory(englishCategory);
        newsProvider.loadNews().then((_) {
          if (!context.mounted) return;
          context.go('/home');
        });
        break;
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _showSearchScreen
            ? _buildSearchResultsScreen(screenWidth, screenHeight)
            : _buildMainSearchScreen(screenWidth, screenHeight),
      ),
    );
  }

  Widget _buildMainSearchScreen(double screenWidth, double screenHeight) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(height: screenHeight * 0.02),

        // Search Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Container(
            width: double.infinity,
            height: screenHeight * 0.06,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                children: [
                  SizedBox(width: screenWidth * 0.04),
                  Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                    size: screenWidth * 0.06,
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth * 0.04,
                      ),
                      decoration: InputDecoration(
                        hintText: localizations.searchForNews,
                        hintStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: screenWidth * 0.04,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _searchResults.clear();
                            _showSearchScreen = false;
                          });
                        }
                      },
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _performSearch(value);
                          setState(() {
                            _showSearchScreen = true;
                          });
                        }
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: _clearSearch,
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.primary,
                        size: screenWidth * 0.05,
                      ),
                    ),
                  SizedBox(width: screenWidth * 0.02),
                ],
              ),
            ),
          ),
        ),
        if (!_showSearchScreen)
          Expanded(child: _buildNormalContent(screenWidth, screenHeight)),
        if (_showSearchScreen)
          Expanded(child: _buildSearchResultsScreen(screenWidth, screenHeight)),
      ],
    );
  }

  Widget _buildSearchResultsScreen(double screenWidth, double screenHeight) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSearchScreen = false;
                  });
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: screenWidth * 0.06,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.searchResults,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${localizations.searchingFor} "${_searchController.text}"',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_searchResults.length} ${localizations.found}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Search Results
        Expanded(
          child: _searchResults.isEmpty
              ? _buildNoResultsState(screenWidth, screenHeight)
              : _buildSearchResultsList(screenWidth, screenHeight),
        ),
      ],
    );
  }

  Widget _buildNoResultsState(double screenWidth, double screenHeight) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: Theme.of(context).colorScheme.outlineVariant,
            size: screenWidth * 0.15,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            '${localizations.noResultsFoundFor}"${_searchController.text}"',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outlineVariant,
              fontSize: screenWidth * 0.04,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            localizations.tryDifferentKeywords,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: screenWidth * 0.035,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(double screenWidth, double screenHeight) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final news = _searchResults[index];
        return _buildSearchResultItem(context, news: news);
      },
    );
  }

  Widget _buildSearchResultItem(BuildContext context, {required News news}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        final newsProvider = Provider.of<NewsProvider>(context, listen: false);
        Map<String, dynamic>? foundTopic;
        for (var topic in newsProvider.topics) {
          final topicName = topic['name'] as String;
          if (news.category.toLowerCase().contains(topicName.toLowerCase()) ||
              news.title.toLowerCase().contains(topicName.toLowerCase())) {
            foundTopic = topic;
            break;
          }
        }

        final topic =
            foundTopic ??
            {
              'name': localizations.searchResults,
              'image_url': null,
              'description': 'Results for "${_searchController.text}"',
            };

        context.push(
          '/topics-detail',
          extra: {'topic': topic, 'initialNews': news},
        );
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.title,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      Text(
                        news.category,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        news.source,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: screenWidth * 0.032,
                        ),
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
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: screenWidth * 0.15,
                          height: screenWidth * 0.15,
                          decoration: BoxDecoration(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.article,
                            color: Theme.of(context).colorScheme.outlineVariant,
                            size: screenWidth * 0.06,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: screenWidth * 0.15,
                    height: screenWidth * 0.15,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.article,
                      color: Theme.of(context).colorScheme.outlineVariant,
                      size: screenWidth * 0.06,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildNormalContent(double screenWidth, double screenHeight) {
    final localizations = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight * 0.04),

          // Categories
          Consumer<NewsProvider>(
            builder: (context, newsProvider, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                child: Row(
                  children: [
                    ...newsProvider.searchCategories.map((englishCategory) {
                      final localizedCategory = _getLocalizedCategoryName(
                        englishCategory,
                        context,
                      );
                      return Container(
                        margin: EdgeInsets.only(right: screenWidth * 0.07),
                        child: _buildCategoryItem(
                          context,
                          icon: _getCategoryIcon(englishCategory),
                          title: localizedCategory,
                          onTap: () =>
                              _handleCategoryTap(englishCategory, context),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: screenHeight * 0.03),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.001,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.notifications,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: screenWidth * 0.057,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Container(
                              width: screenWidth * 0.12,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            context.push('/notifications');
                          },
                          child: Text(
                            localizations.viewAll,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Consumer<NewsProvider>(
                builder: (context, newsProvider, child) {
                  final notifiedNews = newsProvider.notifiedNews;
                  final latestNotifications = notifiedNews.take(4).toList();

                  if (notifiedNews.isEmpty) {
                    return SizedBox(
                      height: screenHeight * 0.15,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              color: Theme.of(context).colorScheme.onSecondary,
                              size: screenWidth * 0.15,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              localizations.noNotifications,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondary,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              localizations.youWillSeeNotificationsHere,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                fontSize: screenWidth * 0.035,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                    ),
                    child: Column(
                      children: [
                        ...latestNotifications.asMap().entries.map((entry) {
                          final index = entry.key;
                          final news = entry.value;
                          final isLastItem =
                              index == latestNotifications.length - 1;
                          return _buildNotificationItem(
                            context,
                            news: news,
                            showBottomBar: !isLastItem,
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.03),

          // Topics Section
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.topics,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: screenWidth * 0.057,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.push('/topic');
                      },
                      child: Text(
                        localizations.viewAll,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.008),

                Consumer<NewsProvider>(
                  builder: (context, newsProvider, child) {
                    if (newsProvider.topics.isEmpty) {
                      return Container(
                        width: double.infinity,
                        height: 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      );
                    }

                    final topicCount = newsProvider.topics.length;
                    final maxBarWidth = screenWidth * 0.92;
                    final blueBarWidth = maxBarWidth / topicCount;

                    return Container(
                      width: double.infinity,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Sliding blue bar
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            left: _currentTopicIndex * blueBarWidth,
                            child: Container(
                              width: blueBarWidth,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.001),

                // Smooth Carousel for Topics
                Consumer<NewsProvider>(
                  builder: (context, newsProvider, child) {
                    if (newsProvider.topics.isEmpty) {
                      return SizedBox(
                        height: screenHeight * 0.1,
                        child: Center(
                          child: Text(
                            localizations.noTopicsAvailable,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: screenHeight * 0.19,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.35),
                        itemCount: newsProvider.topics.length,
                        itemBuilder: (context, index) {
                          final topic = newsProvider.topics[index];
                          return _buildAnimatedTopicItem(
                            context,
                            topic: topic,
                            isActive: index == _currentTopicIndex,
                            onTap: () => _handleTopicTap(topic, context),
                          );
                        },
                        onPageChanged: (index) {
                          setState(() {
                            _currentTopicIndex = index;
                          });
                          // Fetch news for the new active topic
                          final newsProvider = Provider.of<NewsProvider>(
                            context,
                            listen: false,
                          );
                          final activeTopic = newsProvider.topics[index];
                          final topicName = activeTopic['name'] as String;
                          newsProvider.fetchNewsByTopic(topicName);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Topic News
          Consumer<NewsProvider>(
            builder: (context, newsProvider, child) {
              if (newsProvider.isLoadingTopicNews) {
                return SizedBox(
                  height: screenHeight * 0.3,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              if (newsProvider.topicNews.isEmpty) {
                return SizedBox.shrink();
              }

              final displayedNews = newsProvider.topicNews.take(4).toList();
              final hasMoreNews = newsProvider.topicNews.length > 4;
              final currentTopic =
                  newsProvider.topics.isNotEmpty &&
                      _currentTopicIndex < newsProvider.topics.length
                  ? newsProvider.topics[_currentTopicIndex]
                  : null;

              return Column(
                children: [
                  ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                    ),
                    itemCount: displayedNews.length,
                    itemBuilder: (context, index) {
                      final news = displayedNews[index];
                      final isLastItem = index == displayedNews.length - 1;
                      return _buildTopicNewsItem(
                        context,
                        news: news,
                        showBottomBar: !isLastItem,
                      );
                    },
                  ),

                  if (hasMoreNews && currentTopic != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          context.push(
                            '/topics-detail',
                            extra: {'topic': currentTopic, 'initialNews': null},
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              localizations.viewMore,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Icon(
                              Icons.arrow_forward,
                              color: Theme.of(context).colorScheme.primary,
                              size: screenWidth * 0.04,
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: screenHeight * 0.02),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopicNewsItem(
    BuildContext context, {
    required News news,
    bool showBottomBar = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        final newsProvider = Provider.of<NewsProvider>(context, listen: false);
        final currentTopic =
            newsProvider.topics.isNotEmpty &&
                _currentTopicIndex < newsProvider.topics.length
            ? newsProvider.topics[_currentTopicIndex]
            : null;

        if (currentTopic != null) {
          context.push(
            '/topics-detail',
            extra: {'topic': currentTopic, 'initialNews': news},
          );
        }
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
            child: Row(
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
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w500,
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
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: screenWidth * 0.15,
                          height: screenWidth * 0.15,
                          decoration: BoxDecoration(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.article,
                            color: Theme.of(context).colorScheme.primary,
                            size: screenWidth * 0.06,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: screenWidth * 0.15,
                    height: screenWidth * 0.15,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.article,
                      color: Theme.of(context).colorScheme.primary,
                      size: screenWidth * 0.06,
                    ),
                  ),
              ],
            ),
          ),
          // Only show bottom bar if showBottomBar is true
          if (showBottomBar)
            Container(
              width: double.infinity,
              height: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTopicItem(
    BuildContext context, {
    required Map<String, dynamic> topic,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topicName = topic['name'] as String;
    final imageUrl = topic['image_url'] as String?;
    final containerSize = isActive ? screenWidth * 0.18 : screenWidth * 0.14;
    final iconSize = isActive ? screenWidth * 0.08 : screenWidth * 0.06;
    final fontSize = isActive ? screenWidth * 0.035 : screenWidth * 0.03;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: containerSize,
                        height: containerSize,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: containerSize,
                            height: containerSize,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.topic,
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                              size: iconSize,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: containerSize,
                        height: containerSize,
                        decoration: BoxDecoration(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.topic,
                          color: Theme.of(context).colorScheme.outlineVariant,
                          size: iconSize,
                        ),
                      ),
              ),
            ),
            SizedBox(height: screenWidth * 0.015),

            Text(
              topicName,
              style: TextStyle(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.titleMedium?.color,
                fontSize: fontSize,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (isActive)
              Container(
                width: screenWidth * 0.08,
                height: 3,
                margin: EdgeInsets.only(top: screenWidth * 0.008),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'My Feed':
        return PhosphorIconsFill.newspaper;
      case 'Top Stories':
        return PhosphorIconsFill.star;
      case 'Trending':
        return PhosphorIconsFill.fire;
      case 'Bookmarks':
        return PhosphorIconsFill.bookmarkSimple;
      case 'Unread':
        return PhosphorIconsFill.envelopeOpen;
      default:
        return PhosphorIconsFill.squaresFour;
    }
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 20),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: screenWidth * 0.13,
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required News news,
    bool showBottomBar = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        context.push('/notifications', extra: news);
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    news.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      news.imageUrl!,
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: screenWidth * 0.15,
                          height: screenWidth * 0.15,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.outline,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.article,
                            color: Theme.of(context).colorScheme.outlineVariant,
                            size: screenWidth * 0.06,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: screenWidth * 0.15,
                    height: screenWidth * 0.15,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.article,
                      color: Theme.of(context).colorScheme.outlineVariant,
                      size: screenWidth * 0.06,
                    ),
                  ),
              ],
            ),
          ),
          // Only show bottom bar if showBottomBar is true
          if (showBottomBar)
            Container(
              width: double.infinity,
              height: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
        ],
      ),
    );
  }
}
