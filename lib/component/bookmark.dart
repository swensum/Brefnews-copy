import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../language/app_localizations.dart';
import '../provider/news_provider.dart';
import '../models/news_model.dart';
import '../repositories/marvelous_carousel.dart';
import '../utilities/share_utils.dart';
import '../utilities/webview_screen.dart';


class BookmarkPage extends StatefulWidget {
  final News? initialNews;

  const BookmarkPage({super.key, this.initialNews});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> with TickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  List<News> _sortedBookmarks = [];
  bool _isInitialized = false;

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
      _sortBookmarks();
      _isInitialized = true;
    });
  }

  void _sortBookmarks() {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final bookmarkedNews = List<News>.from(newsProvider.bookmarkedNews);
    
    if (widget.initialNews != null) {
      final clickedNewsIndex = bookmarkedNews.indexWhere((news) => news.id == widget.initialNews!.id);
      if (clickedNewsIndex != -1) {
        final clickedNews = bookmarkedNews.removeAt(clickedNewsIndex);
        bookmarkedNews.insert(0, clickedNews);
      }
    }
    
    if (mounted) {
      setState(() {
        _sortedBookmarks = bookmarkedNews;
        _currentPage = 0; 
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      _sortBookmarks();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
     final screenHeight = MediaQuery.of(context).size.height;
     final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.bookmarks,
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.04, 
          ),
        ),
        centerTitle: false,
      ),
           body: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + screenHeight * 0.01,
        ),
        child: _buildBookmarkContent(),
      ),
    );
  }

  Widget _buildBookmarkContent() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        
        if (_sortedBookmarks.length != newsProvider.bookmarkedNews.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _sortBookmarks();
          });
        }
        
        if (_sortedBookmarks.isEmpty) return _buildEmptyWidget();
        if (_sortedBookmarks.length == 1) return _buildSingleBookmark(newsProvider, _sortedBookmarks.first);

        return MarvelousCarousel(
      
          margin: 1,
          
          onPageChanged: (index) {
            if (mounted) {
              setState(() {
                _currentPage = index;
              });
            }
          },
          children: _sortedBookmarks.asMap().entries.map((entry) {
            final index = entry.key;
            final news = entry.value;
            final isActive = index == _currentPage;

            return AnimatedScale(
              scale: isActive ? 1.0 : 0.98,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: isActive ? 1.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: _BookmarkNewsCard(
                  news: news,
                  isActive: isActive,
                  isClickedNews: index == 0 && widget.initialNews != null && news.id == widget.initialNews!.id,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSingleBookmark(NewsProvider newsProvider, News news) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.001),
        child: _BookmarkNewsCard(
          news: news,
          isActive: true,
          isClickedNews: true,
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
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
            size: screenHeight * 0.1
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            localizations.noSavedArticles,
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
          color: _isTapped ? Colors.blue.withValues(alpha:  0.2) : Colors.transparent,
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _isTapped ? 0.8 : 1.0,
          curve: Curves.elasticOut,
          child: Icon(
            Icons.share,
            size: widget.size,
            color: _isTapped ? Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.onSecondaryFixed,
          ),
        ),
      ),
    );
  }
}

class _BookmarkNewsCard extends StatefulWidget {
  final News news;
  final bool isActive;
  final bool isClickedNews;

  const _BookmarkNewsCard({
    required this.news, 
    required this.isActive,
    required this.isClickedNews,
  });

  @override
  State<_BookmarkNewsCard> createState() => _BookmarkNewsCardState();
}

class _BookmarkNewsCardState extends State<_BookmarkNewsCard> {
  final GlobalKey shareKey = GlobalKey();
  bool _isBookmarkOrShareTap = false;

  Future<void> _shareNewsCard(BuildContext context) async {
    // Set flag to prevent card tap
    _isBookmarkOrShareTap = true;
    
    await ShareUtils.shareNewsCard(
      globalKey: shareKey,
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

    // Force HTTPS
    rawUrl = rawUrl.replaceAll(RegExp(r'^https?://'), '');
    rawUrl = 'https://$rawUrl';
    
    print('🟢 [WebView Debug] Secure URL: $rawUrl');

    try {
      if (!context.mounted) return;
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: rawUrl,
            title: widget.news.source.isEmpty ? 'News Article' : widget.news.source,
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
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return _ImagePreviewDialog(news: widget.news);
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
        bottom: screenHeight * 0.1,
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

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 1000), () {
      overlayEntry.remove();
    });
  }

  // ADD THREE-DOT MENU METHOD
  void _showThreeDotMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildThreeDotMenu(context),
    );
  }

  // ADD THREE-DOT MENU BUILDER
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
            // Share Feedback on Short Option
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

  // ADD FEEDBACK METHOD
  void _shareFeedbackOnShort(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Then navigate to feedback page
      context.push('/feedback-detail', extra: {
        'newsHeadline': widget.news.title,
        'onFeedbackSubmitted': (String type, String text, String headline) {
          // Handle feedback submission callback if needed
          print('Feedback submitted: $type - $text');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxImageHeight = screenHeight * 0.33;

    return RepaintBoundary(
      key: shareKey,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.001),
         child: GestureDetector(
           onTap: () => _launchUrl(context),
          child: Material(
             color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (widget.news.imageUrl != null && widget.news.imageUrl!.isNotEmpty)
                        _buildNewsImage(context, maxImageHeight)
                      else
                        _buildPlaceholderImage(maxImageHeight, screenWidth),
                
                      // ADD THREE DOTS MENU BUTTON - Top Right Corner
                      Positioned(
                        top: screenWidth * 0.02,
                        right: screenWidth * 0.02,
                        child: GestureDetector(
                          onTap: () => _showThreeDotMenu(context),
                          child: Container(
                            width: screenWidth * 0.08,
                            height: screenWidth * 0.08,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha:  0.6),
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
                
                      // Logo - Same as NotificationPage
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
                        bottom: -screenWidth * 0.047,
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
                                    bool isBookmarked = newsProvider.isBookmarked(widget.news);
                                    return GestureDetector(
                                      onTap: () => _toggleBookmark(context),
                                      child: Icon(
                                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                        size: screenWidth * 0.05,
                                        color: isBookmarked ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSecondaryFixed,
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
                          Flexible(
                            fit: FlexFit.loose,
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
                                        ? screenWidth * 0.035
                                        : screenWidth * 0.035,
                                    height: Platform.isIOS ? 1.6 : 1.4,
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
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                            fontSize: Platform.isIOS
                                                ? screenWidth * 0.03
                                                : screenWidth * 0.03,
                                            fontWeight: FontWeight.w600,
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
                  // Headline section - takes full width (Same as NotificationPage)
                  GestureDetector(
                    onTap: () => _launchUrl(context),
                    child: Container(
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        image: widget.news.imageUrl != null && widget.news.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(widget.news.imageUrl!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.6),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                        color: widget.news.imageUrl == null || widget.news.imageUrl!.isEmpty
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
      ),
    );
  }

  Widget _buildNewsImage(BuildContext context, double maxImageHeight) {
    return GestureDetector(
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
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: maxImageHeight,
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage(maxImageHeight, MediaQuery.of(context).size.width);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(double height, double screenWidth) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        color: Colors.grey,
      ),
      child: Icon(
        Icons.article,
        color: Colors.white,
        size: screenWidth * 0.12,
      ),
    );
  }
}

class _ImagePreviewDialog extends StatelessWidget {
  final News news;

  const _ImagePreviewDialog({required this.news});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Background with tap to close
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: screenWidth,
              height: screenHeight,
              color: Colors.black,
            ),
          ),
          
          // Image
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                news.imageUrl!,
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
          
          // Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + screenHeight * 0.02,
            right: screenWidth * 0.05,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: const BoxDecoration(
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
          
          // Title Overlay
          if (news.title.isNotEmpty)
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
                  news.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Platform.isIOS
                        ? screenWidth * 0.044
                        : screenWidth * 0.042,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
        ],
      ),
    );
  }
}