import 'package:flutter/material.dart';
import 'dart:async';
import '../services/ads_service.dart';
import '../services/data_preloader_service.dart';
import '../services/logger_service.dart';
import '../constants/app_theme.dart';

class AdSplashScreen extends StatefulWidget {
  const AdSplashScreen({super.key});

  @override
  State<AdSplashScreen> createState() => _AdSplashScreenState();
}

 class _AdSplashScreenState extends State<AdSplashScreen> {
   final AdsService _adsService = AdsService();
  final DataPreloaderService _dataPreloader = DataPreloaderService();
   String? _adImageUrl;
   Timer? _timer;
  Timer? _minDisplayTimer;
  bool _dataPreloadCompleted = false;
  bool _minTimeCompleted = false;
  String _loadingText = 'Loading sacred texts...';

  static const Duration _minDisplayDuration = Duration(seconds: 3);
  static const Duration _maxDisplayDuration = Duration(seconds: 8);

     @override
   void initState() {
     super.initState();
     _adImageUrl = _adsService.getSplashAdImage();
    _startDataPreloadingAndCountdown();
   }

   @override
   void dispose() {
     _timer?.cancel();
    _minDisplayTimer?.cancel();
     super.dispose();
   }

  void _startDataPreloadingAndCountdown() {
    // Start minimum display time timer
    _minDisplayTimer = Timer(_minDisplayDuration, () {
      if (mounted) {
        setState(() {
          _minTimeCompleted = true;
        });
        _checkAndNavigate();
      }
    });

    // Start maximum display time timer (fallback)
    _timer = Timer(_maxDisplayDuration, () {
       if (mounted) {
         _navigateToHome();
       }
     });
     
    // Start data preloading
    _preloadData();
  }

  Future<void> _preloadData() async {
    try {
      // Update loading text periodically
      _updateLoadingText();

      // Start data preloading
      final success = await _dataPreloader.preloadAllData();

      if (mounted) {
        setState(() {
          _dataPreloadCompleted = true;
          _loadingText = success ? 'Ready!' : 'Loading complete!';
        });

        // Small delay to show completion state
        await Future.delayed(const Duration(milliseconds: 500));

        _checkAndNavigate();
      }
    } catch (e) {
      
      if (mounted) {
        setState(() {
          _dataPreloadCompleted = true;
          _loadingText = 'Ready!';
        });
        _checkAndNavigate();
      }
    }
  }

  void _updateLoadingText() {
    final loadingSteps = [
      'Loading sacred texts...',
      'Loading temples...',
      'Loading biographies...',
      'Preparing content...',
      'Almost ready...',
    ];

    int stepIndex = 0;
    Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted || _dataPreloadCompleted) {
        timer.cancel();
        return;
      }

      setState(() {
        _loadingText = loadingSteps[stepIndex % loadingSteps.length];
      });
      stepIndex++;
    });
  }

  void _checkAndNavigate() {
    // Navigate only when both conditions are met:
    // 1. Data preloading is complete (or timed out)
    // 2. Minimum display time has elapsed
    if (_dataPreloadCompleted && _minTimeCompleted) {
      _navigateToHome();
    }
   }

  void _onSkipPressed() {
    logger.debug(
      'User skipped splash screen - ensuring background data loading continues',
    );

    // Ensure data loading continues in background even after navigation
    if (!_dataPreloadCompleted) {
      // Don't cancel the preloading - let it continue in background
      DataPreloaderService()
          .preloadAllData()
          .then((_) {
            
          })
          .catchError((error) {
            
          });
    }

    _navigateToHome();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Ad Image - Full Screen
            _buildContent(),
            
            // Skip Button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: _onSkipPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.darkGrayColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusXL,
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            
            // Loading indicator and text
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadingText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

     Widget _buildContent() {
     // Show image directly without loading state
     if (_adImageUrl == null || _adImageUrl!.isEmpty) {
       // Show branded fallback if no ad URL
       return Container(
         color: AppTheme.secondaryColor,
         child: const Center(
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Icon(
                 Icons.auto_stories,
                 size: 80,
                 color: Colors.white,
               ),
               SizedBox(height: AppTheme.spacingXXL),
               Text(
                 'Hindu Connect',
                 style: TextStyle(
                   color: Colors.white,
                   fontSize: 28,
                   fontWeight: FontWeight.w700,
                 ),
               ),
               SizedBox(height: AppTheme.spacingS),
               Text(
                 'Loading...',
                 style: TextStyle(
                   color: Colors.white,
                   fontSize: 16,
                   fontWeight: FontWeight.w500,
                 ),
               ),
             ],
           ),
         ),
       );
     }
     
     return SizedBox.expand(
       child: Image.network(
         _adImageUrl!,
         fit: BoxFit.cover,
         errorBuilder: (context, error, stackTrace) {
           // Try to show fallback image
           return Image.network(
             _adsService.getFallbackImage(),
             fit: BoxFit.cover,
             errorBuilder: (context, error, stackTrace) {
               // If fallback also fails, show branded fallback for Android 10 compatibility
               return Container(
                 color: AppTheme.secondaryColor,
                 child: const Center(
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(
                         Icons.auto_stories,
                         size: 80,
                         color: Colors.white,
                       ),
                       SizedBox(height: AppTheme.spacingXXL),
                       Text(
                         'Hindu Connect',
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: 28,
                           fontWeight: FontWeight.w700,
                         ),
                       ),
                       SizedBox(height: AppTheme.spacingS),
                       Text(
                         'Loading...',
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: 16,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                 ),
               );
             },
           );
         },
       ),
     );
  }
}
