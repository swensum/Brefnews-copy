import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:marvelous_carousel/marvelous_carousel.dart';
import 'package:url_launcher/url_launcher.dart';
import '../language/app_localizations.dart';
import '../provider/news_provider.dart';
import '../models/news_model.dart';
import '../utilities/share_utils.dart';

class TopicsDetailPage extends StatefulWidget {
  final Map<String, dynamic> topic;
  final News? initialNews;

  const TopicsDetailPage({
    super.key, 
    required this.topic,
    this.initialNews,
  });

  @override
  State<TopicsDetailPage> createState() => _TopicsDetailPageState();
}

class _TopicsDetailPageState extends State<TopicsDetailPage>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  List<News> _topicNews = [];
  bool _isInitialized = false;
  late String _topicName;

  @override
  void initState() {
    super.initState();

    _topicName = widget.topic['name'] as String;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTopicNews();
      _isInitialized = true;
    });
  }

  void _loadTopicNews() async {
    try {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      await newsProvider.fetchNewsByTopic(_topicName);
      
      if (mounted) {
        setState(() {
          _topicNews = List<News>.from(newsProvider.topicNews);
          _sortNews();
        });
      }
    } catch (e) {
      print('Error loading topic news: $e');
    }
  }

  void _sortNews() {
    if (widget.initialNews != null) {
      final clickedNewsIndex = _topicNews.indexWhere(
        (news) => news.id == widget.initialNews!.id,
      );
      if (clickedNewsIndex != -1) {
        final clickedNews = _topicNews.removeAt(clickedNewsIndex);
        _topicNews.insert(0, clickedNews);
        _currentPage = 0;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadTopicNews();
        }
      });
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _topicName,
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
        child: _buildTopicContent(),
      ),
    );
  }

  Widget _buildTopicContent() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        // Sync with provider data when it changes
        if (_topicNews.length != newsProvider.topicNews.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _topicNews = List<News>.from(newsProvider.topicNews);
                _sortNews();
              });
            }
          });
        }

        if (_topicNews.isEmpty) return _buildEmptyWidget();
        if (_topicNews.length == 1) {
          return _buildSingleNews(
            _topicNews.first,
          );
        }

        return MarvelousCarousel(
          pagerType: PagerType.stack,
          margin: 8,
          scrollDirection: Axis.vertical,
          reverse: true,
          dotsVisible: false,
          onPageChanged: (index) {
            if (mounted) {
              setState(() {
                _currentPage = index;
              });
            }
          },
          children: _topicNews.asMap().entries.map((entry) {
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
                child: _TopicNewsCard(
                  news: news,
                  isActive: isActive,
                  isClickedNews: widget.initialNews != null && 
                      index == 0 && 
                      news.id == widget.initialNews!.id,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSingleNews(News news) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.001),
        child: _TopicNewsCard(
          news: news,
          isActive: true,
          isClickedNews: widget.initialNews != null && news.id == widget.initialNews!.id,
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
            Icons.topic,
            color: Theme.of(context).colorScheme.outlineVariant, 
            size: screenHeight * 0.1,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
           localizations.noNewsAvailable,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary, 
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            '${localizations.noArticlesFoundFor} $_topicName',
            style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant, fontSize: screenWidth * 0.04),
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
          color: _isTapped ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
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

class _TopicNewsCard extends StatelessWidget {
  final News news;
  final bool isActive;
  final bool isClickedNews;
  final GlobalKey shareKey = GlobalKey();

  _TopicNewsCard({
    required this.news,
    required this.isActive,
    required this.isClickedNews,
  });

  Future<void> _shareNewsCard(BuildContext context) async {
    await ShareUtils.shareNewsCard(
      globalKey: shareKey,
      news: news,
      context: context,
    );
  }

  Future<void> _launchUrl(BuildContext context) async {
    String rawUrl = news.sourceUrl.trim();
    if (rawUrl.isEmpty) {
      _showErrorSnackBar(context, "Invalid URL");
      return;
    }

    if (!rawUrl.startsWith("http")) {
      rawUrl = "https://$rawUrl";
    }

    final Uri url = Uri.parse(rawUrl);

    if (!await canLaunchUrl(url)) {
      if (context.mounted) {
        _showErrorSnackBar(context, "Cannot launch URL: $rawUrl");
      }
      return;
    }

    try {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, "Error opening link: $e");
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final screenWidth = MediaQuery.of(context).size.width;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: screenWidth * 0.035)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showImagePreview(BuildContext context) {
    if (news.imageUrl == null || news.imageUrl!.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return _ImagePreviewDialog(news: news);
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

  void _shareFeedbackOnShort(BuildContext context) {
    // Close the bottom sheet first using a post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Then navigate to feedback page
      context.push('/feedback-detail', extra: {
        'newsHeadline': news.title,
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
    final maxImageHeight = screenHeight * 0.35;

    return RepaintBoundary(
      key: shareKey,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.001),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
                      _buildNewsImage(context, maxImageHeight)
                    else
                      _buildPlaceholderImage(maxImageHeight, screenWidth),
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
                   
                    Positioned(
                      bottom: -screenWidth * 0.03,
                      right: 0,
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
                                bool isBookmarked = newsProvider.isBookmarked(news);
                                return GestureDetector(
                                  onTap: () {
                                    newsProvider.toggleBookmark(news);
                                    _showBookmarkDialog(context, !isBookmarked);
                                  },
                                  child: Icon(
                                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    size: screenWidth * 0.045,
                                    color: isBookmarked ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSecondaryFixed,
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            _AnimatedShareIcon(
                              onTap: () => _shareNewsCard(context),
                              size: screenWidth * 0.045,
                            ),
                          ],
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
                          news.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: screenWidth * 0.043,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Flexible(
                          fit: FlexFit.loose,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Summary Text
                                Text(
                                  news.summary,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.titleMedium?.color,
                                    fontSize: screenWidth * 0.035,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.015),

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
                                          news.source,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.outlineVariant,
                                            fontSize: screenWidth * 0.032,
                                            fontWeight: FontWeight.w500,
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
                                        decoration:  BoxDecoration(
                                          color: Theme.of(context).colorScheme.outlineVariant,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),

                                      // Time - don't expand, just take needed space
                                      Text(
                                        news.timeAgo,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.outlineVariant,
                                          fontSize: screenWidth * 0.032,
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
                      image: news.imageUrl != null && news.imageUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(news.imageUrl!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.6),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                      color: news.imageUrl == null || news.imageUrl!.isEmpty
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
                                Colors.black.withValues(alpha:  0.0),
                                Colors.black.withValues(alpha:  0.35),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (news.headline != null &&
                                  news.headline!['headline'] != null)
                                Text(
                                  news.headline!['headline'],
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: screenWidth * 0.037,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (news.headline != null &&
                                  news.headline!['subheadline'] != null)
                                Text(
                                  news.headline!['subheadline'],
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: screenWidth * 0.03,
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
  }

  Widget _buildNewsImage(BuildContext context, double maxImageHeight) {
    return GestureDetector(
      onTap: () => _showImagePreview(context),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: SizedBox(
          height: maxImageHeight,
          width: double.infinity,
          child: Image.network(
            news.imageUrl!,
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
              return _buildPlaceholderImage(
                maxImageHeight,
                MediaQuery.of(context).size.width,
              );
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.grey,
      ),
      child: Icon(Icons.article, color: Colors.white, size: screenWidth * 0.12),
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
                    fontSize: screenWidth * 0.042,
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