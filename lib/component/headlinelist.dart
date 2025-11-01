import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/news_model.dart';
import '../provider/news_provider.dart';

class HeadlinesListingPage extends StatefulWidget {
  final Map<String, dynamic> initialHeadline;
  final List<Map<String, dynamic>> allHeadlines;
  final VoidCallback? onBack;

  const HeadlinesListingPage({
    super.key,
    required this.initialHeadline,
    required this.allHeadlines,
    this.onBack,
  });

  @override
  State<HeadlinesListingPage> createState() => _HeadlinesListingPageState();
}

class _HeadlinesListingPageState extends State<HeadlinesListingPage> {
  late Map<String, dynamic> _selectedHeadline;
  late List<News> _headlineNews;
  bool _isLoading = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _selectedHeadline = widget.initialHeadline;
    _headlineNews = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHeadlineNews();
    });
  }

  void _loadHeadlineNews() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
      });

      print('🟢 [HeadlinesListing] Loading news for headline: ${_selectedHeadline['headline_text']}');
      if (_selectedHeadline.containsKey('news_articles') && 
          _selectedHeadline['news_articles'] is List) {
        
        final newsList = _selectedHeadline['news_articles'] as List<News>;
        if (newsList.isNotEmpty) {
          print('🟢 [HeadlinesListing] Found ${newsList.length} articles in headline data');
          if (mounted) {
            setState(() {
              _headlineNews = List.from(newsList);
              _isLoading = false;
            });
          }
          return;
        }
      }

      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      final headlineText = _getHeadlineText(_selectedHeadline, newsProvider.currentLanguage);
      
      print('🟢 [HeadlinesListing] Using fallback matching for: "$headlineText"');
      
      final cachedNews = newsProvider.allNews;
      final relatedNews = <News>[];
      
      for (final news in cachedNews) {
        if (!mounted) break;
        if (news.headline == null) continue;
        
        final newsHeadlineText = news.headline!['headline']?.toString() ?? '';
        if (_doesHeadlineMatch(newsHeadlineText, headlineText)) {
          relatedNews.add(news);
        }
      }
      
      relatedNews.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      print('🟢 [HeadlinesListing] Fallback found ${relatedNews.length} articles');

      if (mounted) {
        setState(() {
          _headlineNews = relatedNews;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔴 [HeadlinesListing] Error loading headline news: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _headlineNews = [];
        });
      }
    }
  }

  bool _doesHeadlineMatch(String newsHeadline, String timelineHeadline) {
    if (newsHeadline.isEmpty || timelineHeadline.isEmpty) return false;
    
    final cleanNews = newsHeadline.toLowerCase().trim();
    final cleanTimeline = timelineHeadline.toLowerCase().trim();
    
    return cleanNews == cleanTimeline;
  }

  String _getHeadlineText(Map<String, dynamic> headline, String language) {
    final translations = headline['translations'] as Map<String, dynamic>?;
    
    print('🔄 [Timeline] Getting headline text for language: $language');
    print('🔄 [Timeline] Headline translations: $translations');
    
    if (translations != null && translations.containsKey(language)) {
      final translatedText = translations[language]?.toString() ?? headline['headline_text'] ?? '';
      print('🔄 [Timeline] Using translated text: $translatedText');
      return translatedText;
    }
    
    final fallbackText = headline['headline_text'] ?? 'Unknown Headline';
    print('🔄 [Timeline] Using fallback text: $fallbackText');
    return fallbackText;
  }

  void _onHeadlineSelected(Map<String, dynamic> headline) {
    if (_selectedHeadline['id'] == headline['id']) return;
    
    print('🟢 [HeadlinesListing] Headline selected: ${headline['headline_text']}');
    setState(() {
      _selectedHeadline = headline;
    });
    _loadHeadlineNews();
  }

  Future<void> _onNewsTap(News news) async {
    if (_isNavigating) return;
    
    _isNavigating = true;
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (!mounted) return;
    
    try {
      await context.push(
        '/headlines',
        extra: {
          'headline': _selectedHeadline,
          'initialNews': news,
        },
      );
    } catch (e) {
      print('🔴 [HeadlinesListing] Navigation error: $e');
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: _buildFullSizeCardWithHeadlines(context),
        ),
      ),
    );
  }

  Widget _buildFullSizeCardWithHeadlines(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      margin: EdgeInsets.all(screenWidth * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: screenWidth * 0.02,
            spreadRadius: screenWidth * 0.005,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeaderWithCategories(context),
          _buildSelectedHeadlineImage(context),
          Expanded(
            child: _buildTimelineNewsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithCategories(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Padding(
      padding: EdgeInsets.only(right: screenWidth * 0.01),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: screenHeight * 0.01),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back, 
                color: Colors.black, 
                size: screenWidth * 0.065
              ),
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            SizedBox(width: screenWidth * 0.01),
            Expanded(
              child: SizedBox(
                height: screenHeight * 0.045,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.allHeadlines.length,
                  itemBuilder: (context, index) {
                    final headline = widget.allHeadlines[index];
                    final isSelected = headline['id'] == _selectedHeadline['id'];
                    final headlineText = _getHeadlineText(headline, Provider.of<NewsProvider>(context).currentLanguage);
      
                    return GestureDetector(
                      onTap: () => _onHeadlineSelected(headline),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03, 
                          vertical: screenHeight * 0.005
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red.shade50 : Colors.grey.shade200,
                          border: isSelected ? Border.all(
                            color: Colors.red,
                            width: screenWidth * 0.004,
                          ) : null,
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        ),
                        child: Center(
                          child: Text(
                            headlineText,
                            style: TextStyle(
                              color: isSelected ? Colors.red : Colors.black87,
                              fontSize: screenWidth * 0.032,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedHeadlineImage(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final hasImage = _selectedHeadline['headline_image'] != null && 
                    _selectedHeadline['headline_image'].toString().isNotEmpty;

    if (!hasImage) {
      return const SizedBox.shrink();
    }

    final headlineText = _getHeadlineText(_selectedHeadline, Provider.of<NewsProvider>(context).currentLanguage);

    return Container(
      width: double.infinity,
      height: screenWidth * 0.45,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04, 
        vertical: screenHeight * 0.01
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        image: DecorationImage(
          image: NetworkImage(_selectedHeadline['headline_image']),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.center,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.4),
              Colors.transparent,
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Text(
              headlineText,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.042,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: screenWidth * 0.01,
                    offset: Offset(screenWidth * 0.002, screenWidth * 0.005),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineNewsList(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          strokeWidth: screenWidth * 0.008,
        ),
      );
    }

    if (_headlineNews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined, 
              size: screenWidth * 0.12, 
              color: Colors.grey
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'No news available for this headline',
              style: TextStyle(
                color: Colors.grey,
                fontSize: screenWidth * 0.038,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'Try selecting a different headline',
              style: TextStyle(
                color: Colors.grey, 
                fontSize: screenWidth * 0.03
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          left: screenWidth * 0.08,
          top: 0,
          bottom: 0,
          right: 0,
          child: _LimitedDashedLine(
            itemCount: _headlineNews.length,
            itemHeight: screenHeight * 0.1,
            extraSpace: screenHeight * 0.05,
          ),
        ),

        ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04, 
            vertical: screenHeight * 0.01
          ),
          itemCount: _headlineNews.length,
          itemBuilder: (context, index) {
            final news = _headlineNews[index];
            return _buildTimelineNewsItem(context, news, index);
          },
        ),
      ],
    );
  }

  Widget _buildTimelineNewsItem(BuildContext context, News news, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => _onNewsTap(news),
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.025),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: screenHeight * 0.006),
              width: screenWidth * 0.08,
              child: Center(
                child: Container(
                  width: screenWidth * 0.032,
                  height: screenWidth * 0.032,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            SizedBox(width: screenWidth * 0.025),

            Expanded(
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.025),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            news.timeAgo,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.w800,
                              letterSpacing: screenWidth * 0.001
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.008),
                          Text(
                            news.title,
                            style: TextStyle(
                              fontSize: screenWidth * 0.034,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.015),
                    Container(
                      width: screenWidth * 0.18,
                      height: screenWidth * 0.18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        image: news.imageUrl != null && news.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(news.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: news.imageUrl == null || news.imageUrl!.isEmpty
                            ? Colors.grey.shade300
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitedDashedLine extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double extraSpace;

  const _LimitedDashedLine({
    required this.itemCount,
    required this.itemHeight,
    required this.extraSpace,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomPaint(
      painter: LimitedDashedLinePainter(
        itemCount: itemCount,
        itemHeight: itemHeight,
        extraSpace: extraSpace,
        screenWidth: screenWidth,
      ),
    );
  }
}

class LimitedDashedLinePainter extends CustomPainter {
  final int itemCount;
  final double itemHeight;
  final double extraSpace;
  final double screenWidth;

  const LimitedDashedLinePainter({
    required this.itemCount,
    required this.itemHeight,
    required this.extraSpace,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = screenWidth * 0.005
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double dashHeight = screenWidth * 0.015;
    final double dashSpace = screenWidth * 0.015;
    
    double totalHeight = (itemCount * itemHeight) + extraSpace;
    double limitedHeight = totalHeight < size.height ? totalHeight : size.height;
    
    double currentY = 0;

    while (currentY < limitedHeight) {
      canvas.drawLine(
        Offset(0, currentY),
        Offset(0, currentY + dashHeight),
        paint,
      );
      currentY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}