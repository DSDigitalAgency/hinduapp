import '../services/markdown_service.dart';

class TempleModel {
  final String? templeId;
  final String? title;
  final String? excerpt;
  final String? text; // Full content from API
  final String? category;
  final List<String>? highlights;

  TempleModel({
    this.templeId,
    this.title,
    this.excerpt,
    this.text,
    this.category,
    this.highlights,
  });

  factory TempleModel.fromJson(Map<String, dynamic> json) {
    return TempleModel(
      templeId: json['templeId'] ?? json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      excerpt: json['excerpt'] ?? '',
      text: json['text'] ?? '', // Full content from API
      category: json['category'] ?? '',
      highlights: json['highlights'] != null 
          ? List<String>.from(json['highlights'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templeId': templeId,
      'title': title,
      'excerpt': excerpt,
      'text': text,
      'category': category,
      'highlights': highlights,
    };
  }

  // Display title with fallback
  String get displayTitle {
    return title ?? 'Unknown Temple';
  }

  // Content preview for search results
  String get contentPreview {
    if (excerpt != null && excerpt!.isNotEmpty) {
      // Use the centralized markdown service for consistent processing
      // Show full excerpt for reading, not truncated preview
      final cleaned = MarkdownService.cleanMarkdown(excerpt!);
      // Remove ALL currency markers and placeholders like $1, $2, etc. from anywhere in the text
      final sanitized = cleaned
          .replaceAll(RegExp(r'\$\d+'), '') // Remove $1, $2, $3, etc. from anywhere
          .replaceAll(RegExp(r'^\d+\.\s*'), '') // Remove leading numbers like "1. ", "2. "
          .replaceAll(RegExp(r'^\s*[-•]\s*'), '') // Remove leading bullets or dashes
          .trim();
      return sanitized.isEmpty ? 'No description available' : sanitized;
    }
    // If excerpt is empty but full text exists, generate a short preview
    if (text != null && text!.isNotEmpty) {
      final cleaned = MarkdownService.cleanMarkdown(text!);
      final sanitized = cleaned
          .replaceAll(RegExp(r'\$\d+'), '') // Remove $1, $2, $3, etc. from anywhere
          .replaceAll(RegExp(r'^\d+\.\s*'), '') // Remove leading numbers like "1. ", "2. "
          .replaceAll(RegExp(r'^\s*[-•]\s*'), '') // Remove leading bullets or dashes
          .trim();
      if (sanitized.isEmpty) return 'No description available';
      return sanitized.length > 140 ? '${sanitized.substring(0, 140)}...' : sanitized;
    }
    return 'No description available';
  }

  // Keep original markdown (trimmed) for card rendering
  String get markdownPreview {
    final source = (excerpt != null && excerpt!.isNotEmpty)
        ? excerpt!
        : (text ?? '');
    if (source.isEmpty) return 'No description available';
    String s = source.trim();
    if (s.length > 200) {
      s = '${s.substring(0, 200)}...';
    }
    return s;
  }

  // Full content for detailed view
  String get fullContent {
    if (text != null && text!.isNotEmpty) {
      return text!;
    }
    if (excerpt != null && excerpt!.isNotEmpty) {
      return excerpt!;
    }
    return 'No content available for this temple.';
  }

  // Check if temple has content
  bool get hasContent {
    return (text != null && text!.isNotEmpty) || (excerpt != null && excerpt!.isNotEmpty);
  }

  // Get category display name
  String get categoryDisplay {
    if (category == null || category!.isEmpty) return '';
    
    // Convert category to readable format
    return category!
        .replaceAll('_', ' ')
        .replaceAll('108', '108 ')
        .trim();
  }

  // Get highlights for search results
  List<String> get displayHighlights {
    if (highlights == null || highlights!.isEmpty) return [];
    
    return highlights!.map((highlight) {
      // Use the centralized markdown service for consistent processing
      return MarkdownService.cleanMarkdown(highlight);
    }).toList();
  }
} 