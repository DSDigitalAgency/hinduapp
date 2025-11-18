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
  YoutubePlayerController? _controller;
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
    
    // Use WebView as primary method to avoid error 153 issues
    // YouTube iframe player often fails with error 153 (embedding disabled)
    _initializeWebViewFallback();
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
    try {
      _controller?.close();
    } catch (e) {
      // Ignore if already closed
    }
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

  // YouTube player initialization removed - using WebView as primary method to avoid error 153

  void _initializeWebViewFallback() {
    if (widget.video.youtubeId == null || widget.video.youtubeId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    
    // Close the YouTube player controller if it exists
    try {
      _controller?.close();
    } catch (e) {
      // Ignore if already closed or not initialized
    }
    
    setState(() {
      _useWebViewFallback = true;
      _isLoading = true;
      _hasError = false;
    });

    // For error 15 (embedding blocked), try WebView first, but show clear error if it fails
    // The error screen will have a prominent button to open in YouTube app
    _initializeWebViewPlayer();
  }

  Future<bool> _tryOpenInYouTubeApp() async {
    try {
      final success = await YouTubeService.openYouTubeVideo(widget.video.youtubeId!);
      if (success && mounted) {
        // If successfully opened in YouTube app, navigate back after a delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
        return true;
      }
    } catch (e) {
      // YouTube app not available, continue with WebView
    }
    return false;
  }

  void _initializeWebViewPlayer() {
    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted && progress == 100) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
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
                // Log error for debugging
                print('WebView error: ${error.description} (${error.errorCode})');
                
                // Check if error message contains "error 15" or embedding-related errors
                final errorDesc = error.description.toLowerCase();
                if (errorDesc.contains('error 15') || 
                    errorDesc.contains('embedding') ||
                    errorDesc.contains('blocked') ||
                    error.errorCode == -2) {
                  // Error 15 or embedding blocked - automatically open in YouTube app
                  _openYouTubeVideo();
                  // Close this screen after opening YouTube
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                } else {
                  // Other errors - show error screen
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                  });
                }
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              // Allow YouTube embeds and related resources
              final url = request.url.toLowerCase();
              if (url.contains('youtube.com') || 
                  url.contains('youtube-nocookie.com') ||
                  url.contains('google.com') ||
                  url.contains('gstatic.com') ||
                  url.contains('googlevideo.com')) {
                return NavigationDecision.navigate;
              }
              // Block other navigation attempts
              return NavigationDecision.prevent;
            },
          ),
        );

      // Try youtube-nocookie.com first (more permissive), then fallback to regular youtube.com
      // Use HTML wrapper with iframe for better compatibility
      // Add JavaScript to detect error 15 and notify Flutter
      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        html, body {
            width: 100%;
            height: 100%;
            background-color: #000;
            overflow: hidden;
        }
        .video-container {
            position: relative;
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        iframe {
            width: 100%;
            height: 100%;
            border: none;
        }
        .error-message {
            color: white;
            text-align: center;
            padding: 20px;
            font-family: Arial, sans-serif;
        }
    </style>
</head>
<body>
    <div class="video-container">
        <iframe 
            id="ytplayer"
            src="https://www.youtube-nocookie.com/embed/${widget.video.youtubeId!}?autoplay=0&modestbranding=1&rel=0&showinfo=0&enablejsapi=1&playsinline=1&origin=https://hinduconnect.app&iv_load_policy=3"
            frameborder="0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
            allowfullscreen
            onload="checkForErrors()">
        </iframe>
    </div>
    <script>
        function checkForErrors() {
            // Check for error 15 or embedding issues after a delay
            setTimeout(function() {
                var iframe = document.getElementById('ytplayer');
                try {
                    // Try to access iframe content (will fail if cross-origin, but that's OK)
                    var iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                    var bodyText = iframeDoc.body.innerText || iframeDoc.body.textContent || '';
                    
                    // Check for error messages
                    if (bodyText.includes('error 15') || 
                        bodyText.includes('embedding') || 
                        bodyText.includes('blocked') ||
                        bodyText.includes('not available')) {
                        // Notify Flutter about error
                        if (window.flutter_inappwebview) {
                            window.flutter_inappwebview.callHandler('onError15');
                        }
                    }
                } catch(e) {
                    // Cross-origin error is expected, ignore
                }
            }, 2000);
        }
        
        // Also listen for iframe load errors
        window.addEventListener('error', function(e) {
            if (e.message && (e.message.includes('error 15') || e.message.includes('embedding'))) {
                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('onError15');
                }
            }
        }, true);
    </script>
</body>
</html>
      ''';
      
      _webViewController!.loadHtmlString(htmlContent, baseUrl: 'https://www.youtube-nocookie.com');
      
      // Set up a longer timeout to detect error 15 (videos that can't be embedded often show error after a few seconds)
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isLoading && !_hasError) {
          // If still loading after 5 seconds without error, might be error 15
          // Show error screen with option to open in YouTube
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
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
                  if (!_hasError && widget.video.youtubeId != null && _webViewController != null)
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: WebViewWidget(controller: _webViewController!),
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
                                'Video cannot be embedded',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'This video cannot be played here due to\nembedding restrictions. Please watch it\non YouTube instead.',
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
      _controller?.close();
    } catch (e) {
      // Ignore error if controller was already closed
    }
    
    // Reset WebView controller
    _webViewController = null;
    
    // Add a small delay to ensure cleanup
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Retry with WebView
    _initializeWebViewFallback();
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
    // Favorites now work without authentication (using local storage)
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
    // Favorites now work without authentication (using local storage)
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