// No debug prints in production
import '../services/youtube_service.dart';

class VideoModel {
  final String id;
  final String? youtubeUrl;
  final String? youtubeId;
  final String? title;
  final String? description;
  final DateTime? createdAt;
  final Map<String, dynamic>? _youtubeMetadata;
  final String? language;
  final String? category;

  VideoModel({
    required this.id,
    this.youtubeUrl,
    this.youtubeId,
    this.title,
    this.description,
    this.createdAt,
    this.language,
    this.category,
    Map<String, dynamic>? youtubeMetadata,
  }) : _youtubeMetadata = youtubeMetadata;

  // Language mapping helpers
  static const Map<String, String> _languageCodeToName = {
    'en': 'English',
    'hi': 'Hindi',
    'sa': 'Sanskrit',
    'ta': 'Tamil',
    'te': 'Telugu',
    'ml': 'Malayalam',
    'kn': 'Kannada',
    'bn': 'Bengali',
    'gu': 'Gujarati',
    'mr': 'Marathi',
    'pa': 'Punjabi',
    'or': 'Odia',
    'od': 'Odia',
    'as': 'Assamese',
    'ur': 'Urdu',
  };

  static String? languageNameFromCode(String? code) {
    if (code == null) return null;
    final key = code.toLowerCase();
    return _languageCodeToName[key] ?? code;
  }

  static String? languageCodeFromName(String? name) {
    if (name == null) return null;
    final entry = _languageCodeToName.entries.firstWhere(
      (e) => e.value.toLowerCase() == name.toLowerCase(),
      orElse: () => const MapEntry('', ''),
    );
    return entry.key.isEmpty ? null : entry.key;
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final youtubeUrl = json['videourl'] ?? json['youtubeUrl'] ?? json['url'];
    final youtubeId = extractYoutubeId(youtubeUrl);
    // Language and category (prefer human-readable name when available)
    final String? language =
        json['languageUsed'] ??
        json['languageName'] ??
        json['language_name'] ??
        json['language'] ??
        json['language_code'] ??
        json['lang'];
    final String? category = json['category'] ?? json['cat'] ?? json['type'] ?? json['categoryName'];

    // Try to get title from various possible fields
    String? title = json['title'] ?? 
                    json['name'] ?? 
                    json['videoTitle'] ?? 
                    json['video_title'] ?? 
                    json['videotitle'];
    
    // Ignore backend description – YouTube enrichment will populate it
    String? description;
    

    
    // Only use real data, no generic fallbacks
    if (title == null || title.isEmpty || title == 'YouTube Video') {
      title = null;
    }
    
    // Remove any author information from title and description
    if (title != null && title.isNotEmpty) {
      // Remove trailing 'by <author>' patterns to keep title clean
      title = title.replaceAll(RegExp(r'\s+by\s+[A-Za-z\s]+[.!]?$', caseSensitive: false), '').trim();
    }
    
    // Remove any author information from description (e.g., "By INDIAN DEVOTIONAL SONGS")
    // Note: description is always null at this point, so no processing needed
    
    // If no description found, leave it as null to show "No description available"
    // Note: description is already null at this point
    

    
         // Safe DateTime parsing
     DateTime? createdAt;
     if (json['createddt'] != null) {
       try {
         createdAt = DateTime.parse(json['createddt']);
       } catch (e) {
         createdAt = DateTime.now();
       }
     } else {
       createdAt = DateTime.now();
     }
     
     final video = VideoModel(
       id: json['id'] ?? json['_id'] ?? '',
       youtubeUrl: youtubeUrl,
       youtubeId: youtubeId,
       title: title,
       description: description,
       createdAt: createdAt,
       language: language,
       category: category,
     );
    
    return video;
  }

  // Async factory to fetch YouTube metadata
  static Future<VideoModel> fromJsonWithMetadata(Map<String, dynamic> json) async {
    final youtubeUrl = json['videourl'] ?? json['youtubeUrl'];
    final youtubeId = extractYoutubeId(youtubeUrl);
    
    // First, create a basic video model with original data
     final basicVideo = VideoModel.fromJson(json);
    
    // Try to fetch YouTube metadata if we have a YouTube ID
    Map<String, dynamic>? youtubeMetadata;
    if (youtubeId != null) {
      try {
        youtubeMetadata = await YouTubeService.getVideoInfo(youtubeId);
      } catch (e) {
        // Error fetching YouTube metadata
      }
    }
    
         // Use YouTube metadata if available, otherwise preserve original data
     String? title;
     String? description;
     
     if (youtubeMetadata != null) {
       title = youtubeMetadata['title'];
       description = youtubeMetadata['description'];
     }
     
     // Only use YouTube data if it's valid, otherwise preserve original data
     if (title == null || title.isEmpty || title == 'YouTube Video') {
       title = basicVideo.title; // Preserve original title
     }
     
     // For description, prioritize YouTube data over original data
     // Only fall back to original description if YouTube returns null/empty
     if (description == null || description.isEmpty) {
       description = basicVideo.description; // Fall back to original description
     }
    
    // Remove any author information from title and description
    if (title != null && title.isNotEmpty) {
      // Remove common author patterns from title (case-insensitive and punctuation-safe)
      title = title.replaceAll(RegExp(r'\s+by\s+[A-Za-z\s]+[.!]?$', caseSensitive: false), '').trim();
    }
    
    // Remove any author information from description (e.g., "By INDIAN DEVOTIONAL SONGS")
    if (description != null && description.isNotEmpty) {
      // Remove common author patterns (case-insensitive and punctuation-safe)
      description = description.replaceAll(RegExp(r'by\s+[A-Za-z\s]+[.!]?$', caseSensitive: false), '').trim();
    }
    
    final video = VideoModel(
      id: basicVideo.id,
      youtubeUrl: basicVideo.youtubeUrl,
      youtubeId: basicVideo.youtubeId,
      title: title,
      description: description,
      createdAt: basicVideo.createdAt,
      youtubeMetadata: youtubeMetadata,
      language: basicVideo.language,
      category: basicVideo.category,
    );
    
    return video;
  }

  // Extract YouTube video ID from various URL formats
  static String? extractYoutubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // Handle different YouTube URL formats
    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/v\/([a-zA-Z0-9_-]{11})'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    
    return null;
  }

  // Generate YouTube thumbnail URL
  String? get thumbnailUrl {
    if (youtubeId == null) return null;
    // Prefer high-res with graceful fallback handled by UI consumer
    return 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg';
  }

  // Generate YouTube embed URL
  String? get embedUrl {
    if (youtubeId == null) return null;
    return 'https://www.youtube.com/embed/$youtubeId';
  }

  // Generate YouTube watch URL
  String? get watchUrl {
    if (youtubeId == null) return null;
    return 'https://www.youtube.com/watch?v=$youtubeId';
  }

  // Get title with fallback
  String get displayTitle {
    final finalTitle = title ?? _youtubeMetadata?['title'];
    if (finalTitle != null && finalTitle.isNotEmpty && finalTitle != 'YouTube Video') {
      return finalTitle;
    }
    return 'No title available';
  }

    // Get description with fallback
  String get displayDescription {
    // Show ONLY YouTube API description; sanitize boilerplate lines
    final ytDesc = _youtubeMetadata?['description'];
    if (ytDesc is String && ytDesc.isNotEmpty) {
      final cleaned = _sanitizeYouTubeDescription(ytDesc);
      return cleaned.isNotEmpty ? cleaned : 'No description available';
    }
    return 'No description available';
  }

  static String _sanitizeYouTubeDescription(String raw) {
    String s = raw;
    // Remove common boilerplate headers seen in the channel descriptions
    s = s.replaceFirst(RegExp(r"^Part of 'Vande Guru Paramparaam'\s*-\s*A Spiritual Musical Series\.[\s\S]*?\n+", caseSensitive: false), '');
    s = s.replaceFirst(RegExp(r"^Music\s*-[\s\S]*?\n+", caseSensitive: false), '');
    // Remove repeated social links / lines starting with http/https
    s = s.replaceAll(RegExp(r"https?:\/\/\S+"), '');
    // Collapse multiple blank lines
    s = s.replaceAll(RegExp(r"\n{2,}"), '\n');
    return s.trim();
  }

  // Display helpers for UI
  String? get languageDisplay => languageNameFromCode(language);
  String? get categoryDisplay {
    if (category == null || category!.isEmpty) return category;
    return category;
  }

  // Get duration from YouTube metadata
  String get formattedDuration {
    if (_youtubeMetadata?['duration'] != null) {
      return YouTubeService.formatDuration(_youtubeMetadata!['duration']);
    }
    return '00:00';
  }

  // Get views from YouTube metadata
  String get formattedViews {
    if (_youtubeMetadata?['viewCount'] != null) {
      return YouTubeService.formatViewCount(_youtubeMetadata!['viewCount'].toString());
    }
    return '0';
  }

  // Get channel title from YouTube metadata
  String? get channelTitle {
    return _youtubeMetadata?['channelTitle'];
  }

  // Get published date from YouTube metadata
  String? get publishedAt {
    return _youtubeMetadata?['publishedAt'];
  }
  
  // Get YouTube metadata for debugging
  Map<String, dynamic>? get youtubeMetadata {
    return _youtubeMetadata;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'youtubeUrl': youtubeUrl,
      'youtubeId': youtubeId,
      'title': title,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'youtubeMetadata': _youtubeMetadata,
      'language': language,
      'category': category,
    };
  }
} 