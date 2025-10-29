import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../language/app_localizations.dart';

class NewFeedbackPage extends StatefulWidget {
  final Function(String, String, String) onFeedbackSubmitted;
  final String? newsHeadline; // Add this parameter

  const NewFeedbackPage({
    super.key, 
    required this.onFeedbackSubmitted,
    this.newsHeadline, // Make it optional
  });

  @override
  State<NewFeedbackPage> createState() => _NewFeedbackPageState();
}

class _NewFeedbackPageState extends State<NewFeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _headlineController = TextEditingController(); 
  String? _selectedFeedbackType;
  final List<PlatformFile> _selectedFiles = [];
  late List<String> _feedbackTypes;
  
  // Validation error states
  String? _feedbackTypeError;
  String? _feedbackTextError;

  @override
  void initState() {
    super.initState();
    if (widget.newsHeadline != null && widget.newsHeadline!.isNotEmpty) {
      _headlineController.text = widget.newsHeadline!;
      _feedbackTypes = [
      'Content related issue',
      'Suggestion', 
      'Technical Glitch',
      'General',
      'Others',
    ];
    }
  }
   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now it's safe to access context and localizations
    _initializeFeedbackTypes();
  }
   void _initializeFeedbackTypes() {
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      _feedbackTypes = [
        localizations.contentRelatedIssue,
        localizations.suggestion,
        localizations.technicalGlitch,
        localizations.general,
        localizations.others,
      ];
    }
   }
  

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc'],
        allowMultiple: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  bool _isImageFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    return extension == 'jpg' || extension == 'jpeg' || extension == 'png';
  }

  void _showFeedbackTypeBottomSheet() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
 final localizations = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(screenWidth * 0.05),
          topRight: Radius.circular(screenWidth * 0.05),
        ),
      ),
      builder: (context) => Container(
        height: screenHeight * 0.6,
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            // Header with title and close button in black container
            Container(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.selectFeedbackType,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.cancel, 
                          color: Colors.white, 
                          size: screenWidth * 0.045
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Feedback type options without icons
            Expanded(
              child: ListView.builder(
                itemCount: _feedbackTypes.length,
                itemBuilder: (context, index) {
                  final type = _feedbackTypes[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      border: Border.all(
                        color: _selectedFeedbackType == type
                            ? Colors.blue
                            : Colors.grey[300]!,
                        width: _selectedFeedbackType == type ? 
                            screenWidth * 0.005 : screenWidth * 0.003,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        type,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: _selectedFeedbackType == type
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _selectedFeedbackType == type
                              ? Colors.blue
                              : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedFeedbackType = type;
                          _feedbackTypeError = null;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitFeedback() async {
     final localizations = AppLocalizations.of(context)!;
    // Reset previous errors
    setState(() {
      _feedbackTypeError = null;
      _feedbackTextError = null;
    });

    // Validate feedback type
    if (_selectedFeedbackType == null) {
      setState(() {
        _feedbackTypeError = localizations.pleaseSelectFeedbackType;
      });
      return;
    }

    // Validate feedback text
    if (_feedbackController.text.trim().isEmpty) {
      setState(() {
        _feedbackTextError = localizations.pleaseEnterFeedback;
      });
      return;
    }

    try {
      String? fileUrl;

      // Step 1: Upload the file to Supabase Storage if one exists
      if (_selectedFiles.isNotEmpty && _selectedFiles.first.path != null) {
        final file = _selectedFiles.first;
        
        // Generate a unique file name to avoid conflicts
        final fileName = 'feedback_${DateTime.now().millisecondsSinceEpoch}.${file.extension}';
        
        // Upload file to Supabase Storage
        await Supabase.instance.client.storage
            .from('feedback')
            .upload(fileName, File(file.path!));
        
        // Get the public URL for the uploaded file
        fileUrl = Supabase.instance.client.storage
            .from('feedback')
            .getPublicUrl(fileName);
      }

      // Step 2: Save feedback data to the database
      final feedbackData = {
        'feedback_type': _selectedFeedbackType,
        'feedback_text': _feedbackController.text.trim(),
        'headline': _headlineController.text.trim(), // Include headline in submission
        'attached_file_url': fileUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert into database
      final response = await Supabase.instance.client
          .from('feedback')
          .insert(feedbackData)
          .select();

      print('Database insert response: $response');

      // Handle the response - check if UUID exists, otherwise use id
      final insertedData = response[0];
      final insertedUuid = insertedData['uuid'] as String? ?? insertedData['id']?.toString();

      print('Inserted UUID/ID: $insertedUuid');
if (!mounted) return;
      final screenWidth = MediaQuery.of(context).size.width;
      if (!mounted) return;
      await showDialog(
        
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                 localizations.thankYou,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: screenWidth * 0.045,
                  ),
                ),
              ],
            ),
            content: Text(
              localizations.feedbackSuccess,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.black54,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  localizations.ok,
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
              ),
            ],
          );
        },
      );

      // Return to FeedbackPage
      if (mounted) {
        Navigator.of(context).pop({
          'success': true,
        });
      }
      
    } catch (error) {
      print('Error submitting feedback: $error');
      setState(() {
        _feedbackTextError = 'Failed to submit feedback. Please try again.';
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
          icon: Icon(
            Icons.arrow_back, 
            color: Theme.of(context).colorScheme.onSurface, 
            size: screenWidth * 0.06
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.newFeedback,
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   
                    if (widget.newsHeadline != null && widget.newsHeadline!.isNotEmpty) ...[
                      Text(
                        localizations.shortHeadline,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.001,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: screenWidth * 0.003,
                          ),
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        child: TextField(
                          controller: _headlineController,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: localizations.shortHeadlinePlaceholder,
                            hintStyle: TextStyle(
                              color: Theme.of(context).textTheme.titleMedium?.color,
                              fontSize: screenWidth * 0.04,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          readOnly: true, // Make it read-only since it's auto-filled
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                    ],
        
                    // Feedback Type Section
                    Text(
                      localizations.feedbackType,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    
                    // Feedback Type Selector Button
                    GestureDetector(
                      onTap: _showFeedbackTypeBottomSheet,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border.all(
                            color: _feedbackTypeError != null ? 
                                Colors.red : Theme.of(context).colorScheme.outline,
                            width: screenWidth * 0.003,
                          ),
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedFeedbackType ?? localizations.select,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: _selectedFeedbackType != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.grey[500],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color:  Theme.of(context).colorScheme.outline,
                              size: screenWidth * 0.06,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Feedback Type Error Message
                    if (_feedbackTypeError != null) ...[
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        _feedbackTypeError!,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.red,
                        ),
                      ),
                    ],
        
                    SizedBox(height: screenHeight * 0.04),
        
                    // Your Feedback Section
                    Text(
                      localizations.yourFeedback,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface, 
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Container(
                      height: screenHeight * 0.25,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _feedbackTextError != null ? 
                              Colors.red : Theme.of(context).colorScheme.outline,
                          width: screenWidth * 0.003,
                        ),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: TextField(
                        controller: _feedbackController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: screenWidth * 0.04,
                        ),
                        onChanged: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() {
                              _feedbackTextError = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: localizations.feedbackPlaceholder,
                          hintStyle: TextStyle(
                            color: Theme.of(context).textTheme.titleMedium?.color,
                            fontSize: screenWidth * 0.04,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(screenWidth * 0.04),
                          errorBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    
                    // Feedback Text Error Message
                    if (_feedbackTextError != null) ...[
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        _feedbackTextError!,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.red,
                        ),
                      ),
                    ],
        
                    SizedBox(height: screenHeight * 0.03),
        
                    // Attach Media Text - Clickable only when no files are selected
                    _selectedFiles.isEmpty
                        ? GestureDetector(
                            onTap: _pickFile,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  color: Theme.of(context).colorScheme.primary, 
                                  size: screenWidth * 0.05,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  localizations.attachMedia,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary, 
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                color: Theme.of(context).colorScheme.outlineVariant, 
                                size: screenWidth * 0.05,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                localizations.attachMedia,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.outlineVariant, 
                                ),
                              ),
                            ],
                          ),
        
                    // Selected Files Display with Add More button
                    if (_selectedFiles.isNotEmpty) ...[
                      SizedBox(height: screenHeight * 0.02),
                      Wrap(
                        spacing: screenWidth * 0.03,
                        runSpacing: screenHeight * 0.02,
                        children: [
                        
                          ..._selectedFiles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final file = entry.value;
                            return Container(
                              width: screenWidth * 0.20,
                              height: screenHeight * 0.18,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: screenWidth * 0.003,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Image preview
                                  if (_isImageFile(file))
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(screenWidth * 0.015),
                                      child: Image.file(
                                        File(file.path!),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey[400],
                                              size: screenWidth * 0.06,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  else
                                    Center(
                                      child: Icon(
                                        Icons.insert_drive_file,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: screenWidth * 0.06,
                                      ),
                                    ),
                                  
                                  // Close button
                                  Positioned(
                                    top: screenWidth * 0.005,
                                    right: screenWidth * 0.005,
                                    child: GestureDetector(
                                      onTap: () => _removeFile(index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.onSurface, 
                                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                          size: screenWidth * 0.035,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          // Add More Container
                          GestureDetector(
                            onTap: _pickFile,
                            child: Container(
                              width: screenWidth * 0.20,
                              height: screenHeight * 0.18,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                border: Border.all(
                                  color: Colors.grey[400]!,
                                  width: screenWidth * 0.003,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Colors.grey[600],
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  Text(
                                    localizations.add,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.03,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Add some extra space at the bottom for scrolling
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
        
          
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                  ),
                ),
                child: Text(
                  localizations.submitFeedback,
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

  @override
  void dispose() {
    _feedbackController.dispose();
    _headlineController.dispose();
    super.dispose();
  }
}