class TextSanitizer {
  static String sanitizeText(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .replaceAll('\u2019', "'") // Right single quotation mark
        .replaceAll('\u2018', "'") // Left single quotation mark
        .replaceAll('&apos;', "'") // HTML entity
        .replaceAll('&#39;', "'") // HTML entity numeric
        .replaceAll('\u201C', '"') // Left double quotation mark
        .replaceAll('\u201D', '"') // Right double quotation mark
        .replaceAll('&quot;', '"') // HTML quote entity
        .replaceAll('&#34;', '"') // HTML quote entity numeric
        .replaceAll('\u2013', '-') // En dash
        .replaceAll('\u2014', '-') // Em dash
        .replaceAll('&nbsp;', ' '); // Non-breaking space
  }

  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is String) {
        sanitized[key] = sanitizeText(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = sanitizeMap(value);
      } else if (value is List<dynamic>) {
        sanitized[key] = value.map((item) {
          if (item is String) {
            return sanitizeText(item);
          } else if (item is Map<String, dynamic>) {
            return sanitizeMap(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }
}
