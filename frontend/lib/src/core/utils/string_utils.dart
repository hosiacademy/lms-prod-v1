/// String Utilities for the LMS Frontend
class StringUtils {
  /// Strips HTML tags and decodes common HTML entities from a string.
  static String stripHtml(String html) {
    if (html.isEmpty) return html;
    
    String text = html
        // Replace block-level tags with a space so words don't run together
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '\n\n')
        .replaceAll(
            RegExp(r'</?(ul|ol|tr|td|th|div|h\d)[^>]*>', caseSensitive: false),
            ' ')
        .replaceAll(RegExp(r'<[^>]+>'), '') // remove remaining tags
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Normalize multiple newlines
        .replaceAll(RegExp(r' +'), ' ')        // Normalize multiple spaces
        .trim();
        
    return text;
  }
}
