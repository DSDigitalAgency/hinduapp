import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clipboard/clipboard.dart';
import 'package:hindu_connect/services/logger_service.dart';

/// Service to handle deferred deep linking
/// - Android: Uses Play Store Install Referrer API
/// - iOS: Uses Clipboard method
class DeferredDeepLinkService {
  static const String _firstRunKey = 'isFirstRun';
  static const String _deferredLinkProcessedKey = 'deferredLinkProcessed';
  static const String _clipboardPrefix = 'hindu_connect_';

  /// Check for deferred deep link data (only on first app launch)
  /// Returns the content ID if found, null otherwise
  static Future<String?> checkDeferredDeepLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if this is the first run
      final isFirstRun = prefs.getBool(_firstRunKey) ?? true;
      if (!isFirstRun) {
        logger.debug('Not first run, skipping deferred deep link check');
        return null;
      }

      // Check if we already processed a deferred link
      final alreadyProcessed = prefs.getBool(_deferredLinkProcessedKey) ?? false;
      if (alreadyProcessed) {
        logger.debug('Deferred link already processed, skipping');
        return null;
      }

      String? contentId;
      String? contentType;

      if (Platform.isAndroid) {
        // --- ANDROID STRATEGY: Play Store Install Referrer via Platform Channel ---
        try {
          const platform = MethodChannel('com.dikonda.hinduconnect/install_referrer');
          final String? referrer = await platform.invokeMethod('getInstallReferrer');
          
          if (referrer != null && referrer.isNotEmpty) {
            logger.debug('Android install referrer found: $referrer');
            
            // Parse the referrer string
            // Format: "type:contentId" or just "contentId"
            if (referrer.contains(':')) {
              final parts = referrer.split(':');
              if (parts.length >= 2) {
                contentType = parts[0];
                contentId = parts[1];
              }
            } else {
              // Just content ID, default to 'post' type
              contentType = 'post';
              contentId = referrer;
            }
          }
        } catch (e) {
          logger.error('Error reading Android install referrer: $e');
        }
      } else if (Platform.isIOS) {
        // --- iOS STRATEGY: Clipboard Copy ---
        try {
          final clipText = await FlutterClipboard.paste();
          
          if (clipText != null && clipText.isNotEmpty) {
            logger.debug('iOS clipboard content: $clipText');
            
            // Check if clipboard contains our prefix
            if (clipText.startsWith(_clipboardPrefix)) {
              // Format: "hindu_connect_type:contentId" or "hindu_connect_contentId"
              final data = clipText.substring(_clipboardPrefix.length);
              
              if (data.contains(':')) {
                final parts = data.split(':');
                if (parts.length >= 2) {
                  contentType = parts[0];
                  contentId = parts[1];
                }
              } else {
                // Just content ID, default to 'post' type
                contentType = 'post';
                contentId = data;
              }
              
              // Clear clipboard after reading
              await FlutterClipboard.copy('');
              logger.debug('Cleared clipboard after reading deferred link');
            }
          }
        } catch (e) {
          logger.error('Error reading iOS clipboard: $e');
        }
      }

      // --- IF WE FOUND DATA ---
      if (contentId != null && contentId.isNotEmpty) {
        logger.debug('Found deferred deep link - Type: $contentType, ID: $contentId');
        
        // Mark as processed so we don't check again
        await prefs.setBool(_deferredLinkProcessedKey, true);
        
        // Store the deferred link data for later use
        await prefs.setString('deferredLinkType', contentType ?? 'post');
        await prefs.setString('deferredLinkId', contentId);
        
        return contentId;
      }

      // Mark first run as done (even if no deferred link found)
      await prefs.setBool(_firstRunKey, false);
      
      return null;
    } catch (e) {
      logger.error('Error in checkDeferredDeepLink: $e');
      return null;
    }
  }

  /// Get the deferred link data (type and ID) if available
  static Future<Map<String, String>?> getDeferredLinkData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final type = prefs.getString('deferredLinkType');
      final id = prefs.getString('deferredLinkId');
      
      if (type != null && id != null) {
        return {'type': type, 'id': id};
      }
      return null;
    } catch (e) {
      logger.error('Error getting deferred link data: $e');
      return null;
    }
  }

  /// Clear deferred link data after it's been used
  static Future<void> clearDeferredLinkData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('deferredLinkType');
      await prefs.remove('deferredLinkId');
      await prefs.setBool(_deferredLinkProcessedKey, true);
    } catch (e) {
      logger.error('Error clearing deferred link data: $e');
    }
  }

  /// Check if this is the first app run
  static Future<bool> isFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_firstRunKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Mark first run as complete
  static Future<void> markFirstRunComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstRunKey, false);
    } catch (e) {
      logger.error('Error marking first run complete: $e');
    }
  }
}

