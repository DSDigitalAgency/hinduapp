import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/local_storage_service.dart';
import '../../services/ads_service.dart';
import '../../providers/home_data_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/sacred_text_model.dart';
import '../../models/temple_model.dart';
import '../../models/biography_model.dart';
import '../biography_reading_screen.dart';
import '../sacred_text_reading_screen.dart';
import '../temple_reading_screen.dart';
import '../favorites_screen.dart';
import '../../constants/app_theme.dart';
import '../../features/search/screens/sacred_texts_search_screen.dart';
import '../../features/search/screens/temples_search_screen.dart';
import '../../features/search/screens/biographies_search_screen.dart';
import 'widgets/welcome_banner.dart';
import 'widgets/ads_slider.dart';
import 'widgets/sacred_texts_section.dart';
import 'widgets/temples_section.dart';
import 'widgets/biographies_section.dart';

class OptimizedHomeScreen extends ConsumerStatefulWidget {
  const OptimizedHomeScreen({super.key});

  @override
  ConsumerState<OptimizedHomeScreen> createState() =>
      _OptimizedHomeScreenState();
}

class _OptimizedHomeScreenState extends ConsumerState<OptimizedHomeScreen>
    with WidgetsBindingObserver {
  // Constants
  static const double _sectionSpacing = 20.0;

  final AdsService _adsService = AdsService();
  bool _hasInitialized = false;

  // State variables for Ads Slider
  List<String> _adImages = [];
  bool _isLoadingAds = false;
  int _currentAdIndex = 0;
  Timer? _adsTimer;
  PageController? _adsPageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _adsPageController = PageController();
    _loadAdsForSlider();
    
    // Initialize data loading through Riverpod (only once)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        ref.read(homeDataProvider.notifier).loadInitialData();
        // Refresh language to trigger data loading if needed
        ref.read(languageProvider.notifier).refreshLanguage();
      }
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
    } else if (state == AppLifecycleState.resumed) {
      if (_adImages.isNotEmpty) {
        _startAdsTimer();
      }
      // Refresh language when app resumes to check for changes
      if (mounted) {
        ref.read(languageProvider.notifier).refreshLanguage();
      }
    }
  }

  void _loadAdsForSlider() {
    if (mounted) {
      setState(() {
        _adImages = _adsService.getSliderImages();
        _isLoadingAds = false;
      });

      if (_adImages.isNotEmpty) {
        _startAdsTimer();
      }
    }
  }

  void _startAdsTimer() {
    _adsTimer?.cancel();
    _adsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _adImages.isNotEmpty && _adsPageController != null) {
        final nextIndex = (_currentAdIndex + 1) % _adImages.length;
        setState(() {
          _currentAdIndex = nextIndex;
        });
        _adsPageController!.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _resetAdsTimer() {
    _adsTimer?.cancel();
    if (_adImages.isNotEmpty) {
      _startAdsTimer();
    }
  }

  Future<void> _refreshData() async {
    _hasInitialized = false; // Reset flag to allow fresh data loading
    ref.read(homeDataProvider.notifier).refreshData();
  }

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
      // Open biography screen immediately - let it handle loading internally
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BiographyReadingScreen(
            title: bio.displayTitle,
            content: bio.displayContent,
            biographyId: bio.biographyId ?? bio.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch Riverpod providers
    final sacredTexts = ref.watch(sacredTextsProvider);
    final temples = ref.watch(templesProvider);
    final biographies = ref.watch(biographiesProvider);
    final isLoading = ref.watch(homeDataLoadingProvider);
    final errorMessage = ref.watch(homeDataErrorProvider);

    // Removed debug logging and currentLanguage variable that was causing performance issues

    return Scaffold(
      backgroundColor: AppTheme.warmCreamColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              // Sticky App Bar
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: AppTheme.primaryColor,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                toolbarHeight: 60,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Hindu Connect',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FavoritesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.favorite, color: Colors.white),
                            tooltip: 'Favorites',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Scrollable Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Banner
                    WelcomeBanner(),

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
                        _resetAdsTimer();
                      },
                    ),

                    const SizedBox(height: AppTheme.spacingXXL),

                    // Sacred Texts Section
                    SacredTextsSection(
                      sacredTexts: sacredTexts,
                      isLoading: isLoading,
                      errorMessage: errorMessage,
                      onTextTap: _navigateToSacredText,
                      onRefresh: _refreshData,
                      onSeeAllPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SacredTextsSearchScreen(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: _sectionSpacing),

                    // Temples Section
                    TemplesSection(
                      temples: temples,
                      isLoading: isLoading,
                      errorMessage: errorMessage,
                      onTempleTap: _navigateToTemple,
                      onSeeAllPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TemplesSearchScreen(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: _sectionSpacing),

                    // Biographies Section
                    BiographiesSection(
                      biographies: biographies,
                      isLoading: isLoading,
                      errorMessage: errorMessage,
                      onBiographyTap: _navigateToBiography,
                      onRefresh: _refreshData,
                      onSeeAllPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BiographiesSearchScreen(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: _sectionSpacing),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
