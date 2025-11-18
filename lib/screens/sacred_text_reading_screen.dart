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
import 'package:hindu_connect/services/deep_link_service.dart';
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
    'itrans (English)', // Also support the shorter name
    'Malayalam',
    'Tamil',
    'Telugu',
    'Kannada',
  };

  // Helper method to check if language has direct content available
  bool _hasDirectContent(String language) {
    // Normalize language name to handle variations
    final normalizedLanguage = language.trim();
    if (_availableLanguages.contains(normalizedLanguage)) {
      return true;
    }
    // Also check if it's a variation of "itrans (English)"
    if (normalizedLanguage.toLowerCase().contains('itrans') && 
        normalizedLanguage.toLowerCase().contains('english')) {
      return true;
    }
    return false;
  }
  
  // Normalize language name for consistent handling
  String _normalizeLanguage(String language) {
    final normalized = language.trim();
    if (normalized.toLowerCase().contains('itrans') && 
        normalized.toLowerCase().contains('english')) {
      return 'Roman itrans (English)';
    }
    return normalized;
  }

  // State variables
  SacredTextModel? _sacredTextModel;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _userPreferredLanguage;
  String? _convertedContent;
  String? _convertedTitle;
  
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
    // Get user's preferred language
    final currentLanguage = ref.read(languageProvider);
    // Normalize language name to handle variations (e.g., "itrans (English)" -> "Roman itrans (English)")
    final normalizedLanguage = _normalizeLanguage(currentLanguage);
    _userPreferredLanguage = normalizedLanguage;
    
    // Determine API language code: For 6 native languages, use their code; for others, always use Devanagari
    final bool isNativeLanguage = _hasDirectContent(normalizedLanguage);
    final String apiLanguageCode = isNativeLanguage 
        ? LanguageConversionService.getLanguageCode(normalizedLanguage)
        : 'hi'; // Always use Devanagari for non-native languages

    try {
      // Try to get from widget.sacredText first (from search/home screen)
      if (widget.sacredText != null) {

        _sacredTextModel = SacredTextModel.fromJson(widget.sacredText!);
        
        // Check if we have full content (>= 500 chars indicates full text, not just excerpt)
        final hasFullContent = _sacredTextModel!.text != null && 
            _sacredTextModel!.text!.isNotEmpty && 
            _sacredTextModel!.text!.length >= 500;
        
        // Check what language the content claims to be in
        final searchResultLanguage = _sacredTextModel!.languageUsed ?? '';
        // Handle both language codes and full language names
        String searchResultLanguageName = searchResultLanguage;
        if (searchResultLanguage.length <= 5 && !searchResultLanguage.contains(' ')) {
          // Likely a language code, convert to name
          searchResultLanguageName = LocalStorageService.getLanguageNameFromCode(searchResultLanguage) ?? searchResultLanguage;
        }
        
        // Normalize both for comparison
        final searchLangLower = searchResultLanguageName.toLowerCase();
        final userLangLower = normalizedLanguage.toLowerCase();
        final isSearchResultInUserLanguage = searchLangLower.contains(userLangLower) ||
            userLangLower.contains(searchLangLower) ||
            (searchResultLanguage.toLowerCase() == 'en' && userLangLower.contains('itrans'));
        
        // For HOME SCREEN: If we have full converted content in the user's language, use it directly
        // For SEARCH SCREEN: Search only converts excerpt, so we always need to fetch and convert full text
        if (hasFullContent && isSearchResultInUserLanguage && _sacredTextModel!.isConverted == true) {
          // Home screen: Full content already converted, use it directly
          logger.debug('🔍 Sacred Text Reading: Using full converted content from home screen for $normalizedLanguage');
          _convertedContent = _sacredTextModel!.text!;
          // Title should already be converted in home screen data, use it directly
          _convertedTitle = _sacredTextModel!.title;
          return;
        }
        
        // For all other cases (search screen, incomplete content, or wrong language), fetch full content and convert
        logger.debug('🔍 Sacred Text Reading: Fetching full content and converting for $normalizedLanguage (hasFullContent: $hasFullContent, isInUserLanguage: $isSearchResultInUserLanguage, isConverted: ${_sacredTextModel!.isConverted})');
        
        // Fetch full content from API with correct language parameter
        final apiService = ApiService();
        final sacredTextData = await apiService.getSacredTextById(widget.sacredTextId, language: apiLanguageCode);
        _sacredTextModel = SacredTextModel.fromJson(sacredTextData);
        
        // Cache the data
        await _cacheService.cacheSacredText(widget.sacredTextId, sacredTextData);
        
        // Convert the fetched content
        if (_sacredTextModel!.text != null && _sacredTextModel!.text!.isNotEmpty) {
          // Check what language the API actually returned
          final apiReturnedLanguage = _sacredTextModel!.languageUsed ?? '';
          String apiLanguageName = apiReturnedLanguage;
          if (apiReturnedLanguage.length <= 5 && !apiReturnedLanguage.contains(' ')) {
            // Likely a language code, convert to name
            apiLanguageName = LocalStorageService.getLanguageNameFromCode(apiReturnedLanguage) ?? apiReturnedLanguage;
          }
          
          // For non-native languages: ALWAYS convert from Devanagari
          // For native languages: use directly if API returned matching language
          bool needsConversion = false;
          if (!isNativeLanguage) {
            // Non-native language: always convert
            needsConversion = true;
            logger.debug('🔍 Sacred Text Reading: Non-native language $normalizedLanguage - always converting from $apiLanguageName');
          } else {
            // Native language: check if API returned matching language
            final apiLangLower = apiLanguageName.toLowerCase();
            final apiMatchesUserLanguage = apiLangLower.contains(userLangLower) ||
                userLangLower.contains(apiLangLower) ||
                (apiReturnedLanguage.toLowerCase() == 'en' && userLangLower.contains('itrans'));
            
            needsConversion = !apiMatchesUserLanguage;
            logger.debug('🔍 Sacred Text Reading: Native language $normalizedLanguage - API returned: $apiLanguageName, needsConversion: $needsConversion');
          }
          
          if (needsConversion) {
            logger.debug('🔍 Sacred Text Reading: Converting content from $apiLanguageName to $normalizedLanguage');
            // Convert both title and content to user's preferred language
            final convertedContent = await _conversionService.convertSacredTextContent(
              sacredTextId: widget.sacredTextId,
              userLanguage: normalizedLanguage,
              originalContent: _sacredTextModel!.text!,
            );
            _convertedContent = convertedContent;
            
            // Convert title if available
            if (_sacredTextModel!.title != null && _sacredTextModel!.title!.isNotEmpty) {
              try {
                final convertedTitle = await _conversionService.getConvertedTitleForSearch(
                  title: _sacredTextModel!.title!,
                  userLanguage: normalizedLanguage,
                );
                if (convertedTitle.isNotEmpty && convertedTitle != _sacredTextModel!.title) {
                  _convertedTitle = convertedTitle;
                } else {
                  _convertedTitle = _sacredTextModel!.title;
                }
              } catch (e) {
                _convertedTitle = _sacredTextModel!.title;
              }
            } else {
              _convertedTitle = _sacredTextModel!.title;
            }
          } else {
            logger.debug('🔍 Sacred Text Reading: Using direct content for $normalizedLanguage (API returned: $apiLanguageName)');
            _convertedContent = _sacredTextModel!.text!;
            _convertedTitle = _sacredTextModel!.title;
          }
        }
        return;
      }
      
      // Try cache first
      final cachedData = await _cacheService.getCachedSacredText(widget.sacredTextId);
      if (cachedData != null) {
        _sacredTextModel = SacredTextModel.fromJson(cachedData);
        
        // Convert if needed
        if (_sacredTextModel!.text != null && _sacredTextModel!.text!.isNotEmpty) {
          // Check what language the cached content is in
          final cachedLanguage = _sacredTextModel!.languageUsed ?? '';
          // Handle both language codes and full language names
          String cachedLanguageName = cachedLanguage;
          if (cachedLanguage.length <= 5 && !cachedLanguage.contains(' ')) {
            // Likely a language code, convert to name
            cachedLanguageName = LocalStorageService.getLanguageNameFromCode(cachedLanguage) ?? cachedLanguage;
          }
          
          // For non-native languages: ALWAYS convert from Devanagari
          // For native languages: use directly if cached content is in the user's preferred language
          bool needsConversion = false;
          if (!isNativeLanguage) {
            // Non-native language: always convert
            needsConversion = true;
            logger.debug('🔍 Sacred Text Reading: Non-native language $normalizedLanguage - converting cached content from $cachedLanguageName');
          } else {
            // Native language: check if cached content matches user's language
            final cachedLangLower = cachedLanguageName.toLowerCase();
            final userLangLower = normalizedLanguage.toLowerCase();
            final cachedMatchesUserLanguage = cachedLangLower.contains(userLangLower) ||
                userLangLower.contains(cachedLangLower) ||
                (cachedLanguage.toLowerCase() == 'en' && userLangLower.contains('itrans'));
            
            needsConversion = !cachedMatchesUserLanguage;
            logger.debug('🔍 Sacred Text Reading: Native language $normalizedLanguage - cached: $cachedLanguageName, needsConversion: $needsConversion');
          }
          
          if (needsConversion) {
            logger.debug('🔍 Sacred Text Reading: Converting cached content from $cachedLanguageName to $normalizedLanguage');
            final convertedContent = await _conversionService.convertSacredTextContent(
              sacredTextId: widget.sacredTextId,
              userLanguage: normalizedLanguage,
              originalContent: _sacredTextModel!.text!,
            );
            _convertedContent = convertedContent;
            
            // Convert title if available
            if (_sacredTextModel!.title != null && _sacredTextModel!.title!.isNotEmpty) {
              try {
                final convertedTitle = await _conversionService.getConvertedTitleForSearch(
                  title: _sacredTextModel!.title!,
                  userLanguage: normalizedLanguage,
                );
                if (convertedTitle.isNotEmpty && convertedTitle != _sacredTextModel!.title) {
                  _convertedTitle = convertedTitle;
                } else {
                  _convertedTitle = _sacredTextModel!.title;
                }
              } catch (e) {
                _convertedTitle = _sacredTextModel!.title;
              }
            } else {
              _convertedTitle = _sacredTextModel!.title;
            }
          } else {
            logger.debug('🔍 Sacred Text Reading: Using cached direct content for $normalizedLanguage (cached: $cachedLanguageName)');
            _convertedContent = _sacredTextModel!.text!;
            _convertedTitle = _sacredTextModel!.title;
          }
        }
        return;
      }
    } catch (e) {
      // Handle error silently - will try API call
    }
      
    // Fetch from API as last resort  
    try {
      logger.debug('🔍 Sacred Text Reading: Requesting content with language: $normalizedLanguage (code: $apiLanguageCode, isNative: $isNativeLanguage)');
      final apiService = ApiService();
      final sacredTextData = await apiService.getSacredTextById(widget.sacredTextId, language: apiLanguageCode);
      _sacredTextModel = SacredTextModel.fromJson(sacredTextData);
      
      logger.debug('🔍 Sacred Text Reading: API returned content length: ${_sacredTextModel!.text?.length ?? 0}');
      
      // If no content and we requested a native language, try Devanagari as fallback
      if ((_sacredTextModel!.text == null || _sacredTextModel!.text!.isEmpty) && isNativeLanguage) {
        logger.debug('🔍 Sacred Text Reading: No content in requested native language, trying Devanagari fallback');
        
        try {
          final fallbackData = await apiService.getSacredTextById(widget.sacredTextId, language: 'hi');
          final fallbackModel = SacredTextModel.fromJson(fallbackData);
          
          if (fallbackModel.text != null && fallbackModel.text!.isNotEmpty) {
            _sacredTextModel = fallbackModel;
            
            // Convert from Devanagari to user's preferred language
            logger.debug('🔍 Sacred Text Reading: Fallback found Devanagari content, converting to $normalizedLanguage');
            final convertedContent = await _conversionService.convertSacredTextContent(
              sacredTextId: widget.sacredTextId,
              userLanguage: normalizedLanguage,
              originalContent: _sacredTextModel!.text!,
            );
            _convertedContent = convertedContent;
            
            // Convert title if available
            if (_sacredTextModel!.title != null && _sacredTextModel!.title!.isNotEmpty) {
              try {
                final convertedTitle = await _conversionService.getConvertedTitleForSearch(
                  title: _sacredTextModel!.title!,
                  userLanguage: normalizedLanguage,
                );
                if (convertedTitle.isNotEmpty && convertedTitle != _sacredTextModel!.title) {
                  _convertedTitle = convertedTitle;
                } else {
                  _convertedTitle = _sacredTextModel!.title;
                }
              } catch (e) {
                _convertedTitle = _sacredTextModel!.title;
              }
            } else {
              _convertedTitle = _sacredTextModel!.title;
            }
            
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
        // Check what language the API actually returned
        final apiReturnedLanguage = _sacredTextModel!.languageUsed ?? '';
        // Handle both language codes and full language names
        String apiLanguageName = apiReturnedLanguage;
        if (apiReturnedLanguage.length <= 5 && !apiReturnedLanguage.contains(' ')) {
          // Likely a language code, convert to name
          apiLanguageName = LocalStorageService.getLanguageNameFromCode(apiReturnedLanguage) ?? apiReturnedLanguage;
        }
        
        // For non-native languages: ALWAYS convert from Devanagari
        // For native languages: use directly if API returned matching language
        bool needsConversion = false;
        if (!isNativeLanguage) {
          // Non-native language: always convert
          needsConversion = true;
          logger.debug('🔍 Sacred Text Reading: Non-native language $normalizedLanguage - always converting from $apiLanguageName');
        } else {
          // Native language: check if API returned matching language
          final apiLangLower = apiLanguageName.toLowerCase();
          final userLangLower = normalizedLanguage.toLowerCase();
          final apiMatchesUserLanguage = apiLangLower.contains(userLangLower) ||
              userLangLower.contains(apiLangLower) ||
              (apiReturnedLanguage.toLowerCase() == 'en' && userLangLower.contains('itrans'));
          
          needsConversion = !apiMatchesUserLanguage;
          logger.debug('🔍 Sacred Text Reading: Native language $normalizedLanguage - API returned: $apiLanguageName, needsConversion: $needsConversion');
        }
        
        if (needsConversion) {
          // Convert to user's preferred language (from Devanagari for non-native, or from wrong language for native)
          logger.debug('🔍 Sacred Text Reading: Converting content from $apiLanguageName to $normalizedLanguage');
          final convertedContent = await _conversionService.convertSacredTextContent(
            sacredTextId: widget.sacredTextId,
            userLanguage: normalizedLanguage,
            originalContent: _sacredTextModel!.text!,
          );
          _convertedContent = convertedContent;
          
          // Convert title if available
          if (_sacredTextModel!.title != null && _sacredTextModel!.title!.isNotEmpty) {
            try {
              final convertedTitle = await _conversionService.getConvertedTitleForSearch(
                title: _sacredTextModel!.title!,
                userLanguage: normalizedLanguage,
              );
              if (convertedTitle.isNotEmpty && convertedTitle != _sacredTextModel!.title) {
                _convertedTitle = convertedTitle;
              } else {
                _convertedTitle = _sacredTextModel!.title;
              }
            } catch (e) {
              _convertedTitle = _sacredTextModel!.title;
            }
          } else {
            _convertedTitle = _sacredTextModel!.title;
          }
        } else {
          logger.debug('🔍 Sacred Text Reading: Using direct content for $normalizedLanguage (API returned: $apiLanguageName)');
          _convertedContent = _sacredTextModel!.text!;
          _convertedTitle = _sacredTextModel!.title;
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
      final title = _getSacredTextTitle();
      final sacredTextId = widget.sacredTextId;
      
      // Create preview for sharing (first 200 characters)
      String sharePreview = content;
      if (sharePreview.length > 200) {
        sharePreview = '${sharePreview.substring(0, 200)}...';
      }

      final shareText = DeepLinkService.generateShareText(
        preview: sharePreview,
        type: 'sacredtext',
        id: sacredTextId,
        title: title,
      );
      
      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (e) {
      // Handle error silently
    }
  }

  String _getSacredTextTitle() {
    // Use converted title if available, otherwise use original
    if (_convertedTitle != null && _convertedTitle!.isNotEmpty) {
      return _convertedTitle!;
    }
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
                  
                  // Highlights/Tags section (similar to temples)
                  if (_sacredTextModel?.displayHighlights != null && _sacredTextModel!.displayHighlights.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingXXL),
                    Consumer(
                      builder: (context, ref, child) {
                        final readingSettings = ref.watch(readingSettingsProvider);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Highlights:',
                              style: TextStyle(
                                fontSize: readingSettings.textSize + 2,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Markdown(
                              key: ValueKey('sacred_text_highlights_markdown_${readingSettings.textSize}_${readingSettings.backgroundColor.toARGB32()}_${readingSettings.textSpacing}'),
                              data: _sacredTextModel!.displayHighlights.map((highlight) => '• $highlight').join('\n'),
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
                        );
                      },
                    ),
                  ],
                  
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