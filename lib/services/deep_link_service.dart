import 'package:url_launcher/url_launcher.dart';

/// Service for generating and handling deep links
class DeepLinkService {
  // Base domain for universal links (you'll need to configure this)
  // For now, using a placeholder - replace with your actual domain
  static const String baseDomain = 'https://hinduconnect.app';
  
  // App Store URLs
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.dikonda.hinduconnect';
  static const String appStoreUrl = 'https://apps.apple.com/app/id6753724071';
  
  /// Generate a deep link for sacred text
  static String generateSacredTextLink(String sacredTextId) {
    // Custom scheme deep link (works when app is installed)
    final encodedId = Uri.encodeComponent(sacredTextId);
    return 'hinduconnect://sacredtext/$encodedId';
  }
  
  /// Generate a universal link for sacred text (HTTPS)
  static String generateSacredTextUniversalLink(String sacredTextId) {
    final encodedId = Uri.encodeComponent(sacredTextId);
    return '$baseDomain/sacredtext/$encodedId';
  }
  
  /// Generate a deep link for temple
  static String generateTempleLink(String templeId) {
    final encodedId = Uri.encodeComponent(templeId);
    return 'hinduconnect://temple/$encodedId';
  }
  
  /// Generate a universal link for temple (HTTPS)
  static String generateTempleUniversalLink(String templeId) {
    final encodedId = Uri.encodeComponent(templeId);
    return '$baseDomain/temple/$encodedId';
  }
  
  /// Generate a deep link for biography
  static String generateBiographyLink(String biographyId) {
    final encodedId = Uri.encodeComponent(biographyId);
    return 'hinduconnect://biography/$encodedId';
  }
  
  /// Generate a universal link for biography (HTTPS)
  static String generateBiographyUniversalLink(String biographyId) {
    final encodedId = Uri.encodeComponent(biographyId);
    return '$baseDomain/biography/$encodedId';
  }
  
  /// Generate a deep link for post
  static String generatePostLink(String postId) {
    final encodedId = Uri.encodeComponent(postId);
    return 'hinduconnect://post/$encodedId';
  }
  
  /// Generate a universal link for post (HTTPS)
  static String generatePostUniversalLink(String postId) {
    final encodedId = Uri.encodeComponent(postId);
    return '$baseDomain/post/$encodedId';
  }
  
  /// Generate a shareable link using deferred deep link method
  /// This works for both installed and non-installed cases:
  /// - If app installed: Opens app directly
  /// - If app not installed: Redirects to Play Store/App Store with referrer/clipboard
  static String generateShareableLink({
    required String type, // 'sacredtext', 'temple', 'biography', 'post'
    required String id,
  }) {
    // Always use deferred deep link method (share.html)
    final encodedType = Uri.encodeComponent(type);
    final encodedId = Uri.encodeComponent(id);
    return '$baseDomain/share.html?type=$encodedType&id=$encodedId';
  }
  
  /// Generate a deferred deep link URL (alias for generateShareableLink)
  /// This uses the share.html page which handles Play Store referrer (Android) and clipboard (iOS)
  static String generateDeferredDeepLink({
    required String type,
    required String id,
  }) {
    return generateShareableLink(type: type, id: id);
  }
  
  /// Generate share text with deep link
  static String generateShareText({
    required String preview,
    required String type,
    required String id,
    String? title,
  }) {
    final link = generateShareableLink(type: type, id: id);
    final titleText = title != null ? '$title\n\n' : '';
    
    return '''
$titleText$preview

🔗 Open in Hindu Connect App:
$link
''';
  }
  
  /// Launch a deep link (tries custom scheme first, then universal link)
  static Future<bool> launchDeepLink(String link) async {
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Open app store based on platform
  static Future<void> openAppStore() async {
    try {
      // For Android, open Play Store
      // For iOS, open App Store
      // You can detect platform and open appropriate store
      final uri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}

