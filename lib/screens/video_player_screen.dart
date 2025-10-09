import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/favorites_service.dart';
import '../services/youtube_service.dart';
import '../models/video_model.dart';
import '../constants/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  WebViewController? _webViewController;
  final FavoritesService _favoritesService = FavoritesService();
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _hasError = false;
  bool _useWebViewFallback = false;
  Map<String, dynamic>? _videoDetails;
  String? _category;
  String? _language;
  String get _languageDisplay => VideoModel.languageNameFromCode(_language) ?? (_language ?? '');

  @override
  void initState() {
    super.initState();
    
    // Initialize video player
    
    // Set system UI overlay style for video player screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.darkGrayColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    _category = widget.video.category;
    _language = widget.video.language;
    _initializeYouTubePlayer();
    _checkFavoriteStatus();
    _fetchVideoDetails();
  }

  @override
  void dispose() {
    // Restore default system UI overlay style when leaving video player
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _controller.close();
    super.dispose();
  }

  Future<void> _fetchVideoDetails() async {
    if (widget.video.youtubeId != null) {
      try {
        final details = await YouTubeService.getVideoInfo(widget.video.youtubeId!);
        if (mounted && details != null) {
          setState(() {
            _videoDetails = details;
          });
        }
      } catch (e) {
        // Handle silently
      }
    }
  }

  void _initializeYouTubePlayer() {
    if (widget.video.youtubeId == null || widget.video.youtubeId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.video.youtubeId!,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          loop: false,
        ),
      );

      // Listen for player state changes to handle errors
      _controller.listen((value) {
        if (mounted) {
          // Check if player encountered an error
          if (value.hasError) {
            // Try WebView fallback instead of showing error immediately
            _initializeWebViewFallback();
          } else if (value.playerState == PlayerState.playing || value.playerState == PlayerState.buffering) {
            if (_isLoading) {
              setState(() {
                _isLoading = false;
                _hasError = false;
              });
            }
          }
        }
      });

      // Set initial state
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _initializeWebViewFallback() {
    if (widget.video.youtubeId == null || _useWebViewFallback) return;
    
    setState(() {
      _useWebViewFallback = true;
      _isLoading = true;
      _hasError = false;
    });

    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading state
            },
            onPageStarted: (String url) {
              // Page started loading
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              }
            },
          ),
        );

      // Load YouTube embed URL
      final embedUrl = 'https://www.youtube.com/embed/${widget.video.youtubeId!}?autoplay=0&modestbranding=1&rel=0&showinfo=0';
      _webViewController!.loadRequest(Uri.parse(embedUrl));
      
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkGrayColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: Text(
          _videoDetails?['title'] ?? widget.video.displayTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        color: AppTheme.darkGrayColor,
        child: Column(
          children: [
            // Video player
            SizedBox(
              height: MediaQuery.of(context).size.width * 9 / 16,
              width: double.infinity,
              child: Stack(
                children: [
                  if (!_hasError && widget.video.youtubeId != null)
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _useWebViewFallback && _webViewController != null
                          ? WebViewWidget(controller: _webViewController!)
                          : YoutubePlayer(controller: _controller),
                    ),
                  
                  if (_isLoading)
                    Container(
                      color: AppTheme.darkGrayColor,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  
                  // Fallback for video unavailable
                  if (_hasError)
                    Positioned.fill(
                      child: Container(
                        color: AppTheme.darkGrayColor.withValues(alpha: 0.9),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.play_circle_outline,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Video unavailable',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Unable to load video',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => _openYouTubeVideo(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Watch video on YouTube',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _retryVideoLoad(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Video info
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video title
                      Text(
                        _videoDetails?['title'] ?? widget.video.displayTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Row(
                        children: [
                          if (((_category ?? '').isNotEmpty)) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: AppTheme.spacingXS),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                              ),
                              child: Text(
                                _category!,
                                style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                          ],
                          if (((_language ?? '').isNotEmpty))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: AppTheme.spacingXS),
                              decoration: BoxDecoration(
                                color: AppTheme.languageBlueColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                              ),
                              child: Text(
                                _languageDisplay,
                                style: const TextStyle(fontSize: 12, color: AppTheme.languageBlueColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      
                      // Channel only (views and duration removed)
                      if (_videoDetails != null && _videoDetails!['channelTitle'] != null) ...[
                        Text(
                          'Channel: ${_videoDetails!['channelTitle']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Video description
                      Text(
                        _videoDetails?['description'] ?? widget.video.displayDescription,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXXL),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryVideoLoad() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _useWebViewFallback = false;
    });
    
    // Close existing controller if it exists
    try {
      _controller.close();
    } catch (e) {
      // Ignore error if controller was already closed
    }
    
    // Reset WebView controller
    _webViewController = null;
    
    // Add a small delay to ensure cleanup
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Try YouTube player first, will fallback to WebView if needed
    _initializeYouTubePlayer();
  }

  Future<void> _openYouTubeVideo() async {
    if (widget.video.youtubeId != null) {
      final success = await YouTubeService.openYouTubeVideo(widget.video.youtubeId!);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open YouTube video'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    // If user is not authenticated, don't check favorites
    if (!_favoritesService.isUserAuthenticated) {
      if (mounted) {
        setState(() {
          _isFavorite = false;
        });
      }
      return;
    }

    final videoId = widget.video.id.isNotEmpty
        ? widget.video.id
        : (widget.video.youtubeId ?? '');
    
    if (videoId.isNotEmpty) {
      try {
        final isFav = await _favoritesService.isFavorited(videoId);
        if (mounted) {
          setState(() {
            _isFavorite = isFav;
          });
        }
      } catch (e) {
        // If there's an error checking favorite status, assume it's not favorited
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
        }
      }
    }
  }

  Future<void> _toggleFavorite() async {
    // Check if user is authenticated first
    if (!_favoritesService.isUserAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to add videos to favorites'),
            backgroundColor: AppTheme.warningColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final videoId = widget.video.id.isNotEmpty
        ? widget.video.id
        : (widget.video.youtubeId ?? '');
    
    if (videoId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to add to favorites: No video ID available'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }
    
    try {
      await _favoritesService.toggleFavorite(
        itemId: videoId,
        itemType: 'video',
        title: _videoDetails?['title'] ?? widget.video.displayTitle,
        description: _videoDetails?['description'] ?? widget.video.displayDescription,
        imageUrl: widget.video.thumbnailUrl,
      );
      
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
            backgroundColor: _isFavorite
                ? AppTheme.successColor
                : AppTheme.warningColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error: ${e.toString()}';
        if (e.toString().contains('User not authenticated')) {
          errorMessage = 'Please sign in to add videos to favorites';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}