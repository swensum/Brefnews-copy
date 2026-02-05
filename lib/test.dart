import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/news_provider.dart';
import '../models/news_model.dart';
import 'repositories/marvelous_carousel.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      newsProvider.loadNews();
    });
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
        if (newsProvider.isLoading) return _buildShimmerLoader();
      
        return MarvelousCarousel(
        
          margin: 8,
         
          
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
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
                  news: news,
                  isActive: isActive,
                ),
              ),
            );           
          }).toList(),
        );
      },
    );
  }

  Widget _buildShimmerLoader() {
    return const Center(child: CircularProgressIndicator());
  }


}

class _NewsCard extends StatelessWidget {
  final News news;
  final bool isActive;

  const _NewsCard({
    required this.news,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxImageHeight = screenHeight * 0.35;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.004),
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
            // Image Section
            if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: maxImageHeight,
                  width: double.infinity,
                  child: Image.network(
                    news.imageUrl!,
                    width: double.infinity,
                    height: maxImageHeight,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: maxImageHeight,
                        color: Theme.of(context).colorScheme.outline,
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
                      return Container(
                        width: double.infinity,
                        height: maxImageHeight,
                        color: Theme.of(context).colorScheme.outline,
                        child: Icon(
                          Icons.broken_image,
                          color: Theme.of(context).colorScheme.outlineVariant,
                          size: screenWidth * 0.12,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: maxImageHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
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

            // Content Section
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
                      maxLines: 3,
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
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.outlineVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),

                                  // Time
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
          ],
        ),
      ),
    );
  }
}