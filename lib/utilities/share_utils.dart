// share_utils.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/news_model.dart';

class ShareUtils {
  // Share news card as image with text
  static Future<void> shareNewsCard({
    required GlobalKey globalKey,
    required News news,
    required BuildContext context,
  }) async {
    
    try {
      // Show loading indicator
      _showLoadingSnackBar(context);

      // Capture the widget as image
      final Uint8List? imageBytes = await _captureWidget(globalKey);

      String shareText = _buildShareText(news);
  if (!context.mounted) {
      print('Context no longer available');
      return;
    }
    
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (imageBytes != null && imageBytes.isNotEmpty) {
        try {
          // Create InShorts-style card with logo and remove headline
          final Uint8List? imageWithLogo = await _createInshortsStyleCard(
            imageBytes,
          );
          await _shareWithImage(
            imageWithLogo ?? imageBytes,
            shareText,
            news.title,
          );
          return;
        } catch (e) {
          print('Image sharing failed, falling back to text: $e');
          // Fall through to text sharing
        }
      }

      // Fallback to text sharing
      await _shareAsText(shareText, news.title);
    } catch (e) {
      print('Error sharing news card: $e');
       if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showShareError(context, e.toString());
    }
    }
  }

  // Create InShorts-style card with logo in bottom right and remove headline
  static Future<Uint8List?> _createInshortsStyleCard(Uint8List originalImageBytes) async {
    try {
      // Load the original image
      final ui.Codec originalCodec = await ui.instantiateImageCodec(originalImageBytes);
      final ui.FrameInfo originalFrame = await originalCodec.getNextFrame();
      final ui.Image originalImage = originalFrame.image;

      // Load the app logo
      final ByteData logoData = await rootBundle.load('assets/brefnews.png');
      final ui.Codec logoCodec = await ui.instantiateImageCodec(logoData.buffer.asUint8List());
      final ui.FrameInfo logoFrame = await logoCodec.getNextFrame();
      final ui.Image logoImage = logoFrame.image;

      // Calculate the area to keep (remove bottom 9% which is the headline section)
      final int headlineHeight = (originalImage.height * 0.09).round();
      final int newHeight = originalImage.height - headlineHeight;

      // Create first recorder to draw on full image
      final ui.PictureRecorder fullRecorder = ui.PictureRecorder();
      final Canvas fullCanvas = Canvas(fullRecorder);

      // Draw the entire original image
      fullCanvas.drawImage(originalImage, Offset.zero, Paint());

      // Add the logo at the very bottom of the ORIGINAL image (in the headline area)
      final double logoWidth = originalImage.width * 0.45;
      final double logoHeight = logoWidth * (logoImage.height / logoImage.width);
      final double padding = originalImage.width * 0.01;
      final double logoX = originalImage.width - logoWidth - padding;
      
      // Position logo at the very bottom of original image (in the area that will be removed)
      final double logoY = originalImage.height - logoHeight - padding;

      // Draw the logo on the full image
      fullCanvas.drawImageRect(
        logoImage,
        Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
        Rect.fromLTWH(logoX, logoY, logoWidth, logoHeight),
        Paint(),
      );

      // Convert the full image with logo
      final ui.Picture fullPicture = fullRecorder.endRecording();
      final ui.Image fullImageWithLogo = await fullPicture.toImage(originalImage.width, originalImage.height);

      // Now crop to remove the headline area (keeping the logo that was drawn in that area)
      final ui.PictureRecorder cropRecorder = ui.PictureRecorder();
      final Canvas cropCanvas = Canvas(cropRecorder);
      
      // Draw only the top part (excluding headline) but this includes the logo we just drew
      cropCanvas.drawImageRect(
        fullImageWithLogo,
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(), newHeight.toDouble()),
        Rect.fromLTWH(0, 0, originalImage.width.toDouble(), newHeight.toDouble()),
        Paint(),
      );

      // Convert the final cropped image to bytes
      final ui.Picture croppedPicture = cropRecorder.endRecording();
      final ui.Image finalImage = await croppedPicture.toImage(originalImage.width, newHeight);
      final ByteData? finalBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);

      print('InShorts-style card created with logo at very bottom');
      return finalBytes?.buffer.asUint8List();
    } catch (e) {
      print('Error creating InShorts-style card: $e');
      return originalImageBytes;
    }
  }

  // Capture widget as image
  static Future<Uint8List?> _captureWidget(GlobalKey globalKey) async {
    
    try {
     
      await Future.delayed(const Duration(milliseconds: 500));

      final buildContext = globalKey.currentContext;
      if (buildContext == null) {
        print('Share key context is null');
        return null;
      }
if (!buildContext.mounted) {
      print('Widget is no longer mounted');
      return null;
    }
      final RenderObject? renderObject = buildContext.findRenderObject();
      if (renderObject == null || !renderObject.isRepaintBoundary) {
        print('Render object not found or not a repaint boundary');
        return null;
      }

      final RenderRepaintBoundary boundary =
          renderObject as RenderRepaintBoundary;

      // Capture with high quality
      final double pixelRatio = 2.0;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        print('Failed to convert image to byte data');
        return null;
      }

      final Uint8List imageBytes = byteData.buffer.asUint8List();

      // Verify the image is not empty
      if (imageBytes.isEmpty) {
        print('Captured image is empty');
        return null;
      }

      print('Successfully captured widget image: ${imageBytes.length} bytes');
      return imageBytes;
    } catch (e) {
      print('Error capturing widget: $e');
      return null;
    }
  }

  // Build share text
  static String _buildShareText(News news) {
    String headlineText = '';
    if (news.headline != null && news.headline!['headline'] != null) {
      headlineText = '📢 ${news.headline!['headline']}\n';
    }
    if (news.headline != null && news.headline!['subheadline'] != null) {
      headlineText += '${news.headline!['subheadline']}\n\n';
    }

    return """
📰 ${news.title}

📝 ${news.summary}

🔗 Source: ${news.source}
⏰ ${news.timeAgo}

$headlineText📲 Shared via BrefNews
Download the app for quick news updates!
    """
        .trim();
  }

  // Share with image
  static Future<void> _shareWithImage(
    Uint8List imageBytes,
    String shareText,
    String subject,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = await File(
        '${tempDir.path}/brefnews_$timestamp.png',
      ).create();
      await file.writeAsBytes(imageBytes);

      print('Sharing image file: ${file.path}');

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: subject,
      );

      // Clean up after delay
      Future.delayed(const Duration(seconds: 30), () {
        if (file.existsSync()) {
          file.deleteSync();
          print('Cleaned up temporary file: ${file.path}');
        }
      });
    } catch (e) {
      print('Error sharing with image: $e');
      rethrow;
    }
  }

  // Share as text only
  static Future<void> _shareAsText(String shareText, String subject) async {
    try {
      // ignore: deprecated_member_use
      await Share.share(shareText, subject: subject);
    } catch (e) {
      print('Share.share failed: $e');
      rethrow;
    }
  }

  // Show loading indicator
  static void _showLoadingSnackBar(BuildContext context) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 12),
          Text('Preparing share...'),
        ],
      ),
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 5),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Show error message to user
  static void _showShareError(BuildContext context, String error) {
    String errorMessage;

    if (error.contains('MissingPluginException')) {
      errorMessage = 'Sharing not available. Please restart the app.';
    } else if (error.contains('PlatformException')) {
      errorMessage = 'Sharing failed. Please try again.';
    } else {
      errorMessage = 'Failed to share: $error';
    }

    final snackBar = SnackBar(
      content: Text(errorMessage),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}