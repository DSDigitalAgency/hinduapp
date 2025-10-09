import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

/// Reading settings state class
class ReadingSettings {
  final double textSize;
  final Color backgroundColor;
  final double textSpacing;

  const ReadingSettings({
    required this.textSize,
    required this.backgroundColor,
    required this.textSpacing,
  });

  ReadingSettings copyWith({
    double? textSize,
    Color? backgroundColor,
    double? textSpacing,
  }) {
    return ReadingSettings(
      textSize: textSize ?? this.textSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textSpacing: textSpacing ?? this.textSpacing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'textSize': textSize,
      'backgroundColor': backgroundColor.toARGB32(),
      'textSpacing': textSpacing,
    };
  }

  static ReadingSettings fromMap(Map<String, dynamic> map) {
    return ReadingSettings(
      textSize: (map['textSize'] ?? 16.0).toDouble(),
      backgroundColor: map['backgroundColor'] != null 
          ? Color(map['backgroundColor'] as int)
          : Colors.white,
      textSpacing: (map['textSpacing'] ?? 1.6).toDouble(),
    );
  }

  static const ReadingSettings defaultSettings = ReadingSettings(
    textSize: 16.0,
    backgroundColor: Colors.white,
    textSpacing: 1.6,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingSettings &&
        other.textSize == textSize &&
        other.backgroundColor == backgroundColor &&
        other.textSpacing == textSpacing;
  }

  @override
  int get hashCode {
    return textSize.hashCode ^ backgroundColor.hashCode ^ textSpacing.hashCode;
  }
}

/// Notifier for managing global reading settings
class ReadingSettingsNotifier extends StateNotifier<ReadingSettings> {
  static ReadingSettingsNotifier? _instance;
  
  ReadingSettingsNotifier._internal() : super(ReadingSettings.defaultSettings) {
    // Don't load settings in constructor - let initializeSettings() handle it
  }
  
  factory ReadingSettingsNotifier() {
    _instance ??= ReadingSettingsNotifier._internal();
    return _instance!;
  }

  /// Load settings from local storage
  Future<void> _loadSettings() async {
    try {
      final settingsMap = await LocalStorageService.loadGlobalReadingSettings();
      if (settingsMap != null && mounted) {
        state = ReadingSettings.fromMap(settingsMap);
      }
    } catch (e) {
      // Use default settings if loading fails
      if (mounted) {
        state = ReadingSettings.defaultSettings;
      }
    }
  }

  /// Initialize settings on app start
  Future<void> initializeSettings() async {
    await _loadSettings();
  }

  /// Force reload settings from storage
  Future<void> reloadSettings() async {
    await _loadSettings();
  }

  /// Update text size and save to storage
  Future<void> updateTextSize(double textSize) async {
    if (state.textSize != textSize) {
      final newSettings = state.copyWith(textSize: textSize);
      state = newSettings;
      await _saveSettings();
    }
  }

  /// Update background color and save to storage
  Future<void> updateBackgroundColor(Color backgroundColor) async {
    if (state.backgroundColor != backgroundColor) {
      final newSettings = state.copyWith(backgroundColor: backgroundColor);
      state = newSettings;
      await _saveSettings();
    }
  }

  /// Update text spacing and save to storage
  Future<void> updateTextSpacing(double textSpacing) async {
    if (state.textSpacing != textSpacing) {
      final newSettings = state.copyWith(textSpacing: textSpacing);
      state = newSettings;
      await _saveSettings();
    }
  }

  /// Update all settings at once
  Future<void> updateAllSettings({
    required double textSize,
    required Color backgroundColor,
    required double textSpacing,
  }) async {
    final newSettings = ReadingSettings(
      textSize: textSize,
      backgroundColor: backgroundColor,
      textSpacing: textSpacing,
    );
    
    if (state != newSettings) {
      state = newSettings;
      await _saveSettings();
    }
  }

  /// Save current settings to local storage
  Future<void> _saveSettings() async {
    try {
      await LocalStorageService.saveGlobalReadingSettings(
        textSize: state.textSize,
        backgroundColor: state.backgroundColor,
        textSpacing: state.textSpacing,
      );
    } catch (e) {
      // Handle error silently for now
    }
  }

  /// Force refresh settings from storage
  Future<void> refreshSettings() async {
    await _loadSettings();
  }
}

/// Global reading settings provider
final readingSettingsProvider = StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings>(
  (ref) => ReadingSettingsNotifier(),
);

/// Individual providers for easy access to specific settings
final textSizeProvider = Provider<double>((ref) {
  return ref.watch(readingSettingsProvider).textSize;
});

final backgroundColorProvider = Provider<Color>((ref) {
  return ref.watch(readingSettingsProvider).backgroundColor;
});

final textSpacingProvider = Provider<double>((ref) {
  return ref.watch(readingSettingsProvider).textSpacing;
});
