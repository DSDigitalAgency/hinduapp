import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screen_protector/screen_protector.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/markdown_service.dart';
import '../services/deep_link_service.dart';
import '../constants/app_theme.dart';
import '../providers/reading_settings_provider.dart';
import '../widgets/reading_settings_widget.dart';

class PostReaderScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const PostReaderScreen({super.key, required this.post});

  @override
  ConsumerState<PostReaderScreen> createState() => _PostReaderScreenState();
}

class _PostReaderScreenState extends ConsumerState<PostReaderScreen>
    with AutomaticKeepAliveClientMixin {
  final FavoritesService _favoritesService = FavoritesService();

  bool _isFavorite = false;

  // Reading settings - now managed by global provider

  // Cache for processed content to prevent reprocessing
  String? _processedContent;

  // Loading state for content fetching
  bool _isLoadingContent = true;

  // User's preferred language for custom fonts
  String? _userPreferredLanguage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Enable screen protection
      await ScreenProtector.protectDataLeakageOn();
      
      _checkFavoriteStatus();
      _loadUserLanguagePreference();
      _fetchFullContent();
    } catch (e) {
      // Error in _init: $e
    }
  }

  @override
  void dispose() {
    // Disable screen protection when leaving the screen
    ScreenProtector.protectDataLeakageOff();
    super.dispose();
  }

  // Fetch full content for the post with optimized loading
  Future<void> _fetchFullContent() async {
    try {
      setState(() {
        _isLoadingContent = true;
      });

      // First, try to use existing content if available
      if (widget.post.content.body.isNotEmpty) {
        setState(() {
          _processedContent = _processContent(widget.post.content.body);
          _isLoadingContent = false;
        });
      }

      // Then try to fetch full content from API
      final apiService = ApiService();
      final response = await apiService.getPostById(postId: widget.post.postId);

      if (response.containsKey('content') && response['content'] is Map) {
        final content = response['content'] as Map<String, dynamic>;
        if (content.containsKey('body')) {
          final fullBody = content['body'] as String;
          if (fullBody.isNotEmpty && mounted) {
            setState(() {
              _processedContent = _processContent(fullBody);
              _isLoadingContent = false;
            });
          }
        }
      } else {
        // If API doesn't return content in expected format, check if response itself has the data
        if (response.containsKey('body')) {
          final fullBody = response['body'] as String;
          if (fullBody.isNotEmpty && mounted) {
            setState(() {
              _processedContent = _processContent(fullBody);
              _isLoadingContent = false;
            });
          }
        } else if (response.containsKey('data')) {
          final data = response['data'];
          if (data is Map<String, dynamic>) {
            final fullBody =
                (data['content']?['body'] ?? data['body'] ?? '') as String;
            if (fullBody.isNotEmpty && mounted) {
              setState(() {
                _processedContent = _processContent(fullBody);
                _isLoadingContent = false;
              });
            }
          }
        }
      }
    } catch (e) {
      // Ensure we always have content to display and stop loading
      if (mounted) {
        setState(() {
          if (_processedContent == null || _processedContent!.isEmpty) {
            String fallbackContent = widget.post.content.body;
            if (fallbackContent.isEmpty) {
              fallbackContent = 'Content not available for this post.';
            }
            _processedContent = _processContent(fallbackContent);
          }
          _isLoadingContent = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorited = await _favoritesService.isFavorited(widget.post.id);
      setState(() {
        _isFavorite = isFavorited;
      });
    } catch (e) {
      // Error checking favorite status
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final isFavorited = await _favoritesService.isFavorited(widget.post.id);

      if (isFavorited) {
        await _favoritesService.removeFromFavorites(widget.post.id);
        setState(() {
          _isFavorite = false;
        });
      } else {
        await _favoritesService.addToFavorites(
          itemId: widget.post.id,
          itemType: 'post',
          title: widget.post.basicInfo.title,
          description: widget.post.content.body,
          imageUrl: '',
        );
        setState(() {
          _isFavorite = true;
        });
      }

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Error toggling favorite
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load user language preference
  Future<void> _loadUserLanguagePreference() async {
    setState(() {
      _userPreferredLanguage = widget.post.content.language;
    });
  }

  // Get content for post sharing
  String _getPostContent() {
    String content = '';
    if (_processedContent != null && _processedContent!.isNotEmpty) {
      content = _processedContent!;
    } else if (widget.post.content.body.isNotEmpty) {
      content = widget.post.content.body;
    } else {
      content = 'Post content';
    }

    // Use prepareMarkdownForRendering to preserve formatting for display
    return MarkdownService.prepareMarkdownForRendering(content);
  }

  Future<void> _sharePost() async {
    try {
      // Get the actual content that's being displayed
      String contentToShare = '';

      if (_processedContent != null && _processedContent!.isNotEmpty) {
        // Use the processed content that's actually displayed
        contentToShare = _processedContent!;
      } else if (widget.post.content.body.isNotEmpty) {
        // Fallback to original post content
        contentToShare = widget.post.content.body;
      } else {
        contentToShare = 'Read this post in Hindu Connect App';
      }

      // Create preview for sharing (first 200 characters)
      String sharePreview = contentToShare;
      if (sharePreview.length > 200) {
        sharePreview = '${sharePreview.substring(0, 200)}...';
      }

      final shareText = DeepLinkService.generateShareText(
        preview: sharePreview,
        type: 'post',
        id: widget.post.postId,
        title: widget.post.basicInfo.title,
      );
      
      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (e) {
      // Error sharing post
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReadingSettings() {
    final readingSettingsNotifier = ref.read(readingSettingsProvider.notifier);
    final currentSettings = ref.read(readingSettingsProvider);
    
    ReadingSettingsWidget.showReadingSettings(
      context: context,
      textSize: currentSettings.textSize,
      backgroundColor: currentSettings.backgroundColor,
      textSpacing: currentSettings.textSpacing,
      onTextSizeChanged: (value) {
        readingSettingsNotifier.updateTextSize(value);
      },
      onBackgroundColorChanged: (value) {
        readingSettingsNotifier.updateBackgroundColor(value);
      },
      onTextSpacingChanged: (value) {
        readingSettingsNotifier.updateTextSpacing(value);
      },
    );
  }

  // Process content for display
  String _processContent(String content) {
    return MarkdownService.prepareMarkdownForRendering(content);
  }

  // Reading settings are now managed by global provider

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final readingSettings = ref.watch(readingSettingsProvider);
    final currentLanguage = widget.post.content.language;
    
    return Scaffold(
      key: ValueKey('scaffold_${readingSettings.backgroundColor.toARGB32()}'),
      backgroundColor: readingSettings.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.post.basicInfo.title.isNotEmpty
              ? widget.post.basicInfo.title
              : 'Post',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
          ),
          IconButton(
            onPressed: _isLoadingContent ? null : _sharePost,
            icon: Icon(
              Icons.share,
              color: _isLoadingContent ? Colors.grey : Colors.white,
            ),
          ),
        ],
      ),
      body: _isLoadingContent
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 80.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_userPreferredLanguage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _userPreferredLanguage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                          height: 1.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  Consumer(
                    builder: (context, ref, child) {
                      final readingSettings = ref.watch(readingSettingsProvider);
                      return MarkdownBody(
                        key: ValueKey('post_markdown_${readingSettings.textSize}_${readingSettings.backgroundColor.toARGB32()}_${readingSettings.textSpacing}'),
                        data: _getPostContent(),
                        styleSheet: MarkdownService.createMarkdownStyleSheet(
                          baseFontSize: readingSettings.textSize,
                          textColor: ReadingSettingsWidget.getTextColor(readingSettings.backgroundColor),
                          lineHeight: readingSettings.textSpacing,
                          currentLanguage: currentLanguage,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showReadingSettings,
        backgroundColor: AppTheme.primaryColor,
        child: const Text(
          'AA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}