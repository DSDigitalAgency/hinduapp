import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Unused
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/pincode_service.dart';
import '../models/user_model.dart';
import '../constants/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPincodeValidating = false;
  String? _city;
  String? _state;
  String? _pincodeError;
  String _selectedLanguage = 'Devanagari (Hindi)';
  String _selectedLanguageCode = 'hi';
  
  // List of all supported languages (same order as profile screen)
  static const List<Map<String, String>> _languages = [
    {'name': 'Assamese', 'code': 'as'},
    {'name': 'Bengali (Bangla)', 'code': 'bn'},
    {'name': 'Devanagari (Hindi)', 'code': 'hi'},
    {'name': 'Gujarati', 'code': 'gu'},
    {'name': 'Kannada', 'code': 'kn'},
    {'name': 'Malayalam', 'code': 'ml'},
    {'name': 'Oriya (Odia)', 'code': 'or'},
    {'name': 'Punjabi (Gurmukhi)', 'code': 'pa'},
    {'name': 'itrans (English)', 'code': 'en'},
    {'name': 'Tamil', 'code': 'ta'},
    {'name': 'Telugu', 'code': 'te'},
    {'name': 'Urdu', 'code': 'ur'},
    {'name': 'Arabic', 'code': 'ar'},
    {'name': 'Avestan', 'code': 'ae'},
    {'name': 'Bhaiksuki', 'code': 'bhks'},
    {'name': 'Brahmi', 'code': 'brah'},
    {'name': 'Burmese (Myanmar)', 'code': 'my'},
    {'name': 'Cyrillic (Russian)', 'code': 'ru'},
    {'name': 'Grantha', 'code': 'gran'},
    {'name': 'Hebrew', 'code': 'he'},
    {'name': 'Hebrew (Judeo-Arabic)', 'code': 'he-arab'},
    {'name': 'Imperial Aramaic', 'code': 'arc'},
    {'name': 'Japanese (Hiragana)', 'code': 'ja-hira'},
    {'name': 'Japanese (Katakana)', 'code': 'ja-kata'},
    {'name': 'Javanese', 'code': 'jv'},
    {'name': 'Kharoshthi', 'code': 'khar'},
    {'name': 'Khmer (Cambodian)', 'code': 'km'},
    {'name': 'Lao', 'code': 'lo'},
    {'name': 'Meetei Mayek (Manipuri)', 'code': 'mni'},
    {'name': 'Mongolian', 'code': 'mn'},
    {'name': 'Newa (Nepal Bhasa)', 'code': 'new'},
    {'name': 'Old Persian', 'code': 'peo'},
    {'name': 'Old South Arabian', 'code': 'sarb'},
    {'name': 'Persian', 'code': 'fa'},
    {'name': 'Phoenician', 'code': 'phn'},
    {'name': 'Psalter Pahlavi', 'code': 'phlp'},
    {'name': 'Ranjana (Lantsa)', 'code': 'ranj'},
    {'name': 'Samaritan', 'code': 'sam'},
    {'name': 'Santali (Ol Chiki)', 'code': 'sat'},
    {'name': 'Sharada', 'code': 'shrd'},
    {'name': 'Siddham', 'code': 'sidd'},
    {'name': 'Sinhala', 'code': 'si'},
    {'name': 'Sogdian', 'code': 'sog'},
    {'name': 'Soyombo', 'code': 'soyo'},
    {'name': 'Syriac (Eastern)', 'code': 'syr-east'},
    {'name': 'Syriac (Estrangela)', 'code': 'syr-estr'},
    {'name': 'Syriac (Western)', 'code': 'syr-west'},
    {'name': 'Tamil Brahmi', 'code': 'tamb'},
    {'name': 'Thaana (Dhivehi)', 'code': 'dv'},
    {'name': 'Thai', 'code': 'th'},
    {'name': 'Tibetan', 'code': 'bo'},
  ];
  
  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }
  
  void _prefillUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      // Pre-fill name if available from Google/Apple sign in
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      }
    }
  }
  
  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Your Preferred Language'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = language['name'] == _selectedLanguage;
                
                return ListTile(
                  title: Text(
                    language['name']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : Colors.black,
                    ),
                  ),
                                      trailing: isSelected 
                    ? const Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                      )
                    : null,
                                     onTap: () {
                     setDialogState(() {
                       _selectedLanguage = language['name']!;
                       _selectedLanguageCode = language['code']!;
                     });
                     setState(() {
                       _selectedLanguage = language['name']!;
                       _selectedLanguageCode = language['code']!;
                     });
                     Navigator.pop(context);
                   },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _validatePincode(String pincode) async {
    if (pincode.length != 6) {
      setState(() {
        _pincodeError = 'Pincode must be 6 digits';
        _city = null;
        _state = null;
      });
      return;
    }
    
    setState(() {
      _isPincodeValidating = true;
      _pincodeError = null;
    });
    
    try {
      final pincodeInfo = await PincodeService.getPincodeInfo(pincode);
      
      if (pincodeInfo != null) {
        setState(() {
          _city = pincodeInfo.city;
          _state = pincodeInfo.state;
          _pincodeError = null;
        });
      } else {
        setState(() {
          _pincodeError = 'Invalid pincode';
          _city = null;
          _state = null;
        });
      }
    } catch (e) {
      setState(() {
        _pincodeError = 'Error validating pincode';
        _city = null;
        _state = null;
      });
    } finally {
      setState(() {
        _isPincodeValidating = false;
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_city == null || _state == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid pincode'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('No user found');
      }
      
      // Create updated user model
      final updatedUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        pincode: _pincodeController.text.trim(),
        city: _city,
        state: _state,
        language: _selectedLanguage,
        languageCode: _selectedLanguageCode,
        createdAt: DateTime.now(),
        lastSignIn: DateTime.now(),
      );
      
      // Save to Firestore
      await FirestoreService.createOrUpdateUser(updatedUser);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // Error saving profile: $e
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
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
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingXXL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                const Text(
                  'Welcome to HinduConnect!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                const Text(
                  'Please complete your profile to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXXL),
                
                // Name field
                const Text(
                  'Full Name *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingXXL),
                
                // Phone number field
                const Text(
                  'Phone Number *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingXXL),
                
                // Pincode field
                const Text(
                  'Pincode *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter your pincode',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                    suffixIcon: _isPincodeValidating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            ),
                          )
                        : null,
                    errorText: _pincodeError,
                  ),
                  onChanged: (value) {
                    if (value.length == 6) {
                      _validatePincode(value);
                    } else {
                      setState(() {
                        _pincodeError = null;
                        _city = null;
                        _state = null;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your pincode';
                    }
                    if (value.length != 6) {
                      return 'Pincode must be 6 digits';
                    }
                    if (_pincodeError != null) {
                      return _pincodeError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // City and State display
                if (_city != null && _state != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location Detected:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_city, $_state',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Language selection
                const Text(
                  'Preferred Language *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showLanguageSelectionDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedLanguage,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Email display (read-only)
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _authService.currentUser?.email ?? 'No email available',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                      ),
                      elevation: 0,
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
                            'Complete Setup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 