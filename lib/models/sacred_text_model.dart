import '../services/markdown_service.dart';

class SacredTextModel {
  final String? sacredTextId;
  final String? title;
  final String? subtitle; // English transliteration for non-English titles
  final String? excerpt;
  final String? text; // Full content from API
  final String? languageUsed;
  final bool? usedFallback;
  final List<String>? highlights;
  final String? category;
  final String? author;
  final String? description;
  final List<String>? tags;
  final bool? isConverted;
  final String? originalLanguage;

  SacredTextModel({
    this.sacredTextId,
    this.title,
    this.subtitle,
    this.excerpt,
    this.text,
    this.languageUsed,
    this.usedFallback,
    this.highlights,
    this.category,
    this.author,
    this.description,
    this.tags,
    this.isConverted,
    this.originalLanguage,
  });

  factory SacredTextModel.fromJson(Map<String, dynamic> json) {
    return SacredTextModel(
      sacredTextId: json['sacredTextId'] ?? json['stotraId'] ?? json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      excerpt: json['excerpt'] ?? '',
      text: json['text'] ?? '',
      languageUsed: json['languageUsed'] ??
          json['language'] ??
          json['lang'] ??
          json['languageCode'] ??
          '',
      usedFallback: json['usedFallback'] ?? false,
      highlights: json['highlights'] != null 
          ? List<String>.from(json['highlights'])
          : [],
      category: json['category'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'])
          : [],
      isConverted: json['isConverted'] ?? false,
      originalLanguage: json['originalLanguage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sacredTextId': sacredTextId,
      'title': title,
      'subtitle': subtitle,
      'excerpt': excerpt,
      'text': text,
      'languageUsed': languageUsed,
      'usedFallback': usedFallback,
      'highlights': highlights,
      'category': category,
      'author': author,
      'description': description,
      'tags': tags,
      'isConverted': isConverted,
      'originalLanguage': originalLanguage,
    };
  }

  String get displayTitle {
    return (title != null && title!.isNotEmpty) ? title! : 'Untitled Sacred Text';
  }

  String get displaySubtitle {
    return (subtitle != null && subtitle!.isNotEmpty) ? subtitle! : '';
  }

  String get contentPreview {
    String content = excerpt ?? '';
    if (content.isEmpty) {
      // If no excerpt, try to get a short preview from full text
      content = text ?? '';
    }
    
    if (content.isEmpty) {
      return 'No description available';
    }
    
    // Clean the markdown first
    String cleanedContent = MarkdownService.cleanMarkdown(content);
    
    // First, limit by character count to approximately 2 lines (around 60-80 characters)
    if (cleanedContent.length > 80) {
      // Find a good breaking point (end of sentence or word)
      int cutPoint = 80;
      for (int i = 80; i > 40; i--) {
        if (i < cleanedContent.length && 
            (cleanedContent[i] == '.' || cleanedContent[i] == ' ' || cleanedContent[i] == '\n')) {
          cutPoint = i;
          break;
        }
      }
      cleanedContent = '${cleanedContent.substring(0, cutPoint)}...';
    }
    
    // Additional check: ensure we don't have more than 2 lines
    final lines = cleanedContent.split('\n');
    if (lines.length > 2) {
      // Take only first 2 lines and add ellipsis
      cleanedContent = '${lines.take(2).join('\n')}...';
    }
    
    return cleanedContent;
  }

  bool get hasContent => (excerpt != null && excerpt!.isNotEmpty) || (text != null && text!.isNotEmpty);
  
  // Full content for reading screen
  String get fullContent {
    if (text != null && text!.isNotEmpty) {
      return text!;
    }
    return excerpt ?? 'No content available for this sacred text.';
  }

  String get languageDisplay {
    if (languageUsed == null || languageUsed!.isEmpty) return '';
    
    switch (languageUsed!.toLowerCase()) {
      case 'itrans':
      case 'roman itrans (english)':
      case 'itrans (english)':
      case 'english':
        return 'English';
      case 'devanagari':
      case 'devanagari (hindi)':
      case 'hindi':
        return 'Devanagari (Hindi)';
      case 'iast':
        return 'IAST';
      case 'en':
        return 'English';
      case 'hi':
        return 'Devanagari (Hindi)';
      default:
        return languageUsed!;
    }
  }

  List<String> get displayHighlights {
    if (highlights == null) return [];
    
    return highlights!.map((highlight) {
      // Use the centralized markdown service for consistent processing
      return MarkdownService.cleanMarkdown(highlight);
    }).where((highlight) => highlight.isNotEmpty).toList();
  }

  // Backward compatibility getter for textId
  String? get textId => sacredTextId;
} 

extension SacredTextModelCopy on SacredTextModel {
  SacredTextModel copyWith({
    String? sacredTextId,
    String? title,
    String? subtitle,
    String? excerpt,
    String? text,
    String? languageUsed,
    bool? usedFallback,
    List<String>? highlights,
    String? category,
    String? author,
    String? description,
    List<String>? tags,
    bool? isConverted,
    String? originalLanguage,
  }) {
    return SacredTextModel(
      sacredTextId: sacredTextId ?? this.sacredTextId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      // Use explicit excerpt when provided, otherwise keep existing excerpt
      excerpt: excerpt ?? this.excerpt,
      text: text ?? this.text,
      languageUsed: languageUsed ?? this.languageUsed,
      usedFallback: usedFallback ?? this.usedFallback,
      highlights: highlights ?? this.highlights,
      category: category ?? this.category,
      author: author ?? this.author,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isConverted: isConverted ?? this.isConverted,
      originalLanguage: originalLanguage ?? this.originalLanguage,
    );
  }
}