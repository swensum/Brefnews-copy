import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/authservice.dart';
import '../component/icons.dart';
import '../provider/news_provider.dart';

import '../supabase/supabase_client.dart';
import '../utilities/local_preferences_service.dart';

class PreferencePage extends StatefulWidget {
  const PreferencePage({super.key});

  @override
  State<PreferencePage> createState() => _PreferencePageState();
}

class _PreferencePageState extends State<PreferencePage> {
  final Map<String, String> _topicPreferences = {};
  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndPreferences();
  }

  Future<void> _loadUserAndPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user info
      final userData = await AuthService.getCurrentUser();
      _currentUserId = userData?['id'];
      
      print('Loading preferences for user: $_currentUserId');

      // Load from local storage first for immediate display
      final localPreferences = await LocalStorageService().getTopicPreferences(
        userId: _currentUserId,
      );
      
      setState(() {
        _topicPreferences.addAll(localPreferences);
      });

      // If user is authenticated, try to load from Supabase
      if (_currentUserId != null) {
        final supabaseService = SupabaseService();
        final remotePreferences = await supabaseService.getUserTopicPreferences();
        
        // Merge remote preferences (they take precedence)
        setState(() {
          _topicPreferences.addAll(remotePreferences);
        });

        // Save merged preferences back to local storage
        await LocalStorageService().saveTopicPreferences(
          _topicPreferences, 
          userId: _currentUserId,
        );
      }

    } catch (e) {
      print('Failed to load preferences: $e');
      // Continue with local preferences if remote fails
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    // Fetch topics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      newsProvider.fetchTopics();
    });
  }

  Future<void> _setTopicPreference(String topicName, String preference) async {
    final oldPreference = _getTopicPreference(topicName);
    final supabaseService = SupabaseService();
    
    setState(() {
      if (preference.isEmpty) {
        _topicPreferences.remove(topicName);
      } else {
        _topicPreferences[topicName] = preference;
      }
    });

    try {
      // Save to Supabase - works for both authenticated and non-authenticated users
      await supabaseService.saveTopicPreference(topicName, preference);
      print('Preference saved to Supabase: $topicName -> $preference');
      
      // Always save to local storage
      await LocalStorageService().saveTopicPreferences(
        _topicPreferences, 
        userId: _currentUserId,
      );

    } catch (e) {
      print('Failed to save preference: $e');
      
      // Revert UI if save failed
      setState(() {
        if (oldPreference.isEmpty) {
          _topicPreferences.remove(topicName);
        } else {
          _topicPreferences[topicName] = oldPreference;
        }
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preference: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTopicPreference(String topicName) {
    return _topicPreferences[topicName] ?? '';
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  List<Map<String, dynamic>> _getFilteredTopics(
    List<Map<String, dynamic>> allTopics,
  ) {
    switch (_selectedFilter) {
      case 'Interested':
        return allTopics.where((topic) {
          final topicName = topic['name'] as String;
          return _getTopicPreference(topicName) == 'interested';
        }).toList();
      case 'Not Interested':
        return allTopics.where((topic) {
          final topicName = topic['name'] as String;
          return _getTopicPreference(topicName) == 'not_interested';
        }).toList();
      case 'All':
      default:
        return allTopics;
    }
  }

  List<Map<String, dynamic>> _getMarkedTopics(
    List<Map<String, dynamic>> allTopics,
  ) {
    return allTopics.where((topic) {
      final topicName = topic['name'] as String;
      return _getTopicPreference(topicName).isNotEmpty;
    }).toList();
  }

  List<Map<String, dynamic>> _getUnmarkedTopics(
    List<Map<String, dynamic>> allTopics,
  ) {
    return allTopics.where((topic) {
      final topicName = topic['name'] as String;
      return _getTopicPreference(topicName).isEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color:  Theme.of(context).colorScheme.onSurface,
            size: screenWidth * 0.06,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Section
                Container(
                  color:  Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Main Heading
                        Text(
                          'Your Preferences',
                          style: TextStyle(
                            color:  Theme.of(context).colorScheme.primary,
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.01),
                        Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "You'll see more shorts from topics marked as ",
                                    style: TextStyle(
                                      color:  Theme.of(context).colorScheme.onSurface,
                                      fontSize: screenWidth * 0.036,
                                      letterSpacing: screenWidth * 0.0001,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.007),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '"Interested',
                                    style: TextStyle(
                                      color:  Theme.of(context).colorScheme.onSurface,
                                      fontSize: screenWidth * 0.036,
                                      letterSpacing: screenWidth * 0.0001,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                  Container(
                                    width: screenWidth * 0.06,
                                    height: screenWidth * 0.06,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.thumb_up_rounded,
                                      color: Color(0xFF006400),
                                      size: screenWidth * 0.03,
                                    ),
                                  ),
                                  Text(
                                    '"',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: screenWidth * 0.036,
                                      letterSpacing: screenWidth * 0.0001,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    'and less from topics marked as "Not',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: screenWidth * 0.036,
                                      letterSpacing: screenWidth * 0.0001,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.007),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Interested ",
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: screenWidth * 0.036,
                                      letterSpacing: screenWidth * 0.0001,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                  Container(
                                    width: screenWidth * 0.06,
                                    height: screenWidth * 0.06,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha:  0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.thumb_down_rounded,
                                      color: Colors.red,
                                      size: screenWidth * 0.03,
                                    ),
                                  ),
                                  Text(
                                    '" .',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: screenWidth * 0.036,
                                      letterSpacing: screenWidth * 0.0001,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    'Feel free to add or remove topics to',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: screenWidth * 0.036,
                                      letterSpacing: screenWidth * 0.0001,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.007),
                              Text(
                                'personalize your feed.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: screenWidth * 0.036,
                                  letterSpacing: screenWidth * 0.0001,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.04),
                      ],
                    ),
                  ),
                ),

              
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOptionButton(context, 'All', _selectedFilter == 'All'),
                      SizedBox(width: screenWidth * 0.03),
                      _buildOptionButton(context, 'Interested', _selectedFilter == 'Interested'),
                      SizedBox(width: screenWidth * 0.03),
                      _buildOptionButton(context, 'Not Interested', _selectedFilter == 'Not Interested'),
                    ],
                  ),
                ),

                // Divider line
                Container(height: 1, color:Theme.of(context).colorScheme.outline,),

                // Scrollable Content Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.02),
                          
                          if (_selectedFilter == 'All')
                            Consumer<NewsProvider>(
                              builder: (context, newsProvider, child) {
                                if (newsProvider.topics.isEmpty) return SizedBox();
                                final markedTopics = _getMarkedTopics(newsProvider.topics);
                                if (markedTopics.isEmpty) return SizedBox();

                                return Column(
                                  children: [
                                    ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: markedTopics.length,
                                      itemBuilder: (context, index) {
                                        final topic = markedTopics[index];
                                        final topicName = topic['name'] as String;
                                        final currentPreference = _getTopicPreference(topicName);

                                        return _buildTopicItem(
                                          context,
                                          topicName: topicName,
                                          currentPreference: currentPreference,
                                          onPreferenceChanged: (preference) {
                                            _setTopicPreference(topicName, preference);
                                          },
                                        );
                                      },
                                    ),
                                    SizedBox(height: screenHeight * 0.04),
                                  ],
                                );
                              },
                            ),

                          if (_selectedFilter == 'All')
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No input was provided for the following topics.\nPlease mark your selection',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: screenWidth * 0.036,
                                  letterSpacing: screenWidth * 0.0001,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                          SizedBox(height: screenHeight * 0.02),

                          Consumer<NewsProvider>(
                            builder: (context, newsProvider, child) {
                              if (newsProvider.topics.isEmpty) {
                                return Center(child: CircularProgressIndicator());
                              }

                              List<Map<String, dynamic>> displayTopics = _selectedFilter == 'All'
                                  ? _getUnmarkedTopics(newsProvider.topics)
                                  : _getFilteredTopics(newsProvider.topics);

                              if (displayTopics.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: screenHeight * 0.1),
                                    child: Text(
                                      _selectedFilter == 'All'
                                          ? 'All topics have been marked!'
                                          : 'No topics marked as $_selectedFilter',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                        fontSize: screenWidth * 0.038,
                                      ),
                                    ),
                                  ),
                                );
                              }

                             return ListView.separated(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: displayTopics.length,
                                 separatorBuilder: (context, index) => SizedBox(height: screenHeight * 0.01),
                                itemBuilder: (context, index) {
                                  final topic = displayTopics[index];
                                  final topicName = topic['name'] as String;
                                  final currentPreference = _getTopicPreference(topicName);

                                  return _buildTopicItem(
                                    context,
                                    topicName: topicName,
                                    currentPreference: currentPreference,
                                    onPreferenceChanged: (preference) {
                                      _setTopicPreference(topicName, preference);
                                    },
                                    
                                  );
                                  
                                },
                                
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      );
  }

  Widget _buildTopicItem(
    BuildContext context, {
    required String topicName,
    required String currentPreference,
    required Function(String) onPreferenceChanged,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
  width: double.infinity,
  padding: EdgeInsets.all(screenWidth * 0.04),
  decoration: BoxDecoration(
    color: Theme.of(context).brightness == Brightness.dark 
        ? Theme.of(context).colorScheme.onSecondary
        : Colors.transparent,
    borderRadius: BorderRadius.circular(16),
   
  ),
  child: Row(
    children: [
      // Topic Icon
      Container(
        width: screenWidth * 0.08,
        height: screenWidth * 0.08,
        decoration: BoxDecoration(
          color: TopicIcons.getColorForTopic(topicName).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          TopicIcons.getIconForTopic(topicName),
          color: TopicIcons.getColorForTopic(topicName),
          size: screenWidth * 0.04,
        ),
      ),

      SizedBox(width: screenWidth * 0.03),

      // Topic Name
      Expanded(
        child: Text(
          topicName,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface, 
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Like/Dislike Icons
      Row(
        children: [
          // Like Button
          GestureDetector(
            onTap: () {
              final newPreference = currentPreference == 'interested'
                  ? ''
                  : 'interested';
              onPreferenceChanged(newPreference);
            },
            child: Container(
              width: screenWidth * 0.08,
              height: screenWidth * 0.08,
              decoration: BoxDecoration(
                color: currentPreference == 'interested'
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.thumb_up_rounded,
                color: currentPreference == 'interested'
                    ? Color(0xFF006400)
                    : Theme.of(context).textTheme.bodyLarge?.color,
                size: screenWidth * 0.035,
              ),
            ),
          ),

          SizedBox(width: screenWidth * 0.02),

          // Dislike Button
          GestureDetector(
            onTap: () {
              final newPreference = currentPreference == 'not_interested'
                  ? ''
                  : 'not_interested';
              onPreferenceChanged(newPreference);
            },
            child: Container(
              width: screenWidth * 0.08,
              height: screenWidth * 0.08,
              decoration: BoxDecoration(
                color: currentPreference == 'not_interested'
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.thumb_down_rounded,
                color: currentPreference == 'not_interested'
                    ? Colors.red
                    : Theme.of(context).textTheme.bodyLarge?.color,
                size: screenWidth * 0.035,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
);
  }

  Widget _buildOptionButton(
    BuildContext context,
    String text,
    bool isSelected,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => _setFilter(text),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromARGB(26, 21, 101, 192) : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}