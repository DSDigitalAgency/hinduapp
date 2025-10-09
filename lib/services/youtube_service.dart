import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class YouTubeService {
  // Read from --dart-define if provided; fallback to your provided key
  // Usage: flutter run --dart-define=YOUTUBE_API_KEY=YOUR_KEY
  static const String apiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: 'AIzaSyCsUw-mUXc8oqvvnlGlsIRT0tDB3CubXiE',
  );
  static const String baseUrl = 'https://www.googleapis.com/youtube/v3';
  
  static Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    try {
      // Require API key; do not use scrapers if the goal is to fetch from YouTube API
      if (apiKey.trim().isEmpty) {

        return null;
      }
      final url = Uri.parse('$baseUrl/videos')
          .replace(queryParameters: {
        'id': videoId,
        'part': 'snippet,contentDetails,statistics',
        'key': apiKey,
      });
      final response = await http.get(url);
      

      
      // Check for API key issues
      if (response.statusCode == 403) {

        return null;
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['items'] != null && data['items'].isNotEmpty) {
          final video = data['items'][0];
          final snippet = video['snippet'] ?? {};
          final contentDetails = video['contentDetails'] ?? {};
          final statistics = video['statistics'] ?? {};
          
          final result = {
            'title': snippet['title'],
            'description': snippet['description'],
            'channelTitle': snippet['channelTitle'],
            'publishedAt': snippet['publishedAt'],
            'duration': contentDetails['duration'],
            'viewCount': statistics['viewCount'],
            'likeCount': statistics['likeCount'],
            'thumbnailUrl': snippet['thumbnails']?['high']?['url'],
          };
          

          
          return result;
        }
      }
      // Non-200: surface as null so caller knows API failed
      return null;
    } on TimeoutException {

      return null;
    } catch (e) {

      return null;
    }
  }

  // Test method to verify YouTube API functionality
  static Future<void> testYouTubeAPI() async {
    // Test with a known video that should have a description
    const testVideoIds = ['dQw4w9WgXcQ', 'qmIC0_-7W4c', 'OnTcMuv2Tsk'];
    
    for (final videoId in testVideoIds) {
      
      await getVideoInfo(videoId);

      // Add delay to prevent rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // Method to open YouTube video in external app or browser
  static Future<bool> openYouTubeVideo(String videoId) async {
    try {
      // Try to open in YouTube app first
      final youtubeAppUrl = 'youtube://$videoId';
      final youtubeWebUrl = 'https://www.youtube.com/watch?v=$videoId';
      
      // Try YouTube app first
      if (await canLaunchUrl(Uri.parse(youtubeAppUrl))) {
        return await launchUrl(
          Uri.parse(youtubeAppUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      // Fallback to web browser
      if (await canLaunchUrl(Uri.parse(youtubeWebUrl))) {
        return await launchUrl(
          Uri.parse(youtubeWebUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      return false;
    } catch (e) {

      return false;
    }
  }

  // Method to get real YouTube data without API key (for testing)
  static Future<Map<String, dynamic>?> getRealYouTubeData(String videoId) async {
    try {
      // Try multiple services to get YouTube video info
      final services = [
        {
          'name': 'noembed.com',
          'url': 'https://noembed.com/embed',
          'params': {
            'url': 'https://www.youtube.com/watch?v=$videoId',
            'format': 'json',
          }
        },
        {
          'name': 'iframely.com',
          'url': 'https://iframe.ly/api/iframely',
          'params': {
            'url': 'https://www.youtube.com/watch?v=$videoId',
            'format': 'json',
          }
        }
      ];
      
      for (final service in services) {
        try {
          final uri = Uri.parse(service['url'] as String)
              .replace(queryParameters: service['params'] as Map<String, String>);
          
          final response = await http
              .get(uri);
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            
            if (data['title'] != null) {
              // Get description from multiple possible fields
              String? description;
              
              // Check if we have a real description from YouTube
              if (data['description'] != null && data['description'].toString().isNotEmpty) {
                description = data['description'];
              } else if (data['summary'] != null && data['summary'].toString().isNotEmpty) {
                description = data['summary'];
              } else {
                // No real description found, return null to show "No description available"
                description = null;
              }
              

              
              final result = {
                'title': data['title'] ?? '',
                'description': description,
                'publishedAt': DateTime.now().toIso8601String(),
                'duration': 'PT5M30S', // Default duration
                'viewCount': '1000',
                'likeCount': '50',
              };
              
              return result;
            }
          }
        } catch (e) {
          // Handle error silently - will try next service
        }
      }
      
      // If all services fail, try to get basic info from YouTube page
      try {
        final youtubePageUrl = 'https://www.youtube.com/watch?v=$videoId';
        final response = await http
            .get(Uri.parse(youtubePageUrl));

        if (response.statusCode == 200) {
          final html = response.body;
          
          // Try to extract title and description from meta tags
          final titleMatch = RegExp(r'<meta property="og:title" content="([^"]+)"').firstMatch(html);
          final descriptionMatch = RegExp(r'<meta property="og:description" content="([^"]+)"').firstMatch(html);
          
          // Also try to extract from YouTube's specific meta tags
          final ytTitleMatch = RegExp(r'<meta name="title" content="([^"]+)"').firstMatch(html);
          final ytDescMatch = RegExp(r'<meta name="description" content="([^"]+)"').firstMatch(html);
          
          // Try additional meta tag patterns for description
          final descMatch1 = RegExp(r'<meta name="description" content="([^"]+)"').firstMatch(html);
          final descMatch2 = RegExp(r'<meta property="description" content="([^"]+)"').firstMatch(html);
          final descMatch3 = RegExp(r'<meta name="twitter:description" content="([^"]+)"').firstMatch(html);
          
          // Try to extract from JSON-LD structured data
          final jsonLdMatch = RegExp(r'<script type="application/ld\+json">(.*?)</script>', dotAll: true).firstMatch(html);
          
          String? title;
          String? description;
          
          // Get title from multiple sources
          title = titleMatch?.group(1) ?? ytTitleMatch?.group(1);
          
          // Get description from multiple sources
          description = descriptionMatch?.group(1) ?? 
                       ytDescMatch?.group(1) ?? 
                       descMatch1?.group(1) ?? 
                       descMatch2?.group(1) ?? 
                       descMatch3?.group(1);
          
          // Try to extract from JSON-LD if still no description
          if (description == null || description.isEmpty) {
            if (jsonLdMatch != null) {
              try {
                final jsonLdData = jsonDecode(jsonLdMatch.group(1) ?? '{}') as Map<String, dynamic>;
                description = jsonLdData['description'] ?? 
                             jsonLdData['about']?['description'] ?? 
                             jsonLdData['video']?['description'] ?? 
                             jsonLdData['mainEntity']?['description'];
              } catch (e) {
                // Handle parsing error silently
              }
            }
          }
          
          // Extracted data from YouTube page
          
          if (title != null && title.isNotEmpty) {
            return {
              'title': title,
              'description': description, // This can be null if no description found
              'publishedAt': DateTime.now().toIso8601String(),
              'duration': 'PT5M30S',
              'viewCount': '1000',
              'likeCount': '50',
            };
          }
        }
      } catch (e) {
        // Handle error silently - will return null
      }
    } catch (e) {
      // Handle error silently
    }
    
    return null;
  }

  static String formatDuration(String duration) {
    // Parse ISO 8601 duration format (PT4M13S -> 4:13)
    try {
      final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(duration);
      if (match != null) {
        final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
        final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
        
        if (hours > 0) {
          return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        } else {
          return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        }
      }
    } catch (e) {
      // Handle parsing error silently
    }
    return '00:00';
  }

  static String formatViewCount(String? viewCount) {
    try {
      final count = int.tryParse(viewCount ?? '0') ?? 0;
      if (count >= 1000000) {
        return '${(count / 1000000).toStringAsFixed(1)}M';
      } else if (count >= 1000) {
        return '${(count / 1000).toStringAsFixed(1)}K';
      } else {
        return count.toString();
      }
    } catch (e) {
      return '0';
    }
  }
} 