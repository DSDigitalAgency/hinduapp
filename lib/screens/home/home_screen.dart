import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/local_storage_service.dart';
import '../../services/ads_service.dart';
import '../../models/sacred_text_model.dart';
import '../../models/temple_model.dart';
import '../../models/biography_model.dart';
import '../../providers/home_data_provider.dart';
import '../biography_reading_screen.dart';
import '../sacred_text_reading_screen.dart';
import '../temple_reading_screen.dart';
import '../favorites_screen.dart';
import '../../constants/app_theme.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/welcome_banner.dart';
import 'widgets/ads_slider.dart';
import 'widgets/sacred_texts_section.dart';
import 'widgets/temples_section.dart';
import 'widgets/biographies_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final AdsService _adsService = AdsService();

  // State variables for Ads Slider only
  List<String> _adImages = [];
  bool _isLoadingAds = false;
  int _currentAdIndex = 0;
  Timer? _adsTimer;
  PageController? _adsPageController;

  // Track if home screen is currently visible for ads
  bool _isHomeScreenVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _adsPageController = PageController();
    _isHomeScreenVisible = true;

    // Initialize ads and load home data using Riverpod
    Future.microtask(() {
      _loadAdsForSlider();
      
      // Data loading is now handled automatically by the provider initialization
      // No need to manually trigger loadInitialData() here
    });
  }

  @override
  void dispose() {
    _adsTimer?.cancel();
    _adsPageController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _adsTimer?.cancel();
    } else if (state == AppLifecycleState.resumed &&
        _isHomeScreenVisible &&
        _adImages.isNotEmpty) {
      _startAdsTimer();
    }
  }

  void _onScreenVisible() {
    if (!_isHomeScreenVisible) {
      _isHomeScreenVisible = true;
      if (_adImages.isNotEmpty) {
        _startAdsTimer();
      }
    }
  }

  void _onScreenInvisible() {
    if (_isHomeScreenVisible) {
      _isHomeScreenVisible = false;
      _adsTimer?.cancel();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final ModalRoute? route = ModalRoute.of(context);
        final isCurrentRoute = route?.isCurrent ?? false;

        if (isCurrentRoute && !_isHomeScreenVisible) {
          _onScreenVisible();
        } else if (!isCurrentRoute && _isHomeScreenVisible) {
          _onScreenInvisible();
        }
      }
    });
  }

  void _loadAdsForSlider() {
    if (mounted) {
      setState(() {
        _adImages = _adsService.getSliderImages();
        _isLoadingAds = false;
      });

      if (_adImages.isNotEmpty && _isHomeScreenVisible) {
        _startAdsTimer();
      }
    }
  }

  void _startAdsTimer() {
    _adsTimer?.cancel();
    _adsTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted &&
          _adImages.isNotEmpty &&
          _adsPageController != null &&
          _isHomeScreenVisible) {
        final nextIndex = (_currentAdIndex + 1) % _adImages.length;
        setState(() {
          _currentAdIndex = nextIndex;
        });
        _adsPageController!.animateToPage(
          nextIndex,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Navigation methods
  Future<void> _navigateToSacredText(SacredTextModel sacredText) async {
    await LocalStorageService.addToRecentlyViewed({
      'id': sacredText.sacredTextId ?? '',
      'sacredTextId': sacredText.sacredTextId ?? '',
      'title': sacredText.displayTitle,
      'excerpt': sacredText.excerpt ?? sacredText.text ?? '',
      'type': 'sacredText',
      'viewed_at': DateTime.now().toIso8601String(),
    });
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SacredTextReadingScreen(
            sacredTextId: sacredText.sacredTextId ?? '',
            sacredText: sacredText.toJson(),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToTemple(TempleModel temple) async {
    await LocalStorageService.addToRecentlyViewed({
      'id': temple.templeId ?? '',
      'templeId': temple.templeId ?? '',
      'title': temple.displayTitle,
      'excerpt': temple.excerpt ?? temple.text ?? '',
      'type': 'temple',
      'viewed_at': DateTime.now().toIso8601String(),
    });
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TempleReadingScreen(
            templeId: temple.templeId ?? '',
            temple: temple.toJson(),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToBiography(BiographyModel bio) async {
    await LocalStorageService.addToRecentlyViewed({
      'id': bio.id,
      'biographyId': bio.biographyId ?? bio.id,
      'title': bio.title ?? bio.name ?? '',
      'name': bio.name ?? bio.title ?? '',
      'excerpt': bio.excerpt ?? bio.description ?? '',
      'type': 'biography',
      'viewed_at': DateTime.now().toIso8601String(),
    });
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BiographyReadingScreen(
            title: bio.displayTitle,
            content: bio.displayContent,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for reactive updates
    final homeDataState = ref.watch(homeDataProvider);

    // Extract data from state
    final sacredTexts = homeDataState.sacredTexts;
    final temples = homeDataState.temples;
    final biographies = homeDataState.biographies;
    final isLoading = homeDataState.isLoading;
    final errorMessage = homeDataState.errorMessage;

    // Ensure visibility is tracked on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isHomeScreenVisible) {
        _onScreenVisible();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.warmCreamColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: HomeAppBar(
          onFavoritesPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            const WelcomeBanner(),

            const SizedBox(height: AppTheme.spacingL),

            // Ads Slider
            AdsSlider(
              adImages: _adImages,
              isLoading: _isLoadingAds,
              currentAdIndex: _currentAdIndex,
              pageController: _adsPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentAdIndex = index;
                });
              },
            ),

            const SizedBox(height: AppTheme.spacingXXL),

            // Sacred Texts Section - Using Riverpod data
            SacredTextsSection(
              sacredTexts: sacredTexts,
              isLoading:
                  isLoading || (sacredTexts.isEmpty && errorMessage == null),
              errorMessage: sacredTexts.isEmpty ? errorMessage : null,
              onTextTap: _navigateToSacredText,
              onRefresh: () async {
                // Refresh handled by provider
              },
            ),

            const SizedBox(height: AppTheme.spacingXXL),

            // Temples Section - Using Riverpod data
            TemplesSection(
              temples: temples,
              isLoading: isLoading || (temples.isEmpty && errorMessage == null),
              errorMessage: temples.isEmpty ? errorMessage : null,
              onTempleTap: _navigateToTemple,
              onRefresh: () async {
                // Refresh handled by provider
              },
            ),

            const SizedBox(height: AppTheme.spacingXXL),

            // Biographies Section - Using Riverpod data
            BiographiesSection(
              biographies: biographies,
              isLoading:
                  isLoading || (biographies.isEmpty && errorMessage == null),
              errorMessage: biographies.isEmpty ? errorMessage : null,
              onBiographyTap: _navigateToBiography,
              onRefresh: () async {
                // Refresh handled by provider
              },
            ),

            const SizedBox(height: AppTheme.spacingXXL),
          ],
        ),
      ),
    );
  }
}
