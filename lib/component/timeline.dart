import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/news_model.dart';
import '../provider/news_provider.dart';
import '../supabase/supabase_client.dart';
import 'headlinelist.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  List<Map<String, dynamic>> _headlinesWithNews = [];
  Map<String, dynamic>? _selectedHeadlineForListing;
  bool _showHeadlinesListing = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadHeadlinesWithNews();
  }

  Future<void> _loadHeadlinesWithNews() async {
  final newsProvider = Provider.of<NewsProvider>(context, listen: false);

  try {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    // Load headlines directly
    final headlinesResponse = await SupabaseService().client
        .from('headlines')
        .select('*')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final localHeadlines = List<Map<String, dynamic>>.from(headlinesResponse);
    
    // DEBUG: Print how many headlines were fetched
    print('🔵 [Timeline] Fetched ${localHeadlines.length} headlines from Supabase');
    
    for (final headline in localHeadlines) {
      print('🔵 Headline: ${headline['headline_text']}, ID: ${headline['id']}');
    }

    // Use the NewsProvider method for grouped news
    final groupedNews = await newsProvider.getNewsGroupedByHeadlines();
    
    // DEBUG: Print grouped news
    print('🔵 [Timeline] Grouped news has ${groupedNews.length} headlines with news');
    groupedNews.forEach((headlineId, newsList) {
      print('🔵 Headline ID $headlineId has ${newsList.length} news articles');
    });

    // Convert the grouped news to our format
    final List<Map<String, dynamic>> headlinesWithNews = [];

    for (final headline in localHeadlines) {
      final headlineId = headline['id'].toString();
      final newsList = groupedNews[headlineId] ?? [];

      // Get the translated headline text
      final headlineText = _getHeadlineText(
        headline,
        newsProvider.currentLanguage,
      );
      
      // DEBUG: Print each headline's status
      print('🔵 Processing headline $headlineId: "$headlineText"');
      print('🔵 Has ${newsList.length} news articles');

      // FIX: Remove the "if (newsList.isNotEmpty)" condition to show all headlines
      // Or keep it but handle empty news case differently
      headlinesWithNews.add({
        'id': headlineId,
        'headline_text': headlineText,
        'headline_image': headline['headline_image'],
        'created_at': headline['created_at'],
        'translations': headline['translations'],
        'news_articles': newsList, // This can be empty
      });
    }

    // DEBUG: Final count
    print('🔵 [Timeline] Final headlinesWithNews count: ${headlinesWithNews.length}');

    if (mounted) {
      setState(() {
        _headlinesWithNews = headlinesWithNews;
        _isLoading = false;
        _currentLanguage = newsProvider.currentLanguage;
      });
    }
  } catch (e) {
    print('🔴 [Timeline] Failed to load headlines with news: $e');
    print('🔴 Stack trace: ${e.toString()}');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }
}
  String _getHeadlineText(Map<String, dynamic> headline, String language) {
    final translations = headline['translations'] as Map<String, dynamic>?;

    if (translations != null && translations.containsKey(language)) {
      return translations[language]?.toString() ??
          headline['headline_text'] ??
          '';
    }

    return headline['headline_text'] ?? 'Unknown Headline';
  }

  void _openHeadlineListingInCard(
    BuildContext context,
    Map<String, dynamic> headline,
  ) {
    setState(() {
      _selectedHeadlineForListing = headline;
      _showHeadlinesListing = true;
    });
  }

  void _closeHeadlinesListing() {
    setState(() {
      _showHeadlinesListing = false;
      _selectedHeadlineForListing = null;
    });
  }

  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _loadHeadlinesWithNews();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        // Reload when language changes
        if (_currentLanguage != newsProvider.currentLanguage && !_isLoading) {
          _currentLanguage = newsProvider.currentLanguage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadHeadlinesWithNews();
            }
          });
        }

        return _buildUI(context, newsProvider);
      },
    );
  }

  Widget _buildUI(BuildContext context, NewsProvider newsProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: _showHeadlinesListing && _selectedHeadlineForListing != null
              ? _buildHeadlinesListingCard(context)
              : _buildFullSizeCardWithLogo(context, newsProvider),
        ),
      ),
    );
  }

  Widget _buildHeadlinesListingCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.all(screenWidth * 0.01),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2),
        ],
      ),
      child: HeadlinesListingPage(
        initialHeadline: _selectedHeadlineForListing!,
        allHeadlines: _headlinesWithNews,
        onBack: _closeHeadlinesListing,
      ),
    );
  }

  Widget _buildFullSizeCardWithLogo(
    BuildContext context,
    NewsProvider newsProvider,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.all(screenWidth * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: screenHeight * 0.03,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              bottom: screenHeight * 0.02,
            ),
            child: Stack(
              children: [
                Center(
                  child: Image.asset(
                    'assets/timelines.png',
                    height: screenHeight * 0.06,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      context.push(
                        '/feedback-detail',
                        extra: {
                          'onFeedbackSubmitted':
                              (
                                String feedbackType,
                                String feedbackText,
                                String headline,
                              ) {
                                print('Feedback submitted from Timeline:');
                                print('Type: $feedbackType');
                                print('Text: $feedbackText');
                                print('Headline: $headline');
                              },
                          'newsHeadline': 'Timeline Feedback',
                        },
                      );
                    },
                    child: Container(
                      width: screenWidth * 0.08,
                      height: screenWidth * 0.08,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: screenWidth * 0.008,
                            height: screenWidth * 0.008,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.005),
                          Container(
                            width: screenWidth * 0.008,
                            height: screenWidth * 0.008,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.005),
                          Container(
                            width: screenWidth * 0.008,
                            height: screenWidth * 0.008,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              shape: BoxShape.circle,
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
          Expanded(child: _buildScrollableHeadlinesList(context, newsProvider)),
        ],
      ),
    );
  }

  Widget _buildScrollableHeadlinesList(
    BuildContext context,
    NewsProvider newsProvider,
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading headlines...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Failed to load headlines',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _retryLoading, child: Text('Retry')),
          ],
        ),
      );
    }

    if (_headlinesWithNews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No headlines with news available',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for updates',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ..._headlinesWithNews.map((headline) {
            return _buildHeadlineItem(context, headline, newsProvider);
          }),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeadlineItem(
    BuildContext context,
    Map<String, dynamic> headline,
    NewsProvider newsProvider,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final relatedNews = headline['news_articles'] as List<News>;
    final headlineText = headline['headline_text'] ?? 'Unknown Headline';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openHeadlineListingInCard(context, headline),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (headline['headline_image'] != null)
                  Stack(
                    children: [
                      Container(
                        width: screenWidth * 0.15,
                        height: screenWidth * 0.15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(headline['headline_image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.015,
                            vertical: screenWidth * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.022,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Stack(
                    children: [
                      Container(
                        width: screenWidth * 0.15,
                        height: screenWidth * 0.15,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.article, color: Colors.grey.shade600),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.015,
                            vertical: screenWidth * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.022,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        headlineText,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w800,
                          letterSpacing: screenWidth * 0.0001,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: screenWidth * 0.03,
                            color: Colors.grey[700]!,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _getTimeAgo(headline['created_at']),
                            style: TextStyle(
                              fontSize: screenWidth * 0.028,
                              color: Colors.grey[700]!,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: screenWidth * 0.2,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: relatedNews.length,
              itemBuilder: (context, newsIndex) {
                final news = relatedNews[newsIndex];
                return _buildRelatedNewsItem(
                  context,
                  news,
                  screenWidth,
                  headline,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedNewsItem(
    BuildContext context,
    News news,
    double screenWidth,
    Map<String, dynamic> headline,
  ) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/headlines',
          extra: {'headline': headline, 'initialNews': news},
        );
      },
      child: Container(
        width: screenWidth * 0.7,
        margin: EdgeInsets.only(right: 5),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: screenWidth * 0.09,
              height: screenWidth * 0.09,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
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
              child: news.imageUrl == null || news.imageUrl!.isEmpty
                  ? Icon(
                      Icons.article,
                      color: Colors.grey.shade600,
                      size: screenWidth * 0.05,
                    )
                  : null,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: screenWidth * 0.025,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        news.timeAgo,
                        style: TextStyle(
                          fontSize: screenWidth * 0.024,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Recently';
    try {
      final createdTime = DateTime.parse(createdAt.toString());
      final now = DateTime.now();
      final difference = now.difference(createdTime);
      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
      if (difference.inHours < 24) return '${difference.inHours} hours ago';
      return '${difference.inDays} days ago';
    } catch (e) {
      return 'Recently';
    }
  }
}
