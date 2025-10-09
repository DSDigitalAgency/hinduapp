import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/local_storage_service.dart';
import '../services/favorites_service.dart';
import '../services/cache_service.dart';
import '../services/markdown_service.dart';
import '../models/temple_model.dart';
import '../widgets/reading_settings_widget.dart';
import '../providers/reading_settings_provider.dart';
import '../constants/app_theme.dart';

class TempleReadingScreen extends ConsumerStatefulWidget {
  final String templeId;
  final Map<String, dynamic>? temple; // Optional for backward compatibility

  const TempleReadingScreen({
    super.key,
    required this.templeId,
    this.temple,
  });

  @override
  ConsumerState<TempleReadingScreen> createState() => _TempleReadingScreenState();
}

class _TempleReadingScreenState extends ConsumerState<TempleReadingScreen> with AutomaticKeepAliveClientMixin {
  // Removed unused ApiService instance
  final FavoritesService _favoritesService = FavoritesService();
  final CacheService _cacheService = CacheService();
  final ScrollController _scrollController = ScrollController();
  
  TempleModel? _templeModel;
  TempleModel? _detailedTempleModel;
  bool _isLoading = true;
  bool _isFavorite = false;
  
  // Reading settings - now managed by global provider
  
  // User's preferred language for custom fonts
  String? _userPreferredLanguage;
  
  // Cache for processed content to prevent reprocessing
  String? _processedContent;
  
  String _processContent(String content) {
    if (content.isEmpty) return 'No content available';
    
    // Use the centralized markdown service for consistent processing
    return MarkdownService.prepareMarkdownForRendering(content);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.temple != null) {
      _templeModel = TempleModel.fromJson(widget.temple!);
    }
    _loadUserLanguagePreference();
    _loadDetailedTemple();
    _checkFavoriteStatus();
    // Reading settings handled by global provider
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLanguagePreference() async {
    try {
      _userPreferredLanguage = await LocalStorageService.getUserPreferredLanguage();
    } catch (e) {
      // Use default language if loading fails
      _userPreferredLanguage = 'Devanagari';
    }
  }

  Future<void> _loadDetailedTemple() async {
    try {
      final response = await _cacheService.getTempleWithCache(widget.templeId);
      
      if (!mounted) return;
      
      if (response['_id'] != null || response['templeId'] != null || response['title'] != null) {
        // Combine all state changes into a single setState call
        setState(() {
          _detailedTempleModel = TempleModel.fromJson(response);
          _processedContent = _processContent(_getTempleContent());
          _isLoading = false;
        });
        
        // Update the cache timestamp to reflect last access time
        await _cacheService.updateTempleAccessTime(widget.templeId);

        // Save to recently viewed
        final t = _detailedTempleModel!;
        await LocalStorageService.addToRecentlyViewed({
          'id': t.templeId ?? widget.templeId,
          'templeId': t.templeId ?? widget.templeId,
          'title': t.displayTitle,
          'excerpt': t.fullContent,
          'category': t.category ?? '',
          'type': 'temple',
          'viewed_at': DateTime.now().toIso8601String(),
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTempleTitle() {
    return _detailedTempleModel?.displayTitle ?? 
           _templeModel?.displayTitle ?? 
           widget.temple?['title'] ?? 
           'Unknown Temple';
  }

  String _getTempleContent() {
    String content = _detailedTempleModel?.fullContent ?? 
                    _templeModel?.fullContent ?? 
                    widget.temple?['text'] ?? 
                    widget.temple?['excerpt'] ?? 
                    'No content available for this temple.';
    
    // Process content once and cache it
    _processedContent ??= _processContent(content);
    
    return _processedContent!;
  }

  String _getTempleCategory() {
    return _detailedTempleModel?.categoryDisplay ?? 
           _templeModel?.categoryDisplay ?? 
           widget.temple?['category'] ?? 
           '';
  }

  List<String> _getTempleHighlights() {
    return _detailedTempleModel?.displayHighlights ?? 
           _templeModel?.displayHighlights ?? 
           [];
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

  Future<void> _checkFavoriteStatus() async {
    final templeId = _detailedTempleModel?.templeId ?? 
                     _templeModel?.templeId ?? 
                     widget.temple?['templeId'] ?? 
                     widget.templeId;
    
    if (templeId.isNotEmpty) {
      final isFav = await _favoritesService.isFavorited(templeId);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final templeId = _detailedTempleModel?.templeId ?? 
                    _templeModel?.templeId ?? 
                    widget.temple?['templeId'] ?? 
                    widget.templeId;
    
    if (templeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to add to favorites'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _favoritesService.toggleFavorite(
        itemId: templeId,
        itemType: 'temple',
        title: _getTempleTitle(),
        description: '${_getTempleContent().substring(0, 100)}...',
      );
      
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
            backgroundColor: _isFavorite ? Colors.green : Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareTemple() async {
    final templeId = _detailedTempleModel?.templeId ?? 
                     _templeModel?.templeId ?? 
                     widget.temple?['templeId'] ?? 
                     'unknown';
    
    final shareText = '''
${_getTempleTitle()}

${_getTempleContent().substring(0, _getTempleContent().length > 200 ? 200 : _getTempleContent().length)}...

Read more in Hindu Connect App:
hinduconnect://temple/$templeId

Download Hindu Connect:
www.hinduconnect.app
''';

    // FIXED: Correctly call the share method
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
          _getTempleTitle(),
          style: const TextStyle(fontSize: 18),
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
            onPressed: _isLoading ? null : _shareTemple,
            icon: Icon(
              Icons.share,
              color: _isLoading ? Colors.grey : Colors.white,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
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
                            Icons.temple_hindu,
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
                                _getTempleTitle(),
                                style: TextStyle(
                                  fontSize: readingSettings.textSize + 2,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              if (_getTempleCategory().isNotEmpty) ...[
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
                                  child: Text(
                                    _getTempleCategory(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXXL),
                  
                  // Content with Markdown rendering
                  if (_processedContent != null)
                    Markdown(
                      key: ValueKey('temple_markdown_${readingSettings.textSize}_${readingSettings.backgroundColor.toARGB32()}_${readingSettings.textSpacing}'),
                      data: _processedContent!,
                      styleSheet: MarkdownService.createMarkdownStyleSheet(
                        baseFontSize: readingSettings.textSize,
                        textColor: ReadingSettingsWidget.getTextColor(readingSettings.backgroundColor),
                        lineHeight: readingSettings.textSpacing,
                        currentLanguage: _userPreferredLanguage,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    ),
                  
                  // Highlights section
                  if (_getTempleHighlights().isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingXXL),
                    Text(
                      key: ValueKey('temple_highlights_title_${readingSettings.textSize}_${readingSettings.backgroundColor.toARGB32()}_${readingSettings.textSpacing}'),
                      'Highlights:',
                      style: TextStyle(
                        fontSize: readingSettings.textSize + 2,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Markdown(
                      key: ValueKey('temple_highlights_markdown_${readingSettings.textSize}_${readingSettings.backgroundColor.toARGB32()}_${readingSettings.textSpacing}'),
                      data: _getTempleHighlights().map((highlight) => '• $highlight').join('\n'),
                      styleSheet: MarkdownService.createMarkdownStyleSheet(
                        baseFontSize: readingSettings.textSize,
                        textColor: ReadingSettingsWidget.getTextColor(readingSettings.backgroundColor),
                        lineHeight: readingSettings.textSpacing,
                        currentLanguage: _userPreferredLanguage,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    ),
                  ],
                  
                  const SizedBox(height: AppTheme.spacingXXXL),
                  
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
    );
  }
} 