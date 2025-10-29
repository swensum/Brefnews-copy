import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../language/app_localizations.dart';
import 'feedbackdetail.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    try {
      final response = await Supabase.instance.client
          .from('feedback')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _feedbacks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading feedbacks: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface, size: screenWidth * 0.06),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.feedback,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.045,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(screenWidth, screenHeight)
                  : _feedbacks.isEmpty 
                      ? _buildEmptyState(screenWidth, screenHeight) 
                      : _buildFeedbackList(screenWidth, screenHeight),
            ),
            // New Feedback Button at Bottom
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewFeedbackPage(
                        onFeedbackSubmitted: (type, message, date) {
                         
                        },
                      ),
                    ),
                  );
        
                 
                  if (result != null && mounted) {
                    _loadFeedbacks(); 
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                  ),
                ),
                child: Text(
                 localizations.newFeedback,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(double screenWidth, double screenHeight) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: screenWidth * 0.01,
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feedback_outlined,
              color: Theme.of(context).colorScheme.onSurface,
              size: screenHeight * 0.1,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
             localizations.emptyFeedback,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: screenWidth * 0.04,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList(double screenWidth, double screenHeight) {
    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      itemCount: _feedbacks.length,
      itemBuilder: (context, index) {
        final feedback = _feedbacks[index];
        final dateTime = DateTime.parse(feedback['created_at']);
        final formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
        final formattedTime = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

        final uuid = feedback['uuid'] as String?;
        final displayUuid = uuid != null 
            ? uuid.replaceAll('-', '').toLowerCase()
            : 'N/A';
        
        return Card(
          color: Theme.of(context).colorScheme.surface,
          margin: EdgeInsets.only(bottom: screenHeight * 0.015),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // UUID at the top
                Text(
                  '# $displayUuid',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                
                // Feedback Type
                Text(
                  feedback['feedback_type'] ?? 'No type',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
               
                // Feedback Message
                Text(
                  feedback['feedback_text'] ?? 'No message',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                
                // Image container (if available)
                if (feedback['attached_file_url'] != null)
                  Container(
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: screenWidth * 0.003,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      child: Image.network(
                        feedback['attached_file_url'],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: screenWidth * 0.008,
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
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              color: Theme.of(context).colorScheme.outline,
                              size: screenWidth * 0.06,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                
                SizedBox(height: screenHeight * 0.015),
                
                // Date and Time at bottom right corner
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '$formattedDate at $formattedTime',
                    style: TextStyle(
                      color:  Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.032,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}