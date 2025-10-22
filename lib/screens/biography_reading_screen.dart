import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/favorites_service.dart';
import '../services/cache_service.dart';
import '../services/markdown_service.dart';
import '../services/local_storage_service.dart';
import '../models/biography_model.dart';
import '../widgets/reading_settings_widget.dart';
import '../providers/reading_settings_provider.dart';
import '../constants/app_theme.dart';

class BiographyReadingScreen extends ConsumerStatefulWidget {
  final String title;
  final String? content;
  final String? biographyId; // Add biographyId parameter

  const BiographyReadingScreen({
    super.key,
    required this.title,
    this.content,
    this.biographyId, // Add biographyId parameter
  });

  @override
  ConsumerState<BiographyReadingScreen> createState() => _BiographyReadingScreenState();
}

class _BiographyReadingScreenState extends ConsumerState<BiographyReadingScreen> with AutomaticKeepAliveClientMixin {
  final FavoritesService _favoritesService = FavoritesService();
  final CacheService _cacheService = CacheService();
  
  BiographyModel? _biography;
  bool _isFavorite = false;
  bool _isLoading = true;
  String? _error;
  
  // Reading settings - now managed by global provider
  
  // User's preferred language for custom fonts
  String? _userPreferredLanguage;
  
  // Cache for processed content to prevent reprocessing
  String? _processedContent;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserLanguagePreference();
    _loadBiography();
    // Reading settings handled by global provider
  }

  Future<void> _loadUserLanguagePreference() async {
    try {
      _userPreferredLanguage = await LocalStorageService.getUserPreferredLanguage();
    } catch (e) {
      // Use default language if loading fails
      _userPreferredLanguage = 'Devanagari';
    }
  }

  Future<void> _loadBiography() async {
    try {
      BiographyModel? biography;
      
      // Priority 1: If biographyId is provided, fetch complete biography by ID
      if (widget.biographyId != null && widget.biographyId!.isNotEmpty) {
        try {
          final biographyData = await _cacheService.getBiographyByIdWithCache(widget.biographyId!);
          biography = BiographyModel.fromJson(biographyData);
        } catch (e) {
          // Fall back to other methods
        }
      }
      
      // Priority 2: If no biography loaded by ID, try direct content
      if (biography == null && widget.content != null && widget.content!.isNotEmpty) {
        biography = BiographyModel(
          id: widget.title,
          title: widget.title,
          content: widget.content,
        );
      }
      
      // Priority 3: If still no biography, try to load by title
      if (biography == null) {
        try {
          final biographyData = await _cacheService.getBiographyWithCache(widget.title);
          biography = BiographyModel.fromJson(biographyData);
        } catch (e) {
          // Create a placeholder biography
          biography = BiographyModel(
            id: widget.title,
            title: widget.title,
            content: 'Content for ${widget.title} is not available. Please try again later.',
          );
        }
      }

      if (mounted) {
        // Process content immediately
        final processedContent = _processContent(biography.displayContent);
        
        setState(() {
          _biography = biography;
          _processedContent = processedContent;
          _isLoading = false;
        });
        
        // Check favorite status
        _checkFavoriteStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load biography: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _processContent(String content) {
    if (content.isEmpty) return 'No content available';
    
    // Use the centralized markdown service for consistent processing
    return MarkdownService.prepareMarkdownForRendering(content);
  }

  Future<void> _checkFavoriteStatus() async {
    if (_biography == null) return;
    
    try {
      final isFavorite = await _favoritesService.isFavorited(_biography!.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      // Silently handle error
    }
  }
  

  Future<void> _toggleFavorite() async {
    if (_biography == null) return;
    
    try {
      if (_isFavorite) {
        await _favoritesService.removeFromFavorites(_biography!.id);
      } else {
        await _favoritesService.addToFavorites(
          itemId: _biography!.id,
          itemType: 'biography',
          title: _biography!.displayTitle,
          description: _biography!.contentPreview,
        );
      }
      
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isFavorite ? 'remove from' : 'add to'} favorites'),
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

  Future<void> _shareContent() async {
    if (_biography == null) return;

    final shareText =
        '''
${_biography!.displayContent.substring(0, _biography!.displayContent.length > 200 ? 200 : _biography!.displayContent.length)}...

Read more in Hindu Connect App:
https://play.google.com/store/apps/details?id=com.dikonda.hinduconnect
''';

    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final readingSettings = ref.watch(readingSettingsProvider);
    
    return Scaffold(
      key: ValueKey('scaffold_${readingSettings.backgroundColor.toARGB32()}'),
      backgroundColor: readingSettings.backgroundColor,
      appBar: AppBar(
        title: Text(
          _biography?.displayTitle ?? widget.title,
          style: const TextStyle(
            fontSize: 18,
            color: AppTheme.creamColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Favorite button
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
          ),
          // Share button
          IconButton(
            onPressed: _isLoading ? null : _shareContent,
            icon: Icon(
              Icons.share,
              color: _isLoading ? Colors.grey : Colors.white,
            ),
          ),
        ],
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
      body: _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBiography,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12.0, 20.0, 12.0, 80.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingL),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _biography?.displayTitle ?? widget.title,
                                    style: TextStyle(
                                      fontSize: readingSettings.textSize + 2,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                      height: readingSettings.textSpacing,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingS,
                                      vertical: AppTheme.spacingXS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                                    ),
                                    child: const Text(
                                      'Biography',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXXL),
                      
                      // Content with loading indicator if needed
                      _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                ),
                              ),
                            )
                          : _processedContent != null
                              ? Consumer(
                                  builder: (context, ref, child) {
                                    final readingSettings = ref.watch(readingSettingsProvider);
                                    return Markdown(
                                      key: ValueKey('biography_markdown_${readingSettings.textSize}_${readingSettings.backgroundColor.toARGB32()}_${readingSettings.textSpacing}'),
                                      data: _processedContent!,
                                      styleSheet: MarkdownService.createMarkdownStyleSheet(
                                        baseFontSize: readingSettings.textSize,
                                        textColor: ReadingSettingsWidget.getTextColor(readingSettings.backgroundColor),
                                        lineHeight: readingSettings.textSpacing,
                                        currentLanguage: _userPreferredLanguage,
                                      ),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text(
                                      'No content available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                      
                    ],
                  ),
                ),
    );
  }
} 