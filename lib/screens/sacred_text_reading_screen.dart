import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screen_protector/screen_protector.dart';
import 'dart:math' as math;
import 'package:hindu_connect/models/sacred_text_model.dart';
import 'package:hindu_connect/services/favorites_service.dart';
import 'package:hindu_connect/services/cache_service.dart';
import 'package:hindu_connect/services/language_conversion_service.dart';
import 'package:hindu_connect/services/local_storage_service.dart';
import 'package:hindu_connect/services/font_service.dart';
import 'package:hindu_connect/services/markdown_service.dart';
import 'package:hindu_connect/services/api_service.dart';
import 'package:hindu_connect/services/logger_service.dart';
import 'package:hindu_connect/providers/language_provider.dart';
import 'package:hindu_connect/providers/reading_settings_provider.dart';
import 'package:hindu_connect/constants/app_theme.dart';
import 'package:hindu_connect/widgets/reading_settings_widget.dart';

class SacredTextReadingScreen extends ConsumerStatefulWidget {
  final String sacredTextId;
  final Map<String, dynamic>? sacredText;

  const SacredTextReadingScreen({
    super.key,
    required this.sacredTextId,
    this.sacredText,
  });

  @override
  ConsumerState<SacredTextReadingScreen> createState() =>
      _SacredTextReadingScreenState();
}

class _SacredTextReadingScreenState
    extends ConsumerState<SacredTextReadingScreen> with AutomaticKeepAliveClientMixin {
  
  // Services
  final FavoritesService _favoritesService = FavoritesService();
  final CacheService _cacheService = CacheService();
  final LanguageConversionService _conversionService = LanguageConversionService();
  final ScrollController _scrollController = ScrollController();

  // Languages that have content available directly from API (no conversion needed)
  static const Set<String> _availableLanguages = {
    'Devanagari (Hindi)',
    'Roman itrans (English)',
    'Malayalam',
    'Tamil',
    'Telugu',
    'Kannada',
  };

  // Helper method to check if language has direct content available
  bool _hasDirectContent(String language) {
    return _availableLanguages.contains(language);
  }

  // State variables
  SacredTextModel? _sacredTextModel;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _userPreferredLanguage;
  String? _convertedContent;
  
  // Reading settings - now managed by global provider

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    // Disable screen protection when leaving the screen
    ScreenProtector.protectDataLeakageOff();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      // Enable screen protection
      await ScreenProtector.protectDataLeakageOn();
      
      // Reading settings are now handled by the global provider
      
      // Check favorite status
      await _checkFavoriteStatus();
      
      // Load sacred text data
      await _loadSacredTextData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error in _init: $e
      if (mounted) {
      setState(() {
        _isLoading = false;
      });
      }
    }
  }

  Future<void> _loadSacredTextData() async {
    try {
      // Get user's preferred language
      final currentLanguage = ref.read(languageProvider);
      _userPreferredLanguage = currentLanguage;
      final languageCode = LocalStorageService.getLanguageCodeFromName(_userPreferredLanguage);

      
      // Try to get from widget.sacredText first (from search screen)
      if (widget.sacredText != null) {

        _sacredTextModel = SacredTextModel.fromJson(widget.sacredText!);
        
        // Always check if we need to fetch full content
        bool needsFullContent = false;
        
        // Check if we only have excerpt or if text field is empty
        if (_sacredTextModel!.text == null || 
            _sacredTextModel!.text!.isEmpty || 
            _sacredTextModel!.text!.length < 500) { // If content is too short, likely just excerpt
          needsFullContent = true;

        }
        
        if (needsFullContent) {
          // Fetch full content from API with language parameter
          final apiService = ApiService();
          final sacredTextData = await apiService.getSacredTextById(widget.sacredTextId, language: languageCode);
          _sacredTextModel = SacredTextModel.fromJson(sacredTextData);
          
          // Cache the data
          await _cacheService.cacheSacredText(widget.sacredTextId, sacredTextData);
        }
        
        // Convert the content (whether original or fetched) only if needed
        if (_sacredTextModel!.text != null && _sacredTextModel!.text!.isNotEmpty) {



          
      // Skip conversion if language has direct content available from API
      if (_userPreferredLanguage != null && _hasDirectContent(_userPreferredLanguage!)) {
        logger.debug('🔍 Sacred Text Reading: Using initial direct content for $_userPreferredLanguage');
        logger.debug('🔍 Sacred Text Reading: Content preview: ${_sacredTextModel!.text!.substring(0, math.min(100, _sacredTextModel!.text!.length))}');
        _convertedContent = _sacredTextModel!.text!;
      } else {
        logger.debug('🔍 Sacred Text Reading: Converting initial content to $_userPreferredLanguage');
        // Only convert if needed
        final converted = await _conversionService.convertSacredTextContent(
          sacredTextId: widget.sacredTextId,
          userLanguage: _userPreferredLanguage ?? 'Devanagari',
          originalContent: _sacredTextModel!.text!,
        );
        _convertedContent = converted;
      }

        } else {

        }
        return;
      }
      
      // Try cache first
      final cachedData = await _cacheService.getCachedSacredText(widget.sacredTextId);
      if (cachedData != null) {
        _sacredTextModel = SacredTextModel.fromJson(cachedData);
        
        // Convert if needed
        if (_sacredTextModel!.text != null && _sacredTextModel!.text!.isNotEmpty) {
          // Skip conversion if language has direct content available from API
          if (_userPreferredLanguage != null && _hasDirectContent(_userPreferredLanguage!)) {
            logger.debug('🔍 Sacred Text Reading: Using cached direct content for $_userPreferredLanguage');
            _convertedContent = _sacredTextModel!.text!;
          } else {
            logger.debug('🔍 Sacred Text Reading: Converting cached content to $_userPreferredLanguage');
            final converted = await _conversionService.convertSacredTextContent(
              sacredTextId: widget.sacredTextId,
              userLanguage: _userPreferredLanguage ?? 'Devanagari',
              originalContent: _sacredTextModel!.text!,
            );
            _convertedContent = converted;
          }
        }
        return;
      }
    } catch (e) {
      // Handle error silently - will try API call
    }
      
    // Fetch from API as last resort  
    try {
      final languageCode = LocalStorageService.getLanguageCodeFromName(_userPreferredLanguage);
      logger.debug('🔍 Sacred Text Reading: Requesting content with language: $_userPreferredLanguage (code: $languageCode)');
      final apiService = ApiService();
      final sacredTextData = await apiService.getSacredTextById(widget.sacredTextId, language: languageCode);
      _sacredTextModel = SacredTextModel.fromJson(sacredTextData);
      
      logger.debug('🔍 Sacred Text Reading: API returned content length: ${_sacredTextModel!.text?.length ?? 0}');
      
      // If no content and we requested direct language, try Devanagari as fallback
      if ((_sacredTextModel!.text == null || _sacredTextModel!.text!.isEmpty) && 
          _userPreferredLanguage != null && _hasDirectContent(_userPreferredLanguage!)) {
        logger.debug('🔍 Sacred Text Reading: No direct content, trying Devanagari fallback');
        
        try {
          final fallbackData = await apiService.getSacredTextById(widget.sacredTextId, language: 'hi');
          final fallbackModel = SacredTextModel.fromJson(fallbackData);
          
          if (fallbackModel.text != null && fallbackModel.text!.isNotEmpty) {
            logger.debug('🔍 Sacred Text Reading: Fallback found Devanagari content, showing directly without conversion');
            _sacredTextModel = fallbackModel;
            // For direct content languages, show Devanagari directly instead of converting
            _convertedContent = _sacredTextModel!.text!;
            
            // Cache the fallback data
            await _cacheService.cacheSacredText(widget.sacredTextId, fallbackData);
            return;
          }
        } catch (e) {
          logger.debug('🔍 Sacred Text Reading: Fallback also failed: $e');
        }
      }
      
      // Cache the data
      await _cacheService.cacheSacredText(widget.sacredTextId, sacredTextData);
      
      // Convert if needed
      if (_sacredTextModel!.text != null && _sacredTextModel!.text!.isNotEmpty) {
      // Skip conversion if language has direct content available from API
      if (_userPreferredLanguage != null && _hasDirectContent(_userPreferredLanguage!)) {
        logger.debug('🔍 Sacred Text Reading: Using direct content for $_userPreferredLanguage');
        logger.debug('🔍 Sacred Text Reading: API content preview: ${_sacredTextModel!.text!.substring(0, math.min(100, _sacredTextModel!.text!.length))}');
        _convertedContent = _sacredTextModel!.text!;
      } else {
        logger.debug('🔍 Sacred Text Reading: Converting content to $_userPreferredLanguage');
        final converted = await _conversionService.convertSacredTextContent(
          sacredTextId: widget.sacredTextId,
          userLanguage: _userPreferredLanguage ?? 'Devanagari',
          originalContent: _sacredTextModel!.text!,
        );
        _convertedContent = converted;
      }
        }
    } catch (e) {
      // Handle error silently - API call failed
    }
  }


  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorite = await _favoritesService.isFavorited(widget.sacredTextId);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      // Handle error silently - favorite status will remain unchanged
    }
  }


  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _favoritesService.removeFromFavorites(widget.sacredTextId);
      } else {
        await _favoritesService.addToFavorites(
          itemId: widget.sacredTextId,
        itemType: 'sacredText',
        title: _getSacredTextTitle(),
          description: _getSacredTextContent(),
      );
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      // Handle error silently - favorite status will remain unchanged
    }
  }

  Future<void> _shareContent() async {
    try {
      final content = _getSacredTextContent();
      
      // Create preview for sharing (first 200 characters)
      String sharePreview = content;
      if (sharePreview.length > 200) {
        sharePreview = '${sharePreview.substring(0, 200)}...';
      }

      final shareText = '''
$sharePreview

Read more in Hindu Connect App:
https://play.google.com/store/apps/details?id=com.dikonda.hinduconnect
''';
      
      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (e) {
      // Handle error silently
    }
  }

  String _getSacredTextTitle() {
    if (_sacredTextModel != null) {
      return _sacredTextModel!.title ?? 'Sacred Text';
    }
    return 'Sacred Text';
  }

  String _getSacredTextContent() {



    
    String content = '';
    
    // Use converted content if available
    if (_convertedContent != null && _convertedContent!.isNotEmpty) {

      content = _convertedContent!;
    } else if (_sacredTextModel != null) {
      if (_sacredTextModel!.text != null && _sacredTextModel!.text!.isNotEmpty) {

        content = _sacredTextModel!.text!;
      } else if (_sacredTextModel!.excerpt != null && _sacredTextModel!.excerpt!.isNotEmpty) {

        content = _sacredTextModel!.excerpt!;
      }
    }
    
    if (content.isEmpty) {

      return 'No content available for this sacred text.';
    }
    
    // Prepare content for markdown rendering (handles HTML line breaks)
    return MarkdownService.prepareMarkdownForRendering(content);
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
          _getSacredTextTitle(),
          style: FontService.getTextStyleForLanguage(
            _userPreferredLanguage ?? 'Devanagari',
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
                            Icons.menu_book,
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
                                _getSacredTextTitle(),
                                style: FontService.getTextStyleForLanguage(
                                  _userPreferredLanguage ?? 'Devanagari',
                                  fontSize: readingSettings.textSize + 2,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              if (_sacredTextModel?.subtitle != null) ...[
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
                                    _sacredTextModel!.subtitle!,
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
                  
                  // Content with Markdown rendering using global settings
                  Consumer(
                    builder: (context, ref, child) {
                      final readingSettings = ref.watch(readingSettingsProvider);
                      return Markdown(
                        key: ValueKey('sacred_text_markdown_${readingSettings.textSize}_${readingSettings.backgroundColor.toARGB32()}_${readingSettings.textSpacing}'),
                        data: _getSacredTextContent(),
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
                  ),
                  
                  const SizedBox(height: AppTheme.spacingXXXL),
                  
                            ],
        ),
      ),
    );
  }

  Future<void> _showReadingSettings() async {
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
}