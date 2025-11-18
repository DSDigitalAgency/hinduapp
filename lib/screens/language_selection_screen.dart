import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';
import '../providers/language_provider.dart';
import '../constants/app_theme.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String? _selectedLanguage;
  String? _selectedLanguageCode;
  bool _isLoading = false;

  // List of all supported languages
  static const List<Map<String, String>> _languages = [
    {'name': 'Assamese', 'code': 'as'},
    {'name': 'Bengali (Bangla)', 'code': 'bn'},
    {'name': 'Devanagari (Hindi)', 'code': 'hi'},
    {'name': 'Gujarati', 'code': 'gu'},
    {'name': 'Kannada', 'code': 'kn'},
    {'name': 'Malayalam', 'code': 'ml'},
    {'name': 'Oriya (Odia)', 'code': 'or'},
    {'name': 'Punjabi (Gurmukhi)', 'code': 'pa'},
    {'name': 'Roman itrans (English)', 'code': 'en'},
    {'name': 'Tamil', 'code': 'ta'},
    {'name': 'Telugu', 'code': 'te'},
    {'name': 'Urdu', 'code': 'ur'},
    {'name': 'Arabic', 'code': 'ar'},
    {'name': 'Avestan', 'code': 'ae'},
    {'name': 'Bhaiksuki', 'code': 'hi'},
    {'name': 'Brahmi', 'code': 'hi'},
    {'name': 'Burmese (Myanmar)', 'code': 'my'},
    {'name': 'Cyrillic (Russian)', 'code': 'ru'},
    {'name': 'Grantha', 'code': 'hi'},
    {'name': 'Hebrew', 'code': 'he'},
    {'name': 'Hebrew (Judeo-Arabic)', 'code': 'he'},
    {'name': 'Imperial Aramaic', 'code': 'ar'},
    {'name': 'Japanese (Hiragana)', 'code': 'ja-hira'},
    {'name': 'Japanese (Katakana)', 'code': 'ja-kata'},
    {'name': 'Javanese', 'code': 'jv'},
    {'name': 'Kharoshthi', 'code': 'hi'},
    {'name': 'Khmer (Cambodian)', 'code': 'km'},
    {'name': 'Lao', 'code': 'lo'},
    {'name': 'Meetei Mayek (Manipuri)', 'code': 'mni'},
    {'name': 'Mongolian', 'code': 'mn'},
    {'name': 'Newa (Nepal Bhasa)', 'code': 'new'},
    {'name': 'Old Persian', 'code': 'peo'},
    {'name': 'Old South Arabian', 'code': 'ar'},
    {'name': 'Persian', 'code': 'fa'},
    {'name': 'Phoenician', 'code': 'ar'},
    {'name': 'Psalter Pahlavi', 'code': 'fa'},
    {'name': 'Ranjana (Lantsa)', 'code': 'ranj'},
    {'name': 'Samaritan', 'code': 'he'},
    {'name': 'Santali (Ol Chiki)', 'code': 'sat'},
    {'name': 'Sharada', 'code': 'hi'},
    {'name': 'Siddham', 'code': 'hi'},
    {'name': 'Sinhala', 'code': 'si'},
    {'name': 'Sogdian', 'code': 'fa'},
    {'name': 'Soyombo', 'code': 'hi'},
    {'name': 'Syriac (Eastern)', 'code': 'ar'},
    {'name': 'Syriac (Estrangela)', 'code': 'ar'},
    {'name': 'Syriac (Western)', 'code': 'ar'},
    {'name': 'Tamil Brahmi', 'code': 'ta'},
    {'name': 'Thaana (Dhivehi)', 'code': 'dv'},
    {'name': 'Thai', 'code': 'th'},
    {'name': 'Tibetan', 'code': 'bo'},
  ];

  @override
  void initState() {
    super.initState();
    // Load the currently selected language if available
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      // Try to get the current language from storage
      final currentLanguage = await LocalStorageService.getUserPreferredLanguageName();
      
      // Handle legacy "English" name - convert to "Roman itrans (English)"
      String? languageToUse = currentLanguage;
      if (currentLanguage == 'English') {
        languageToUse = 'Roman itrans (English)';
        // Fix the stored value
        await LocalStorageService.saveUserLanguagePreference('Roman itrans (English)', 'en');
      }
      
      // Check if the language exists in our list
      if (languageToUse != null) {
        final languageExists = _languages.any((lang) => lang['name'] == languageToUse);
        if (languageExists) {
          final language = _languages.firstWhere((lang) => lang['name'] == languageToUse);
          if (mounted) {
            setState(() {
              _selectedLanguage = language['name'];
              _selectedLanguageCode = language['code'];
            });
            return;
          }
        }
      }
      
      // Default to Devanagari (Hindi) if no language found or language doesn't exist
      if (mounted) {
        setState(() {
          _selectedLanguage = 'Devanagari (Hindi)';
          _selectedLanguageCode = 'hi';
        });
      }
    } catch (e) {
      // On error, default to Devanagari (Hindi)
      if (mounted) {
        setState(() {
          _selectedLanguage = 'Devanagari (Hindi)';
          _selectedLanguageCode = 'hi';
        });
      }
    }
  }

  Future<void> _saveLanguageAndContinue() async {
    if (_selectedLanguage == null || _selectedLanguageCode == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save language preference
      await LocalStorageService.saveUserLanguagePreference(
        _selectedLanguage!,
        _selectedLanguageCode!,
      );

      // Update language provider
      await ref.read(languageProvider.notifier).updateLanguage(_selectedLanguage!);

      // Mark that language has been selected (not first launch anymore)
      await LocalStorageService.setLanguageSelected(true);

      if (mounted) {
        // Navigate to ad splash screen
        Navigator.of(context).pushReplacementNamed('/ad-splash');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving language: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCreamColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXXL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Logo
                  Image.asset(
                    'assets/app_logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_stories,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  const Text(
                    'Welcome to Hindu Connect',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  const Text(
                    'Please select your preferred language',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Language List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final language = _languages[index];
                  final isSelected = language['name'] == _selectedLanguage;

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                        vertical: AppTheme.spacingS,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : AppTheme.lightGrayColor,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                        ),
                        child: Icon(
                          Icons.language,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                      title: Text(
                        language['name']!,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimaryColor,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedLanguage = language['name'];
                          _selectedLanguageCode = language['code'];
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            // Continue Button
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveLanguageAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

