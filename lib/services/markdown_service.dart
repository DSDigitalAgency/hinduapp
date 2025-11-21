import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'font_service.dart';

/// Service for handling markdown content processing consistently across the app
class MarkdownService {
  /// Clean markdown content by removing formatting tags
  static String cleanMarkdown(String content) {
    if (content.isEmpty) return 'No content available';
    
    return content
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1') // Remove bold
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'\1') // Remove italic
        .replaceAll(RegExp(r'__([^_]+)__'), r'\1') // Remove underline
        .replaceAll(RegExp(r'#+\s*'), '') // Remove headers
        .replaceAll(RegExp(r'<mark>([^<]+)</mark>'), r'\1') // Remove mark tags
        .replaceAll('<br/>', '\n') // Convert HTML line breaks
        .replaceAll('<br>', '\n')
        .replaceAll('</br>', '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove any remaining HTML tags
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Clean up multiple newlines
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Limit consecutive newlines to max 2
        .trim();
  }

  /// Prepare markdown content for rendering (preserves formatting)
  static String prepareMarkdownForRendering(String content) {
    if (content.isEmpty) return 'No content available';
    
    return content
        .replaceAll('<br/>', '\n\n') // Convert HTML line breaks to double newlines for proper spacing
        .replaceAll('<br>', '\n\n')
        .replaceAll('</br>', '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags but keep markdown
        .replaceAll(RegExp(r'~~([^~]+)~~'), r'\1') // Remove strikethrough markdown (~~text~~)
        .replaceAll(RegExp(r'<del>([^<]+)</del>'), r'\1') // Remove HTML strikethrough tags
        .replaceAll(RegExp(r'<s>([^<]+)</s>'), r'\1') // Remove HTML strikethrough tags
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Clean up multiple newlines
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Limit consecutive newlines to max 2
        .trim();
  }

  /// Create a preview of content (first N characters)
  static String createPreview(String content, {int maxLength = 150}) {
    if (content.isEmpty) return 'No content available';
    
    final cleaned = cleanMarkdown(content);
    if (cleaned.length <= maxLength) return cleaned;
    
    return '${cleaned.substring(0, maxLength)}...';
  }

  /// Check if content contains markdown formatting
  static bool hasMarkdownFormatting(String content) {
    if (content.isEmpty) return false;
    
    return content.contains('**') || 
           content.contains('*') || 
           content.contains('__') || 
           content.contains('#') || 
           content.contains('<mark>') ||
           content.contains('<br') ||
           RegExp(r'<[^>]*>').hasMatch(content);
  }

  /// Get appropriate text style for markdown content
  static TextStyle getMarkdownTextStyle({
    double? fontSize,
    Color? color,
    double? height,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      fontSize: fontSize ?? 16.0,
      color: color ?? Colors.black87,
      height: height ?? 1.5,
      fontWeight: fontWeight ?? FontWeight.normal,
    );
  }

  /// Create a markdown style sheet for consistent rendering
  static MarkdownStyleSheet createMarkdownStyleSheet({
    required double baseFontSize,
    required Color textColor,
    required double lineHeight,
    String? currentLanguage,
  }) {
    // Use FontService to get the proper font for the language
    final baseStyle = FontService.getTextStyleForLanguage(
      currentLanguage ?? 'Devanagari',
      fontSize: baseFontSize,
      color: textColor,
      height: lineHeight,
    );

    return MarkdownStyleSheet(
      p: baseStyle,
      h1: baseStyle.copyWith(
        fontSize: baseFontSize + 6,
        fontWeight: FontWeight.bold,
      ),
      h2: baseStyle.copyWith(
        fontSize: baseFontSize + 4,
        fontWeight: FontWeight.bold,
      ),
      h3: baseStyle.copyWith(
        fontSize: baseFontSize + 2,
        fontWeight: FontWeight.bold,
      ),
      strong: baseStyle.copyWith(
        fontWeight: FontWeight.bold,
      ),
      em: baseStyle.copyWith(
        fontStyle: FontStyle.italic,
      ),
      blockquote: baseStyle.copyWith(
        fontStyle: FontStyle.italic,
      ),
      code: baseStyle.copyWith(
        fontSize: baseFontSize - 2,
        fontFamily: 'monospace',
      ),
      listBullet: baseStyle,
      // Remove strikethrough decoration for del (strikethrough) elements
      del: baseStyle.copyWith(
        decoration: TextDecoration.none, // Remove strikethrough
      ),
    );
  }
}
