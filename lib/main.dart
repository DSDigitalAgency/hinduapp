import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:hindu_connect/services/logger_service.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/biography_reading_screen.dart';
import 'screens/sacred_text_reading_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/ad_splash_screen.dart';
import 'services/auth_service.dart';
import 'models/sacred_text_model.dart';
import 'constants/app_theme.dart';
import 'providers/reading_settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger service first
  logger.initialize();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
      _handleDeepLink(initialLink.toString());
    }

    // Handle deep links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri.toString());
      }
    }, onError: (err) {
      // Handle deep link error silently
    });
  }

  void _handleDeepLink(String link) {
    // Parse the deep link
    if (link.startsWith('hinduconnect://biography/')) {
      final biographyId = link.replaceFirst('hinduconnect://biography/', '');
      _navigateToBiography(biographyId);
      return;
    }
    // TODO: extend to other content types as needed (stotra, temple, video)
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hindu Connect',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/ad-splash': (context) => const AdSplashScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _route();
    });
  }

  Future<void> _route() async {
    try {
      if (_authService.isLoggedIn) {
        final isProfileComplete = await _authService.isUserProfileComplete();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, isProfileComplete ? '/ad-splash' : '/profile-setup');
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Flutter splash UI matching brand
    return const _BrandedSplash();
  }
}

class _BrandedSplash extends StatefulWidget {
  const _BrandedSplash();

  @override
  State<_BrandedSplash> createState() => _BrandedSplashState();
}

class _BrandedSplashState extends State<_BrandedSplash> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6600),
      body: SafeArea(
        child: Stack(
          children: [
            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  // Logo
                  _Logo(),
                  SizedBox(height: 16),
                  // App name
                  Text(
                    'Hindu Connect',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Tag line
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'World 1st Complete Devotional Mobile App',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Loading indicator for Android 10 compatibility
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom line
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: const Text(
                'connecting hearts with Devotion.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/app_logo.png',
      width: 120,
      height: 120,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to text if image fails to load (common on Android 10)
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_stories,
            size: 60,
            color: Color(0xFFFF6600),
          ),
        );
      },
    );
  }
}
