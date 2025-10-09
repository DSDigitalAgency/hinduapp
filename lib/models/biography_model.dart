class BiographyModel {
  final String id;
  final String? biographyId;
  final String? title;
  final String? name;
  final String? content;
  final String? body;
  final String? description;
  final String? excerpt;
  final String? era;
  final String? author;
  final String? authorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? additionalData;

  const BiographyModel({
    required this.id,
    this.biographyId,
    this.title,
    this.name,
    this.content,
    this.body,
    this.description,
    this.excerpt,
    this.era,
    this.author,
    this.authorName,
    this.createdAt,
    this.updatedAt,
    this.additionalData,
  });

  factory BiographyModel.fromJson(Map<String, dynamic> json) {
    return BiographyModel(
      id: json['_id'] ?? json['id'] ?? json['biographyId'] ?? '',
      biographyId: json['biographyId'],
      title: json['title'],
      name: json['name'],
      content: json['content'],
      body: json['body'],
      description: json['description'],
      excerpt: json['excerpt'],
      era: json['era'],
      author: json['author'],
      authorName: json['authorName'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : json['createddt'] != null 
              ? DateTime.tryParse(json['createddt'])
              : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : json['updateddt'] != null 
              ? DateTime.tryParse(json['updateddt'])
              : null,
      additionalData: json,
    );
  }

  // Get the primary title (prefer name over title)
  String get displayTitle {
    return name ?? title ?? 'Unknown Person';
  }

  // Get the primary content (prefer content over body over description over excerpt)
  String get displayContent {
    return content ?? body ?? description ?? excerpt ?? 'No content available for this biography.';
  }

  // Get the author name
  String? get displayAuthor {
    return author ?? authorName;
  }

  // Check if this biography has content
  bool get hasContent {
    return (content?.isNotEmpty ?? false) || 
           (body?.isNotEmpty ?? false) || 
           (description?.isNotEmpty ?? false);
  }

  // Get a preview of the content (first 100 characters)
  String get contentPreview {
    final content = displayContent;
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  // Convert to Map for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'biographyId': biographyId,
      'title': title,
      'name': name,
      'content': content,
      'body': body,
      'description': description,
      'excerpt': excerpt,
      'era': era,
      'author': author,
      'authorName': authorName,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  BiographyModel copyWith({
    String? id,
    String? title,
    String? name,
    String? content,
    String? body,
    String? description,
    String? era,
    String? author,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return BiographyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      name: name ?? this.name,
      content: content ?? this.content,
      body: body ?? this.body,
      description: description ?? this.description,
      era: era ?? this.era,
      author: author ?? this.author,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'BiographyModel(id: $id, title: $displayTitle, hasContent: $hasContent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BiographyModel &&
        other.id == id &&
        other.title == title &&
        other.name == name &&
        other.content == content &&
        other.body == body &&
        other.description == description &&
        other.era == era &&
        other.author == author &&
        other.authorName == authorName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        name.hashCode ^
        content.hashCode ^
        body.hashCode ^
        description.hashCode ^
        era.hashCode ^
        author.hashCode ^
        authorName.hashCode;
  }
} 