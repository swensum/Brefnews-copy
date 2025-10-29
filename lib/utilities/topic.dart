import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../language/app_localizations.dart';
import '../provider/news_provider.dart';

class AllTopicsPage extends StatefulWidget {
  const AllTopicsPage({super.key});

  @override
  State<AllTopicsPage> createState() => _AllTopicsPageState();
}

class _AllTopicsPageState extends State<AllTopicsPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
 final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          localizations.allTopics,
          style: TextStyle(
            color: Colors.black,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2.0),
          child: Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey[200], // You can change this color
          ),
        ),
      ),
      body: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          if (newsProvider.topics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.topic,
                    color: Colors.grey,
                    size: screenWidth * 0.15,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    localizations.noTopicsAvailable,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildTopicsGrid(newsProvider, screenWidth, screenHeight);
        },
      ),
    );
  }

  Widget _buildTopicsGrid(NewsProvider newsProvider, double screenWidth, double screenHeight) {
    return GridView.builder(
      padding: EdgeInsets.zero, // Remove all padding
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columns
        crossAxisSpacing: screenWidth * 0.001,
        mainAxisSpacing: screenWidth * 0.001,
        childAspectRatio: 1, // Adjusted for larger images
      ),
      itemCount: newsProvider.topics.length,
      itemBuilder: (context, index) {
        final topic = newsProvider.topics[index];
        return _buildTopicGridItem(context, topic, screenWidth);
      },
    );
  }

  Widget _buildTopicGridItem(BuildContext context, Map<String, dynamic> topic, double screenWidth) {
    final topicName = topic['name'] as String;
    final imageUrl = topic['image_url'] as String?;

    return GestureDetector(
      onTap: () {
        context.push(
          '/topics-detail', 
          extra: {
            'topic': topic,
            'initialNews': null,
          }
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Larger Topic Image/Icon
          Container(
            width: screenWidth * 0.35, // Larger size
            height: screenWidth * 0.35, // Larger size
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16), // Slightly more rounded
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: screenWidth * 0.35,
                      height: screenWidth * 0.35,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.topic,
                            color: Colors.grey[600],
                            size: screenWidth * 0.1, // Larger icon
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.topic,
                        color: Colors.grey[600],
                        size: screenWidth * 0.1, // Larger icon
                      ),
                    ),
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          
          // Topic Name Only
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            child: Text(
              topicName,
              style: TextStyle(
                color: Colors.black,
                fontSize: screenWidth * 0.039,
                fontWeight: FontWeight.w700,
                letterSpacing: screenWidth * 0.0001
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}