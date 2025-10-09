class PostModel {
  final String id;
  final String postId;
  final BasicInfo basicInfo;
  final Author author;
  final Content content;
  final DateTime createddt;
  final DateTime updateddt;

  const PostModel({
    required this.id,
    required this.postId,
    required this.basicInfo,
    required this.author,
    required this.content,
    required this.createddt,
    required this.updateddt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Handle both nested and flat API response structures
    Map<String, dynamic> basicInfoData;
    Map<String, dynamic> authorData;
    Map<String, dynamic> contentData;
    
    // Check if the response has nested structure or flat structure
    if (json.containsKey('basicInfo')) {
      // Nested structure
      basicInfoData = json['basicInfo'] ?? {};
      authorData = json['author'] ?? {};
      contentData = json['content'] ?? {};
    } else {
      // Flat structure (from API response)
      basicInfoData = {
        'title': json['title'] ?? '',
        'slug': json['slug'] ?? '',
        'status': json['status'] ?? 'published',
        'category': json['category'] ?? '',
      };
      authorData = {
        'authorName': json['authorName'] ?? '',
      };
      contentData = {
        'body': json['content']?['body'] ?? json['body'] ?? '',
        'language': json['availableLanguages']?.first ?? 'English',
      };
    }
    
    // Ensure we always have a stable, non-empty ID to avoid UI dedup collapsing to a single item
    final computedId = (json['_id'] ?? json['postId'] ?? json['blogId'] ?? json['id'] ?? json['slug'] ??
      '${(json['title'] ?? '').toString()}-${(json['publishedAt'] ?? json['createddt'] ?? '').toString()}'
    ).toString();

    return PostModel(
      id: computedId,
      postId: (json['postId'] ?? json['blogId'] ?? computedId).toString(),
      basicInfo: BasicInfo.fromJson(basicInfoData),
      author: Author.fromJson(authorData),
      content: Content.fromJson(contentData),
      createddt: DateTime.tryParse(json['publishedAt'] ?? json['createddt'] ?? '') ?? DateTime.now(),
      updateddt: DateTime.tryParse(json['updateddt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'postId': postId,
      'basicInfo': basicInfo.toJson(),
      'author': author.toJson(),
      'content': content.toJson(),
      'createddt': createddt.toIso8601String(),
      'updateddt': updateddt.toIso8601String(),
    };
  }

  PostModel copyWith({
    String? id,
    String? postId,
    BasicInfo? basicInfo,
    Author? author,
    Content? content,
    DateTime? createddt,
    DateTime? updateddt,
  }) {
    return PostModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      basicInfo: basicInfo ?? this.basicInfo,
      author: author ?? this.author,
      content: content ?? this.content,
      createddt: createddt ?? this.createddt,
      updateddt: updateddt ?? this.updateddt,
    );
  }
}

class BasicInfo {
  final String title;
  final String slug;
  final String status;
  final String category;

  const BasicInfo({
    required this.title,
    required this.slug,
    required this.status,
    required this.category,
  });

  factory BasicInfo.fromJson(Map<String, dynamic> json) {
    return BasicInfo(
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      status: json['status'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'status': status,
      'category': category,
    };
  }
}

class Author {
  final String authorName;

  const Author({
    required this.authorName,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      authorName: json['authorName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorName': authorName,
    };
  }
}

class Content {
  final String body;
  final String language;
  final bool isLoading;

  const Content({
    required this.body,
    required this.language,
    this.isLoading = false,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      body: json['body'] ?? '',
      language: json['language'] ?? '',
      isLoading: json['isLoading'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'body': body,
      'language': language,
      'isLoading': isLoading,
    };
  }

  Content copyWith({
    String? body,
    String? language,
    bool? isLoading,
  }) {
    return Content(
      body: body ?? this.body,
      language: language ?? this.language,
      isLoading: isLoading ?? this.isLoading,
    );
  }
} 