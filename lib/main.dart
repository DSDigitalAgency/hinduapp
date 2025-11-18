import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hindu_connect/services/logger_service.dart';
import 'dart:async';
import 'screens/main_navigation_screen.dart';
import 'screens/biography_reading_screen.dart';
import 'screens/sacred_text_reading_screen.dart';
import 'screens/temple_reading_screen.dart';
import 'screens/ad_splash_screen.dart';
import 'screens/language_selection_screen.dart';
import 'models/sacred_text_model.dart';
import 'constants/app_theme.dart';
import 'providers/reading_settings_provider.dart';
import 'services/local_storage_service.dart';
import 'services/deferred_deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger service first
  logger.initialize();
  
  // Completely disable Flutter error handling to prevent loops
  FlutterError.onError = null;
  
  // Ensure status bar is visible for the main app
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Set a consistent, app-wide system UI style (status/navigation bars)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  // Cache will be initialized when user reaches home screen
  
  runApp(ProviderScope(child: const AppInitializer()));
}

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize reading settings
      await ref.read(readingSettingsProvider.notifier).initializeSettings();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // If initialization fails, still proceed with the app
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return const HinduConnectApp();
  }
}

class HinduConnectApp extends StatefulWidget {
  const HinduConnectApp({super.key});

  @override
  State<HinduConnectApp> createState() => _HinduConnectAppState();
}

class _HinduConnectAppState extends State<HinduConnectApp> {
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinkHandling();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinkHandling() async {
    // Handle app started from deep link
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      logger.debug('Received initial deep link: $initialLink');
      logger.debug('Initial link string: ${initialLink.toString()}');
      logger.debug('Initial link scheme: ${initialLink.scheme}');
      logger.debug('Initial link path: ${initialLink.path}');
      logger.debug('Initial link pathSegments: ${initialLink.pathSegments}');
      // Store deep link to be handled after splash screen
      await _storeDeepLinkForSplash(initialLink);
    } else {
      logger.debug('No initial deep link found');
    }

    // Handle deep links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        logger.debug('Received deep link while app running: $uri');
        // When app is already running, navigate directly
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      logger.error('Error in deep link stream: $err');
    });
  }

  /// Store deep link data to be handled after splash screen
  Future<void> _storeDeepLinkForSplash(Uri uri) async {
    try {
      logger.debug('Storing deep link for splash: $uri');
      final prefs = await SharedPreferences.getInstance();
      String? path;
      String? id;
      
      logger.debug('URI details - scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}, pathSegments: ${uri.pathSegments}, authority: ${uri.authority}');
      
      // Handle both custom scheme (hinduconnect://) and HTTPS universal links
      if (uri.scheme == 'hinduconnect') {
        // Custom scheme deep link format: hinduconnect://sacredtext/123
        // For custom schemes, Android may put content type in host/authority
        // and ID in path, OR both in path segments
        
        // First, try to parse from the full URI string using regex (most reliable)
        final uriString = uri.toString();
        final match = RegExp(r'hinduconnect://([^/]+)/(.+)').firstMatch(uriString);
        if (match != null) {
          path = match.group(1);
          id = match.group(2);
          logger.debug('Parsed from regex - path: $path, id: $id');
        } else {
          // Fallback: Check if host/authority has the content type
          // Android may parse hinduconnect://temple/123 as host=temple, path=/123
          if (uri.host.isNotEmpty && uri.pathSegments.isNotEmpty) {
            // Content type is in host, ID is in path
            path = uri.host;
            id = uri.pathSegments[0];
            logger.debug('Parsed from host and path - path: $path, id: $id');
          } else if (uri.pathSegments.length >= 2) {
            // Both in path segments
            path = uri.pathSegments[0];
            id = uri.pathSegments[1];
            logger.debug('Parsed from path segments - path: $path, id: $id');
          } else if (uri.pathSegments.length == 1) {
            // Only ID in path, try authority for type
            if (uri.authority.isNotEmpty) {
              path = uri.authority;
              id = uri.pathSegments[0];
              logger.debug('Parsed from authority and path - path: $path, id: $id');
            } else {
              path = 'post';
              id = uri.pathSegments[0];
            }
          }
        }
      } else if (uri.scheme == 'https' && uri.host.contains('hinduconnect')) {
        // Universal link (HTTPS) format: https://hinduconnect.app/sacredtext/123
        if (uri.pathSegments.length >= 2) {
          path = uri.pathSegments[0];
          id = uri.pathSegments[1];
        } else if (uri.pathSegments.length == 1) {
          path = 'post';
          id = uri.pathSegments[0];
        }
      }
      
      logger.debug('Extracted - path: $path, id: $id');
      
      if (path != null && id != null && id.isNotEmpty) {
        // Decode URL-encoded IDs
        id = Uri.decodeComponent(id);
        // Store for splash screen to handle
        await prefs.setString('pendingDeepLinkType', path);
        await prefs.setString('pendingDeepLinkId', id);
        logger.debug('Stored deep link - type: $path, id: $id');
      } else {
        logger.debug('Failed to extract path or id from deep link');
      }
    } catch (e) {
      logger.error('Error storing deep link for splash: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    try {
      logger.debug('Handling deep link: $uri');
      logger.debug('URI scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}, pathSegments: ${uri.pathSegments}, authority: ${uri.authority}');
      
      String? path;
      String? id;
      
      // Handle both custom scheme (hinduconnect://) and HTTPS universal links
      if (uri.scheme == 'hinduconnect') {
        // Custom scheme deep link format: hinduconnect://sacredtext/123
        // For custom schemes, Android may put content type in host/authority
        // and ID in path, OR both in path segments
        
        // First, try to parse from the full URI string using regex (most reliable)
        final uriString = uri.toString();
        final match = RegExp(r'hinduconnect://([^/]+)/(.+)').firstMatch(uriString);
        if (match != null) {
          path = match.group(1);
          id = match.group(2);
          logger.debug('Parsed from regex - path: $path, id: $id');
        } else {
          // Fallback: Check if host/authority has the content type
          // Android may parse hinduconnect://temple/123 as host=temple, path=/123
          if (uri.host.isNotEmpty && uri.pathSegments.isNotEmpty) {
            // Content type is in host, ID is in path
            path = uri.host;
            id = uri.pathSegments[0];
            logger.debug('Parsed from host and path - path: $path, id: $id');
          } else if (uri.pathSegments.length >= 2) {
            // Both in path segments
            path = uri.pathSegments[0];
            id = uri.pathSegments[1];
            logger.debug('Parsed from path segments - path: $path, id: $id');
          } else if (uri.pathSegments.length == 1) {
            // Only ID in path, try authority for type
            if (uri.authority.isNotEmpty) {
              path = uri.authority;
              id = uri.pathSegments[0];
              logger.debug('Parsed from authority and path - path: $path, id: $id');
            } else {
              path = 'post';
              id = uri.pathSegments[0];
            }
          }
        }
      } else if (uri.scheme == 'https' && uri.host.contains('hinduconnect')) {
        // Universal link (HTTPS) format: https://hinduconnect.app/sacredtext/123
        if (uri.pathSegments.length >= 2) {
          path = uri.pathSegments[0];
          id = uri.pathSegments[1];
        } else if (uri.pathSegments.length == 1) {
          path = 'post';
          id = uri.pathSegments[0];
        }
      }
    
      logger.debug('Extracted path: $path, id: $id');
      
      if (path == null || id == null) {
        logger.debug('Could not extract path or id from deep link');
        return;
      }
      
      // Decode URL-encoded IDs
      id = Uri.decodeComponent(id);
      logger.debug('Navigating to $path/$id');
      
      // When app is already running, store the link and navigate from current context
      // We need to navigate from the current navigator context, not from the app widget
      _navigateToContentFromDeepLink(path, id);
    } catch (e) {
      logger.error('Error handling deep link: $e');
    }
  }
  
  void _navigateToContentFromDeepLink(String path, String id) {
    // When app is already running, navigate directly
    // Use the navigator from the current context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final context = navigatorKey.currentContext;
        if (context != null) {
          logger.debug('Navigating directly to $path/$id from deep link');
          _navigateToContent(context, path, id);
        } else {
          // If no context, store for later
          logger.debug('No navigator context, storing deep link for later');
          _storeDeepLinkForNavigation(path, id);
        }
      } catch (e) {
        logger.error('Error navigating to content from deep link: $e');
        // Fallback: store for later
        _storeDeepLinkForNavigation(path, id);
      }
    });
  }
  
  void _navigateToContent(BuildContext context, String path, String id) {
    try {
      switch (path) {
        case 'biography':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BiographyReadingScreen(
                title: 'Biography',
                content: 'Loading biography...',
              ),
            ),
          );
          break;
        case 'sacredtext':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SacredTextReadingScreen(sacredTextId: id),
            ),
          );
          break;
        case 'temple':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TempleReadingScreen(templeId: id),
            ),
          );
          break;
        case 'post':
          // TODO: Navigate to post
          logger.debug('Post navigation not yet implemented');
          break;
        default:
          logger.debug('Unknown content type: $path');
      }
    } catch (e) {
      logger.error('Error navigating to content: $e');
    }
  }
  
  Future<void> _storeDeepLinkForNavigation(String path, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingDeepLinkType', path);
      await prefs.setString('pendingDeepLinkId', id);
      logger.debug('Stored deep link for navigation - type: $path, id: $id');
    } catch (e) {
      logger.error('Error storing deep link for navigation: $e');
    }
  }

  void _navigateToBiography(String biographyId) async {
    if (!mounted) return;
    try {
      // Try to open the reading screen with minimal data; detailed fetch happens inside the screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BiographyReadingScreen(
            title: 'Biography',
            content: 'Loading biography...',
          ),
        ),
      );
    } catch (_) {}
  }

  void _navigateToSacredText(String sacredTextId) async {
    if (!mounted) return;
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SacredTextReadingScreen(
            sacredTextId: sacredTextId,
          ),
        ),
      );
    } catch (_) {}
  }

  void _navigateToTemple(String templeId) async {
    if (!mounted) return;
    try {
      // Import temple reading screen if needed
      // Navigator.of(context).push(
      //   MaterialPageRoute(
      //     builder: (_) => TempleReadingScreen(templeId: templeId),
      //   ),
      // );
    } catch (_) {}
  }

  void _navigateToPost(String postId) async {
    if (!mounted) return;
    try {
      // TODO: Fetch post data and navigate to PostReaderScreen
      // For now, we'll need to fetch the post from API first
      // This requires importing PostReaderScreen and ApiService
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Hindu Connect',
      theme: AppTheme.lightTheme,
      home: const _InitialRoute(),
      routes: {
        '/language-selection': (context) => const LanguageSelectionScreen(),
        '/ad-splash': (context) => const AdSplashScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/sacred-text-reading': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as SacredTextModel;
          return SacredTextReadingScreen(
            sacredTextId: args.sacredTextId ?? '',
            sacredText: args.toJson(),
          );
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class _InitialRoute extends StatefulWidget {
  const _InitialRoute();

  @override
  State<_InitialRoute> createState() => _InitialRouteState();
}

class _InitialRouteState extends State<_InitialRoute> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    try {
      // Check for deferred deep link first (only on first run)
      final deferredContentId = await DeferredDeepLinkService.checkDeferredDeepLink();
      final deferredLinkData = await DeferredDeepLinkService.getDeferredLinkData();
      
      final isLanguageSelected = await LocalStorageService.isLanguageSelected();
      
      if (mounted) {
        // If we have a deferred deep link, store it for later navigation
        // (after language selection and splash screen)
        if (deferredContentId != null && deferredLinkData != null) {
          // Store in SharedPreferences for later use
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pendingDeferredLinkType', deferredLinkData['type'] ?? 'post');
          await prefs.setString('pendingDeferredLinkId', deferredLinkData['id'] ?? deferredContentId);
        }
        
        if (isLanguageSelected) {
          // Language already selected, go to splash screen
          Navigator.of(context).pushReplacementNamed('/ad-splash');
        } else {
          // First launch, show language selection
          Navigator.of(context).pushReplacementNamed('/language-selection');
        }
      }
    } catch (e) {
      // On error, show language selection screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/language-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
