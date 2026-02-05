
import 'package:html/parser.dart' as html_parser;


class HtmlUtils {
  // Extract plain text from HTML
  static String extractPlainText(String htmlString) {
    try {
      if (htmlString.isEmpty) return '';
      
      final document = html_parser.parse(htmlString);
      return document.body?.text ?? htmlString;
    } catch (e) {
      // If parsing fails, return the original string with basic cleaning
      return _basicHtmlClean(htmlString);
    }
  }

  // Basic HTML tag removal without parsing
  static String _basicHtmlClean(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&#8230;', '...') 
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  // Check if string contains HTML
  static bool containsHtml(String text) {
    return text.contains(RegExp(r'<[^>]*>'));
  }

  // Get a clean summary for display
  static String getCleanSummary(String summary) {
    if (containsHtml(summary)) {
      return extractPlainText(summary);
    }
    return summary;
  }

  // Extract first paragraph for preview
  static String getFirstParagraph(String htmlString) {
    try {
      if (htmlString.isEmpty) return '';
      
      final document = html_parser.parse(htmlString);
      final paragraphs = document.querySelectorAll('p');
      
      if (paragraphs.isNotEmpty) {
        final firstParagraph = paragraphs.first.text;
        return firstParagraph.isNotEmpty ? firstParagraph : extractPlainText(htmlString);
      }
      
      return extractPlainText(htmlString);
    } catch (e) {
      return extractPlainText(htmlString);
    }
  }
}