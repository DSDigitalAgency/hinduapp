import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
// No debug imports
// Removed linkify/show-more dependencies
import '../models/video_model.dart';
import '../services/api_service.dart';
import '../services/youtube_service.dart';
import '../services/video_cache_service.dart';
import '../constants/app_theme.dart';
import 'video_player_screen.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final ApiService _apiService = ApiService();
  
  // Static cache to persist data across navigation
  static List<VideoModel> _cachedVideos = [];
  static bool _hasInitialized = false;
  static bool _isLoading = true;
  static bool _hasError = false;
  static String _errorMessage = '';
  static int _currentPage = 1;
  static bool _hasMoreData = true;
  static const int _pageSize = 12;
  static bool _isFetching = false; // prevent duplicate requests

  // Instance variables for UI state
  List<VideoModel> get _videos => _cachedVideos;
  bool get _isLoadingState => _isLoading;
  bool get _hasErrorState => _hasError;
  String get _errorMessageState => _errorMessage;
  bool get _hasMoreDataState => _hasMoreData;

  // Filters
  String? _selectedLanguage;
  String? _selectedCategory;
  final Set<String> _availableLanguages = <String>{};
  final Set<String> _availableCategories = <String>{};
  // Known options to show even before first page arrives
  static const List<String> _knownCategories = [
    'All Categories',
    'Astrology', 'Ayurveda', 'Festivals', 'General', 'Knowledge',
    'Movies', 'Music', 'Nature', 'Pravachanas', 'Shastras', 'Vastu', 'Worship', 'Yoga',
    'Aparam', // Always last
  ];
  static const List<String> _knownLanguages = [
    'All Languages',
    'English', 'Hindi', 'Sanskrit', 'Tamil', 'Telugu', 'Malayalam', 'Kannada',
    'Bengali', 'Gujarati', 'Marathi', 'Punjabi', 'Odia', 'Assamese', 'Urdu',
  ];
  // No expand/collapse; show brief description only

  @override
  void initState() {
    super.initState();
    // Only load data if not already initialized
    if (!_hasInitialized) {
      _loadVideosFromCache();
    }
  }

  // Load videos from cache first, then fetch fresh data
  Future<void> _loadVideosFromCache() async {
    // Build current filter params
    final Map<String, String> currentFilters = _buildFilterParams();
    
    // Try to load from cache
    final cachedVideos = await VideoCacheService.getCachedVideos(currentFilters);
    
    if (cachedVideos != null && cachedVideos.isNotEmpty) {
      setState(() {
        _cachedVideos = cachedVideos;
        _isLoading = false;
        _hasError = false;
        _hasInitialized = true;
      });
      
      // Fetch fresh data in background
      _loadVideos(refresh: true);
    } else {
      // No cache available, load fresh data
      _loadVideos(refresh: true);
    }
  }

  // Build filter parameters for caching
  Map<String, String> _buildFilterParams() {
    final Map<String, String> params = {};
    
    if (_selectedLanguage != null && _selectedLanguage!.isNotEmpty) {
      params['language'] = _selectedLanguage!.trim();
      final maybeCode = VideoModel.languageCodeFromName(_selectedLanguage);
      if (maybeCode != null) {
        params['language_code'] = maybeCode.trim();
      }
    }
    
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      params['category'] = _selectedCategory!;
    }
    
    return params;
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    
    if (refresh) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _currentPage = 1;
        _cachedVideos.clear();
      });
    }

    try {
      final Map<String, String> params = {
        'page': _currentPage.toString(),
        'limit': _pageSize.toString(),
      };
      
      // Add filter parameters
      if (_selectedLanguage != null && _selectedLanguage!.isNotEmpty) {
        final maybeCode = VideoModel.languageCodeFromName(_selectedLanguage);
        params['language'] = _selectedLanguage!.trim();
        if (maybeCode != null) {
          params['language_code'] = maybeCode.trim();
        }
      }
      
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        params['category'] = _selectedCategory!;
        params['cat'] = _selectedCategory!; // support alternate param
      }

      final response = await _apiService.getVideos(params);
      
      if (mounted) {
        final List<dynamic> videosData = response['videos'] ?? response['data'] ?? response['results'] ?? [];

        // Build initial models with better title handling
        List<VideoModel> basicVideos = videosData.map((video) {
          final v = VideoModel.fromJson(video);
          
          // Better title handling - avoid random/placeholder titles
          String? title = v.title;
          if (title == null || title.isEmpty || 
              title.toLowerCase().contains('random') ||
              title.toLowerCase().contains('sample') ||
              title.toLowerCase().contains('test') ||
              title.toLowerCase().contains('placeholder')) {
            title = null; // Will be populated by YouTube enrichment
          }
          
          return VideoModel(
            id: v.id,
            youtubeUrl: v.youtubeUrl,
            youtubeId: v.youtubeId,
            title: title,
            description: null, // clear any backend/sample description
            createdAt: v.createdAt,
            language: v.language,
            category: v.category,
          );
        }).toList();

        // Build filter options from received data
        for (final v in basicVideos) {
          // Normalize language: code or name
          final lang = VideoModel.languageNameFromCode(v.language);
          if ((lang ?? '').isNotEmpty) _availableLanguages.add(lang!);
          if ((v.category ?? '').isNotEmpty) _availableCategories.add(v.category!);
        }

        // Do not filter client-side by default; rely on server-side params for full dataset

        // Update state in one frame; avoid multiple rebuilds
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasError = false;
          if (refresh) {
            _cachedVideos = basicVideos;
          } else {
            _cachedVideos.addAll(basicVideos);
          }
          // Support multiple pagination flags from backend
          final meta = (response['metadata'] is Map) ? response['metadata'] as Map : null;
          final hasNextFromMeta = meta != null ? (meta['hasNext'] == true) : null;
          final hasNextPage = hasNextFromMeta ?? response['hasNextPage'] ?? response['has_more'] ?? (basicVideos.length >= _pageSize);
          _hasMoreData = hasNextPage == true;
          _hasInitialized = true;
        });

        // Cache the videos for future use
        if (refresh && basicVideos.isNotEmpty) {
          final currentFilters = _buildFilterParams();
          VideoCacheService.cacheVideos(_cachedVideos, currentFilters);
        }

        // Background enrichment with YouTube metadata (no spinners, no blocking)
        _enrichVideosWithYouTube(videosData);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _loadMoreVideos() async {
    if (!_hasMoreData || _isLoading || _isFetching) return;
    _currentPage++;
    await _loadVideos();
  }

  // Handle filter changes
  void _onFilterChanged() {
    // Clear cache when filters change
    VideoCacheService.clearCache();
    
    // Reset pagination
    _currentPage = 1;
    _hasMoreData = true;
    
    // Load fresh data with new filters
    _loadVideos(refresh: true);
  }

  // Refresh cache manually
  Future<void> _refreshCache() async {
    // Clear existing cache
    await VideoCacheService.clearCache();
    
    // Show loading state
    setState(() {
      _isLoading = true;
      _cachedVideos.clear();
    });
    
    // Load fresh data
    await _loadVideos(refresh: true);
  }

  Future<void> _enrichVideosWithYouTube(List<dynamic> videosData) async {
    // Parallel fetch for YouTube metadata; update models in place once available
    final List<_EnrichmentTask> tasks = [];
    for (final raw in videosData) {
      final temp = VideoModel.fromJson(raw);
      if (temp.youtubeId != null) {
        tasks.add(_EnrichmentTask(temp.id, temp.youtubeId!));
      }
    }

    if (tasks.isEmpty) return;

    await Future.wait(tasks.map((t) async {
      final meta = await YouTubeService.getVideoInfo(t.youtubeId);
      if (meta == null) return;
      if (!mounted) return;
      // Merge into state list
      final index = _cachedVideos.indexWhere((v) => v.id == t.videoId);
      if (index != -1) {
        final original = _cachedVideos[index];
        final updated = VideoModel(
          id: original.id,
          youtubeUrl: original.youtubeUrl,
          youtubeId: original.youtubeId,
          // Prioritize backend title, only use YouTube title as fallback if backend title is empty
          title: (original.title?.isNotEmpty == true) ? original.title : (meta['title'] ?? ''),
          description: (meta['description'] ?? ''),
          createdAt: original.createdAt,
          youtubeMetadata: meta,
          language: original.language,
          category: original.category,
        );
        if (!mounted) return;
      setState(() {
          _cachedVideos[index] = updated;
      });
    }
    }));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCreamColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
                          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                children: [
                  const Text(
                    'Videos',
                    style: TextStyle(
                      fontSize: AppTheme.textSizeXXXL,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildFiltersRow(),
                ],
            ),
            ),
            

            
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _refreshCache();
                },
                color: AppTheme.primaryColor,
                child: _buildVideosContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    final languages = (<String>{
      ..._availableLanguages,
      ..._knownLanguages.where((e) => e != 'All Languages'),
    }.toList()
          ..sort());
    final categories = (<String>{
      ..._availableCategories,
      ..._knownCategories.where((e) => e != 'All Categories'),
    }.toList()
          ..sort((a, b) {
            // Keep Aparam at the end
            if (a == 'Aparam') return 1;
            if (b == 'Aparam') return -1;
            return a.compareTo(b);
          }));

    return Row(
      children: [
        // Category filter
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
            child: DropdownButton<String>(
              value: _selectedCategory?.isEmpty == true ? null : _selectedCategory,
              hint: const Text('Category'),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem<String>(value: '', child: Text('All Categories')),
                ...categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))),
              ],
              onChanged: (val) {
                _selectedCategory = (val ?? '').trim();
                _onFilterChanged();
              },
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        // Language filter
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage?.isEmpty == true ? null : _selectedLanguage,
              hint: const Text('Language'),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem<String>(value: '', child: Text('All languages')),
                ...languages.map((l) => DropdownMenuItem<String>(value: l, child: Text(l))),
              ],
              onChanged: (val) {
                _selectedLanguage = (val ?? '').trim();
                _onFilterChanged();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideosContent() {
    // Show skeleton loading while content is loading
    if (_isLoadingState && _videos.isEmpty) {
      return _buildVideosSkeleton();
    }

    if (_hasErrorState && _videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Failed to load videos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(_errorMessageState, style: TextStyle(color: Colors.grey[600], fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: () => _loadVideos(refresh: true), child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.ondemand_video, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'No videos found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                (_selectedCategory?.isNotEmpty == true || _selectedLanguage?.isNotEmpty == true)
                    ? 'Try clearing filters to see more videos.'
                    : 'Please try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              if (_selectedCategory?.isNotEmpty == true || _selectedLanguage?.isNotEmpty == true)
                TextButton(
                  onPressed: () {
                    _selectedCategory = '';
                    _selectedLanguage = '';
                    _onFilterChanged();
                  },
                  child: const Text('Clear filters'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
      cacheExtent: 800,
      itemCount: _videos.length,
        itemBuilder: (context, index) {
        // Prefetch next page when 2 items away from end
        if (_hasMoreDataState && !_isLoadingState && index >= _videos.length - 2) {
          _loadMoreVideos();
          }
          final v = _videos[index];
          return _buildVideoCard(v);
        },
    );
  }

  Widget _buildVideoCard(VideoModel video) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final pr = MediaQuery.of(context).devicePixelRatio;
    final cacheW = (deviceWidth * pr).round();
    final cacheH = ((deviceWidth * 9 / 16) * pr).round();
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(video: video)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Thumbnail
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppTheme.borderRadiusL), topRight: Radius.circular(AppTheme.borderRadiusL)),
            ),
                          child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppTheme.borderRadiusL), topRight: Radius.circular(AppTheme.borderRadiusL)),
              child: (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty)
                        ? Image.network(
                            video.thumbnailUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                      filterQuality: FilterQuality.low,
                      cacheWidth: cacheW,
                      cacheHeight: cacheH,
                          )
                        : Container(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Icon(Icons.play_circle_outline, size: 40, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
            // Video info
            Padding(
              padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                          video.displayTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                                const SizedBox(height: AppTheme.spacingXS),
              Row(
                children: [
                  if ((video.categoryDisplay ?? '').isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: AppTheme.spacingXS),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                      ),
                      child: Text(
                        video.categoryDisplay!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                  ],
                  if ((video.languageDisplay ?? '').isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: AppTheme.spacingXS),
                      decoration: BoxDecoration(
                        color: AppTheme.languageBlueColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                      ),
                      child: Text(
                        video.languageDisplay!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.languageBlueColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.play_circle_outline, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: AppTheme.spacingXS),
                Text('Tap to watch', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: AppTheme.textSizeM, color: Colors.grey),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // Build skeleton loading for videos
  Widget _buildVideosSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      itemCount: 6, // Show 6 skeleton items
      itemBuilder: (context, index) {
        return _buildVideoSkeleton();
      },
    );
  }

  // Build individual video skeleton
  Widget _buildVideoSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.borderRadiusL),
                  topRight: Radius.circular(AppTheme.borderRadiusL),
                ),
              ),
            ),
          ),
          // Content skeleton
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusS),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                // Subtitle skeleton
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusS),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                // Tags skeleton
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description skeleton
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: MediaQuery.of(context).size.width * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Bottom row skeleton
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 16,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 16,
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Removed show more/less and linkification per requirement
}

class _EnrichmentTask {
  final String videoId;
  final String youtubeId;
  _EnrichmentTask(this.videoId, this.youtubeId);
} 