import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../component/timeline.dart';
import '../language/app_localizations.dart';
import '../provider/news_provider.dart';

import '../models/news_model.dart';
import '../repositories/marvelous_carousel.dart';
import '../utilities/share_utils.dart';
import '../utilities/webview_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  String? _previousCategory;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      newsProvider.loadNews();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [Expanded(child: _buildNewsContent())]),
      ),
    );
  }

  Widget _buildNewsContent() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        if (_previousCategory != newsProvider.selectedCategory) {
          _currentPage = 0; // Reset to first article
          _previousCategory = newsProvider.selectedCategory;
          print(
            '🟢 [HomePage] Category changed to ${newsProvider.selectedCategory}, resetting to first article',
          );
        }

        if (newsProvider.selectedCategory == 'Timeline') {
          return TimelinePage();
        }

        // if (newsProvider.selectedCategory == 'Videos') {
        //   return VideosPage();
        // }

        if (newsProvider.selectedCategory == 'Bookmarks' &&
            newsProvider.news.isEmpty) {
          return _buildNoBookmarksWidget();
        }

        if (newsProvider.isLoading) return _buildShimmerLoader();
        if (newsProvider.hasError) return _buildErrorWidget(newsProvider);
        if (newsProvider.news.isEmpty) return _buildEmptyWidget(newsProvider);

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            // Prevent auto-refresh when there's no news
            if (scrollNotification is OverscrollNotification) {
              if (newsProvider.news.isEmpty && !newsProvider.isLoading) {
                return true; // Block the pull-to-refresh
              }
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              // Only refresh if we should allow it
              if (_shouldAllowRefresh(newsProvider)) {
                await newsProvider.loadNews();
              }
            },
            // Disable refresh indicator when no news or in bookmarks
            color:
                (newsProvider.news.isEmpty ||
                    newsProvider.selectedCategory == 'Bookmarks')
                ? Colors.transparent
                : null,
            backgroundColor:
                (newsProvider.news.isEmpty ||
                    newsProvider.selectedCategory == 'Bookmarks')
                ? Colors.transparent
                : null,
            child: MarvelousCarousel(
              enablePullToRefresh: true,
              onRefresh: () async {
                // Call your refresh method
                await newsProvider.refreshNews();
              },
              margin: 1,
              refreshTriggerThreshold: 100.0,

              onPageChanged: (index) {
                final stopwatch = Stopwatch()..start();

                setState(() {
                  _currentPage = index;
                });

                print(
                  '🔄 Page change to $index took ${stopwatch.elapsedMilliseconds}ms',
                );

                // Preload next images when page changes
                if (index < newsProvider.news.length - 1) {
                  final nextNews = newsProvider.news[index + 1];
                  if (nextNews.imageUrl != null &&
                      nextNews.imageUrl!.isNotEmpty) {
                    precacheImage(NetworkImage(nextNews.imageUrl!), context);
                  }
                }

                // Preload next 2 images for smoother scrolling
                if (index < newsProvider.news.length - 2) {
                  final nextNews2 = newsProvider.news[index + 2];
                  if (nextNews2.imageUrl != null &&
                      nextNews2.imageUrl!.isNotEmpty) {
                    precacheImage(NetworkImage(nextNews2.imageUrl!), context);
                  }
                } 
              },
              children: newsProvider.news.asMap().entries.map((entry) {
                int index = entry.key;
                News news = entry.value;
                bool isActive = index == _currentPage;

                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.98,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: isActive ? 1.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: _NewsCard(
                      key: ValueKey(
                        'news_${news.id}_${news.title}',
                      ), // Add unique key
                      shareKey:
                          GlobalKey(), // Create unique share key for each card
                      news: news,
                      isActive: isActive,
                      currentCategory: newsProvider.selectedCategory,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  bool _shouldAllowRefresh(NewsProvider newsProvider) {
    return !newsProvider.isLoading &&
        newsProvider.selectedCategory != 'Bookmarks';
  }

  Widget _buildNoBookmarksWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            color: Theme.of(context).colorScheme.outlineVariant,
            size: screenHeight * 0.1,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            localizations.noBookmarksYet,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            localizations.saveArticlesToReadLater,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outlineVariant,
              fontSize: screenWidth * 0.04,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.03),
          ElevatedButton(
            onPressed: () {
              context.go('/search');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
            ),
            child: Text(
              localizations.exploreArticles,
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: List.generate(2, (index) {
        return Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, index * 20.0),
            child: Transform.scale(
              scale: 1.0 - (index * 0.05),
              child: Opacity(
                opacity: 1.0 - (index * 0.3),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Shimmer.fromColors(
                          baseColor: Theme.of(context).colorScheme.outline,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.3,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outline,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: screenWidth * 0.05,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                SizedBox(height: screenWidth * 0.03),
                                Container(
                                  width: double.infinity,
                                  height: screenWidth * 0.04,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                SizedBox(height: screenWidth * 0.02),
                                Container(
                                  width: double.infinity,
                                  height: screenWidth * 0.04,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorWidget(NewsProvider newsProvider) {
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.outlineVariant,
            size: screenHeight * 0.1,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            localizations.failedToLoadNews,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: screenHeight * 0.025,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          ElevatedButton(
            onPressed: newsProvider.loadNews,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              localizations.retry,
              style: TextStyle(fontSize: screenHeight * 0.02),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(NewsProvider newsProvider) {
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article,
            color: Theme.of(context).colorScheme.outlineVariant,
            size: screenHeight * 0.1,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            localizations.noNewsAvailable,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: screenHeight * 0.025,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            localizations.checkBackLaterForUpdates,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outlineVariant,
              fontSize: screenHeight * 0.018,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          ElevatedButton(
            onPressed: newsProvider.loadNews,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              localizations.refresh,
              style: TextStyle(fontSize: screenHeight * 0.02),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedShareIcon extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const _AnimatedShareIcon({required this.onTap, required this.size});

  @override
  State<_AnimatedShareIcon> createState() => _AnimatedShareIconState();
}

class _AnimatedShareIconState extends State<_AnimatedShareIcon> {
  bool _isTapped = false;

  void _handleTap() {
    setState(() {
      _isTapped = true;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isTapped = false;
        });
      }
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(widget.size * 0.2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isTapped
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _isTapped ? 0.8 : 1.0,
          curve: Curves.elasticOut,
          child: Icon(
            Icons.share,
            size: widget.size,
            color: _isTapped
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSecondaryFixed,
          ),
        ),
      ),
    );
  }
}

// ========== FIXED: StatefulWidget with proper lifecycle management ==========
class _NewsCard extends StatefulWidget {
  final News news;
  final bool isActive;
  final String currentCategory;
  final GlobalKey shareKey;

  const _NewsCard({
    super.key,
    required this.news,
    required this.isActive,
    required this.currentCategory,
    required this.shareKey,
  });

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  // Add this variable to track if we should block the card tap
  bool _isBookmarkOrShareTap = false;

  // ========== ADDED: Track if article has been marked as read ==========
  bool _hasBeenMarkedAsRead = false;
  bool _hasBeenSeenInUnread = false;

  @override
  void initState() {
    super.initState();
    _markAsReadIfActive();
  }

  @override
  void didUpdateWidget(_NewsCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ========== ADDED: Only mark as read if card becomes active AND hasn't been marked before ==========
    if (widget.isActive && !oldWidget.isActive && !_hasBeenMarkedAsRead) {
      _markAsReadIfActive();
    }
  }

  // ========== FIXED: Don't mark as read if we're in Unread category ==========
  void _markAsReadIfActive() {
    if (widget.currentCategory == 'Unread') {
      if (!_hasBeenSeenInUnread && widget.isActive) {
        _hasBeenSeenInUnread = true;
        print('👀 Article seen in Unread: ${widget.news.title}');
      }
      return; // Don't mark as read in Unread category
    }
    if (widget.isActive && !_hasBeenMarkedAsRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasBeenMarkedAsRead) {
          final newsProvider = Provider.of<NewsProvider>(
            context,
            listen: false,
          );
          if (!newsProvider.isRead(widget.news)) {
            newsProvider.markAsRead(widget.news);
            _hasBeenMarkedAsRead = true; // Prevent future marks
            print('📖 Marked article as read: ${widget.news.title}');
          }
        }
      });
    }
  }

  Future<void> _shareNewsCard(BuildContext context) async {
    // Set flag to prevent card tap
    _isBookmarkOrShareTap = true;

    await ShareUtils.shareNewsCard(
      globalKey: widget.shareKey,
      news: widget.news,
      context: context,
    );

    // Reset flag after a short delay
    Future.delayed(Duration(milliseconds: 100), () {
      _isBookmarkOrShareTap = false;
    });
  }

  Future<void> _launchUrl(BuildContext context) async {
    // Don't launch if it was a bookmark/share tap
    if (_isBookmarkOrShareTap) {
      _isBookmarkOrShareTap = false;
      return;
    }

    String rawUrl = widget.news.sourceUrl.trim();

    print('🟢 [WebView Debug] Original URL: $rawUrl');

    if (rawUrl.isEmpty) {
      return;
    }

    rawUrl = rawUrl.replaceAll(RegExp(r'^https?://'), '');
    rawUrl = 'https://$rawUrl';

    print('🟢 [WebView Debug] Secure URL: $rawUrl');

    try {
      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: rawUrl,
            title: widget.news.source.isEmpty
                ? 'News Article'
                : widget.news.source,
          ),
        ),
      );
    } catch (e) {
      print('🔴 [WebView Debug] WebView failed: $e');
    }
  }

  void _toggleBookmark(BuildContext context) {
    // Set flag to prevent card tap
    _isBookmarkOrShareTap = true;

    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    bool isBookmarked = newsProvider.isBookmarked(widget.news);

    newsProvider.toggleBookmark(widget.news);
    _showBookmarkDialog(context, !isBookmarked);

    // Reset flag after a short delay
    Future.delayed(Duration(milliseconds: 100), () {
      _isBookmarkOrShareTap = false;
    });
  }

  void _showImagePreview(BuildContext context) {
    if (widget.news.imageUrl == null || widget.news.imageUrl!.isEmpty) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.black,
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      widget.news.imageUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: screenWidth * 0.15,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + screenHeight * 0.02,
                right: screenWidth * 0.05,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: screenWidth * 0.06,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.04,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    widget.news.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Platform.isIOS
                          ? screenWidth * 0.044
                          : screenWidth * 0.042,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBookmarkDialog(BuildContext context, bool isSaved) {
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
              isSaved ? localizations.shortSaved : localizations.shortUnsaved,
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

    // Insert overlay
    overlayState.insert(overlayEntry);

    // Remove overlay after 1 second
    Future.delayed(const Duration(milliseconds: 1000), () {
      overlayEntry.remove();
    });
  }

  void _showThreeDotMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildThreeDotMenu(context),
    );
  }

  Widget _buildThreeDotMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.feedback, color: Colors.black87),
              title: Text(
                localizations.shareFeedbackOnShort,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareFeedbackOnShort(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareFeedbackOnShort(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.push(
        '/feedback-detail',
        extra: {
          'newsHeadline': widget.news.title,
          'onFeedbackSubmitted': (String type, String text, String headline) {
            print('Feedback submitted: $type - $text');
          },
        },
      );
    });
  }
@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final maxImageHeight = screenHeight * 0.33;

  return RepaintBoundary(
    key: widget.shareKey,
    child: Padding(
      padding: EdgeInsets.all(screenWidth * 0.001),
      child: GestureDetector(
        onTap: () => _launchUrl(context),
        child: Container(
          constraints: BoxConstraints(
            minHeight: screenHeight * 0.7,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Stack - Fixed height
              SizedBox(
                height: maxImageHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (widget.news.imageUrl != null &&
                        widget.news.imageUrl!.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showImagePreview(context),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: SizedBox(
                            height: maxImageHeight,
                            width: double.infinity,
                            child: Image.network(
                              widget.news.imageUrl!,
                              width: double.infinity,
                              height: maxImageHeight,
                              fit: BoxFit.cover,
                              alignment: Alignment.topLeft,

                              cacheWidth: (screenWidth * 5).toInt(),
                              filterQuality: FilterQuality.medium,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: double.infinity,
                                      height: maxImageHeight,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: maxImageHeight,
                                  color: Theme.of(context).colorScheme.outline,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                    size: screenWidth * 0.12,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: maxImageHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        child: Icon(
                          Icons.article,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: screenWidth * 0.12,
                        ),
                      ),

                    Positioned(
                      top: screenWidth * 0.02,
                      right: screenWidth * 0.02,
                      child: GestureDetector(
                        onTap: () => _showThreeDotMenu(context),
                        child: Container(
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: screenWidth * 0.008,
                                height: screenWidth * 0.008,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.005),
                              Container(
                                width: screenWidth * 0.008,
                                height: screenWidth * 0.008,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.005),
                              Container(
                                width: screenWidth * 0.008,
                                height: screenWidth * 0.008,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -screenWidth * 0.039,
                      left: screenWidth * 0.01,
                      child: GestureDetector(
                        onTap: () {
                          // Prevent URL launch when logo is tapped
                          _isBookmarkOrShareTap = true;
                          Future.delayed(Duration(milliseconds: 100), () {
                            _isBookmarkOrShareTap = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/brefnews.png',
                              color: Theme.of(context).colorScheme.onSurface,
                              width: screenWidth * 0.25,
                              height: screenWidth * 0.08,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -screenWidth * 0.045,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // Prevent URL launch when the entire icon container is tapped
                          _isBookmarkOrShareTap = true;
                          Future.delayed(Duration(milliseconds: 100), () {
                            _isBookmarkOrShareTap = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.02,
                            vertical: screenWidth * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Consumer<NewsProvider>(
                                builder: (context, newsProvider, child) {
                                  bool isBookmarked = newsProvider.isBookmarked(
                                    widget.news,
                                  );
                                  return GestureDetector(
                                    onTap: () => _toggleBookmark(context),
                                    child: Icon(
                                      isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      size: screenWidth * 0.05,
                                      color: isBookmarked
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryFixed,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              _AnimatedShareIcon(
                                onTap: () => _shareNewsCard(context),
                                size: screenWidth * 0.05,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content section - Use Expanded to take remaining space
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.04,
                    screenHeight * 0.02,
                    screenWidth * 0.04,
                    screenHeight * 0.015,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.news.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: Platform.isIOS
                              ? screenWidth * 0.042
                              : screenWidth * 0.042,
                          fontWeight: FontWeight.bold,
                          height: Platform.isIOS ? 1.3 : 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      
                      // Summary section - Use Flexible instead of nested Flexible
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Text
                            Text(
                              widget.news.summary,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.color,
                                fontSize: Platform.isIOS
                                    ? screenWidth * 0.036
                                    : screenWidth * 0.037,
                                height: Platform.isIOS ? 1.4 : 1.4,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0),
                            
                            // Source and Time Info
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.008,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Source
                                  Flexible(
                                    child: Text(
                                      widget.news.source,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                        fontSize: Platform.isIOS
                                            ? screenWidth * 0.03
                                            : screenWidth * 0.03,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                        
                                  // Dot separator
                                  Container(
                                    width: screenWidth * 0.01,
                                    height: screenWidth * 0.01,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                        
                                  Text(
                                    widget.news.timeAgo,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                      fontSize: Platform.isIOS
                                          ? screenWidth * 0.03
                                          : screenWidth * 0.03,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            
              Transform(
                transform: Matrix4.identity()
    ..setEntry(3, 2, 0.001), // Match the carousel's perspective
  alignment: Alignment.bottomCenter,
                child: Container(
                  height: screenHeight * 0.07,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    image:
                        widget.news.imageUrl != null &&
                            widget.news.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.news.imageUrl!),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.6),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                    color:
                        widget.news.imageUrl == null ||
                            widget.news.imageUrl!.isEmpty
                        ? Colors.grey[800]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        padding: EdgeInsets.only(left: screenWidth * 0.04),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.news.headline != null &&
                                widget.news.headline!['headline'] != null)
                              Text(
                                widget.news.headline!['headline'],
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: Platform.isIOS
                                      ? screenWidth * 0.039
                                      : screenWidth * 0.037,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (widget.news.headline != null &&
                                widget.news.headline!['subheadline'] != null)
                              Text(
                                widget.news.headline!['subheadline'],
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: Platform.isIOS
                                      ? screenWidth * 0.032
                                      : screenWidth * 0.03,
                                ),
                                textAlign: TextAlign.left,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}}