import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/pincode_service.dart';
import '../services/language_conversion_service.dart';
import '../models/user_model.dart';
import '../providers/language_provider.dart';
import 'favorites_screen.dart';
import 'reading_history_screen.dart';
import 'web_view_screen.dart';
import '../services/local_storage_service.dart';
import '../constants/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  
  final AuthService _authService = AuthService();
  UserModel? _userData;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
              backgroundColor: AppTheme.warmCreamColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                      child: Column(
                        children: [
                          SizedBox(height: AppTheme.spacingL),
                          _buildUserDetailsSection(),
                          SizedBox(height: AppTheme.spacingXXL),
                          _buildMenuSection(),
                          _buildSignOutButton(),
                          SizedBox(height: AppTheme.spacingXXL),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        AppTheme.spacingL,
        AppTheme.spacingL,
        AppTheme.spacingM,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.warmCreamColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: AppTheme.textSizeXXXL,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: AppTheme.spacingXS),
              Text(
                'Manage your account settings',
                style: TextStyle(
                  fontSize: AppTheme.textSizeS,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_userData != null)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                  if (_isEditing) {
                    _showEditProfileDialog();
                  }
                },
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserDetailsSection() {
    final user = _authService.currentUser;
    final displayName = _userData?.name ?? user?.displayName ?? 'User';
    
    // Email handling - prioritize Firebase Auth email, then Firestore email
    String email = 'Email not available';
    
    // First try Firebase Auth email
    if (user?.email != null && user!.email!.isNotEmpty) {
      email = user.email!;
    } 
    // Then try Firestore email (but only if it's not empty)
    else if (_userData?.email != null && _userData!.email.isNotEmpty) {
      email = _userData!.email;
    }
    // If both are empty or null, show a helpful message
    else {
      email = 'Email not set';
    }
    
    final phone = _userData?.phone ?? 'Not provided';
    final bool hasLocation = (_userData?.city ?? '').isNotEmpty && (_userData?.state ?? '').isNotEmpty;
    final location = hasLocation ? '${_userData!.city}, ${_userData!.state}' : 'Location not set';
    final language = _userData?.language ?? 'Roman itrans (English)';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXL),
        boxShadow: [AppTheme.lightShadow],
      ),
      child: Column(
        children: [
          // User name at top, centered
          Text(
            displayName,
            style: const TextStyle(
              fontSize: AppTheme.textSizeXXXL,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppTheme.spacingXL),
          
          // Email
          _buildUserDetailItem(
            Icons.email_outlined,
            'Email',
            email,
          ),
          
          _buildDivider(),
          
          // Phone
          _buildUserDetailItem(
            Icons.phone_outlined,
            'Phone',
            phone,
          ),
          
          _buildDivider(),
          
          // Location
          _buildUserDetailItem(
            Icons.location_on_outlined,
            'Location',
            hasLocation ? location : 'Not set',
          ),
          
          _buildDivider(),
          
          // Selected Language
          _buildUserDetailItem(
            Icons.language_outlined,
            'Selected Language',
            language,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        // Main Menu Items
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusXL),
            boxShadow: [AppTheme.lightShadow],
          ),
          child: Column(
            children: [
              _buildMenuItem(
                Icons.bookmark_outline,
                'Favorites',
                'Your bookmarked scriptures and videos',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesScreen(),
                  ),
                ),
              ),
              _buildDivider(),
              _buildMenuItem(
                Icons.history_outlined,
                'Reading History',
                'Recently viewed content',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReadingHistoryScreen(),
                  ),
                ),
              ),
              _buildDivider(),
              _buildMenuItem(
                Icons.language_outlined,
                'Language',
                'Select your preferred language',
                () => _showLanguageSelectionDialog(),
              ),
            ],
          ),
        ),
        
        SizedBox(height: AppTheme.spacingXL),
        
        _buildSupportSection(),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      height: 1,
      color: AppTheme.lightGrayColor,
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXL),
        boxShadow: [AppTheme.lightShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              const Text(
                'Support & About',
                style: TextStyle(
                  fontSize: AppTheme.textSizeXL,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppTheme.spacingL),
          
          // Support Menu Items
          _buildSupportMenuItem(
            Icons.help_outline,
            'Help & FAQ',
            'Get help and find answers to common questions',
            () => _launchURL('https://hinduconnect.app/faq.html'),
          ),
          _buildDivider(),
          _buildSupportMenuItem(
            Icons.feedback_outlined,
            'Send Feedback',
            'Share your thoughts and suggestions',
            () => _showFeedbackDialog(),
          ),
          _buildDivider(),
          _buildSupportMenuItem(
            Icons.star_outline,
            'Rate App',
            'Rate Hindu Connect on Play Store',
            () => _rateApp(),
          ),
          _buildDivider(),
          _buildSupportMenuItem(
            Icons.info_outline,
            'About Hindu Connect',
            'Learn more about the app and its mission',
            () => _launchURL('https://hinduconnect.app/about.html'),
          ),
          _buildDivider(),
          _buildSupportMenuItem(
            Icons.favorite_outline,
            'Donate',
            'Support Hindu Connect and help us grow',
            () => _launchURL('https://hinduconnect.app/donate'),
          ),
          _buildDivider(),
          _buildSupportMenuItem(
            Icons.privacy_tip_outlined,
            'Privacy Policy',
            'Read our privacy policy and terms',
            () => _launchURL('https://hinduconnect.app/privacy.html'),
          ),
          _buildDivider(),
          _buildSupportMenuItem(
            Icons.description_outlined,
            'Terms & Conditions',
            'Read our terms and conditions',
            () => _launchURL('https://hinduconnect.app/terms.html'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingM,
          horizontal: AppTheme.spacingS,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: AppTheme.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppTheme.textSizeM,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTheme.textSizeS,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetailItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingM,
        horizontal: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.textSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacingXS),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTheme.textSizeS,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingM,
          horizontal: AppTheme.spacingS,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: AppTheme.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppTheme.textSizeL,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTheme.textSizeS,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingXL),
      child: ElevatedButton.icon(
        onPressed: _showSignOutDialog,
        icon: const Icon(Icons.logout_outlined),
        label: const Text('Sign Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingL,
            horizontal: AppTheme.spacingXL,
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    // Prioritize Firebase Auth email over Firestore email if Firestore email is empty
    final userName = _userData?.name ?? _authService.currentUser?.displayName ?? '';
    final userData = _userData;
    String userEmail;
    final email = userData?.email;
    if (email != null && email.isNotEmpty) {
      userEmail = email;
    } else {
      userEmail = _authService.currentUser?.email ?? '';
    }
    
    final nameController = TextEditingController(text: userName);
    final emailController = TextEditingController(text: userEmail);
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    
    List<File> selectedFiles = [];
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Send Feedback'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field (auto-filled, read-only)
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: AppTheme.lightGrayColor,
                    hintText: userName.isNotEmpty ? null : 'No name available',
                  ),
                  enabled: false,
                  style: TextStyle(
                    color: userName.isNotEmpty ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacingL),
                
                // Email field (auto-filled, read-only)
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: AppTheme.lightGrayColor,
                    hintText: userEmail.isNotEmpty ? null : 'No email available',
                  ),
                  enabled: false,
                  style: TextStyle(
                    color: userEmail.isNotEmpty ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacingL),
                
                // Subject field
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: const OutlineInputBorder(),
                    hintText: 'Enter subject of your feedback',
                    filled: true,
                    fillColor: AppTheme.lightGrayColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacingL),
                
                // Message field
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    border: const OutlineInputBorder(),
                    hintText: 'Enter your feedback message',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppTheme.lightGrayColor,
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: AppTheme.spacingL),
                
                // File upload section
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrayColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_file, color: AppTheme.primaryColor),
                          SizedBox(width: AppTheme.spacingS),
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: AppTheme.textSizeM,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      const Text(
                        'Upload images or files (max 50MB total)',
                        style: TextStyle(
                          fontSize: AppTheme.textSizeXS,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      
                      // Selected files list
                      if (selectedFiles.isNotEmpty) ...[
                        ...selectedFiles.map((file) => Container(
                          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: AppTheme.creamColor,
                                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusS),
                    border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file, size: 16),
                              SizedBox(width: AppTheme.spacingS),
                              Expanded(
                                child: Text(
                                  file.path.split('/').last,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    selectedFiles.remove(file);
                                  });
                                },
                                icon: const Icon(Icons.close, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        )),
                        SizedBox(height: AppTheme.spacingS),
                      ],
                      
                      // Upload button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                allowMultiple: true,
                                type: FileType.any,
                              );
                              
                              if (result != null) {
                                setDialogState(() {
                                  for (var file in result.files) {
                                    if (file.path != null) {
                                      selectedFiles.add(File(file.path!));
                                    }
                                  }
                                });
                              }
                            } catch (e) {
                              _showErrorSnackBar('Error selecting files: $e');
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Choose Files'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.creamColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (subjectController.text.trim().isEmpty) {
                  _showErrorSnackBar('Please enter a subject');
                  return;
                }
                
                if (messageController.text.trim().isEmpty) {
                  _showErrorSnackBar('Please enter a message');
                  return;
                }
                
                // Check file size limit (50MB = 50 * 1024 * 1024 bytes)
                int totalSize = 0;
                for (var file in selectedFiles) {
                  totalSize += await file.length();
                }
                
                if (totalSize > 50 * 1024 * 1024) {
                  _showErrorSnackBar('Total file size exceeds 50MB limit');
                  return;
                }
                
                setDialogState(() {
                  isSubmitting = true;
                });
                
                try {
                  // Prepare feedback content
                  final feedbackEmail = 'support@hinduconnect.app';
                  final subject = 'Hindu Connect Feedback: ${subjectController.text.trim()}';
                  final body = '''
Feedback from Hindu Connect App

Name: ${nameController.text.trim()}
Email: ${emailController.text.trim()}
Subject: ${subjectController.text.trim()}

Message:
${messageController.text.trim()}

---
Sent from Hindu Connect App
                  '''.trim();
                  
                  // Store context before async operation
                  final navigatorContext = context;
                  
                  // Open email client directly
                  await _openEmailClientDirectly(feedbackEmail, subject, body);
                  
                  if (mounted && navigatorContext.mounted) {
                    Navigator.pop(navigatorContext);
                  }
                } catch (e) {
                  setDialogState(() {
                    isSubmitting = false;
                  });
                  _showErrorSnackBar('Error preparing feedback: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.creamColor,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.creamColor),
                      ),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEmailClientDirectly(String feedbackEmail, String subject, String body) async {
    try {
      // Create the mailto URI with proper encoding
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: feedbackEmail,
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );
      

      
      // Try to open the email client with platform-specific launch mode
      if (await canLaunchUrl(emailUri)) {

        
        // Use platform-specific launch mode for better Android compatibility
        await launchUrl(
          emailUri,
          mode: LaunchMode.platformDefault,
        );
        

        _showSuccessSnackBar('Email client opened! Please review the content and tap SEND to actually send the email.');
      } else {

        
        // Try to open Gmail app directly on Android
        final gmailAppUri = Uri.parse('gmail://co?to=$feedbackEmail&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
        
        if (await canLaunchUrl(gmailAppUri)) {
          await launchUrl(
            gmailAppUri,
            mode: LaunchMode.externalApplication,
          );
          _showSuccessSnackBar('Gmail app opened! Please review the content and tap SEND to actually send the email.');
        } else {

          
          // Last resort: open web Gmail
          final webEmailUri = Uri.parse('https://mail.google.com/mail/?view=cm&fs=1&to=$feedbackEmail&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
          
          if (await canLaunchUrl(webEmailUri)) {
            await launchUrl(
              webEmailUri,
              mode: LaunchMode.externalApplication,
            );
            _showSuccessSnackBar('Gmail web opened! Please review the content and tap SEND to actually send the email.');
          } else {
            throw Exception('Could not open any email client');
          }
        }
      }
    } catch (e) {

      _showErrorSnackBar('Error opening email client: $e');
    }
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    Widget? suffixIcon,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText != null ? Colors.red.shade300 : Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          suffixIcon: suffixIcon,
          errorText: errorText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          counterText: maxLength != null ? null : '',
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userData?.name ?? '');
    final phoneController = TextEditingController(text: _userData?.phone ?? '');
    final pincodeController = TextEditingController(text: _userData?.pincode ?? '');
    
    String? city;
    String? state;
    String? pincodeError;
    bool isPincodeValidating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(
                          controller: nameController,
                          label: 'Name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: pincodeController,
                          label: 'Pincode',
                          icon: Icons.location_on_outlined,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          suffixIcon: isPincodeValidating
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
                          errorText: pincodeError,
                          onChanged: (value) async {
                            if (value.length == 6) {
                              setDialogState(() {
                                isPincodeValidating = true;
                                pincodeError = null;
                              });
                              
                              try {
                                final pincodeInfo = await PincodeService.getPincodeInfo(value);
                                
                                setDialogState(() {
                                  if (pincodeInfo != null) {
                                    city = pincodeInfo.city;
                                    state = pincodeInfo.state;
                                    pincodeError = null;
                                  } else {
                                    pincodeError = 'Invalid pincode';
                                    city = null;
                                    state = null;
                                  }
                                  isPincodeValidating = false;
                                });
                              } catch (e) {
                                setDialogState(() {
                                  pincodeError = 'Error validating pincode';
                                  city = null;
                                  state = null;
                                  isPincodeValidating = false;
                                });
                              }
                            } else {
                              setDialogState(() {
                                pincodeError = null;
                                city = null;
                                state = null;
                              });
                            }
                          },
                        ),
                        
                        // City and State display
                        if (city != null && state != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$city, $state',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _isEditing = false;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (city == null || state == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid pincode'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                            return;
                          }
                          
                          // Store context before async operation
                          final navigatorContext = context;
                          
                          await _updateProfile(
                            nameController.text,
                            phoneController.text,
                            pincodeController.text,
                            city!,
                            state!,
                          );
                          if (mounted && navigatorContext.mounted) {
                            Navigator.pop(navigatorContext);
                          }
                          setState(() {
                            _isEditing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile(String name, String phone, String pincode, String city, String state) async {
    try {
      final user = _authService.currentUser;
      if (user != null && _userData != null) {
        final updatedUser = _userData!.copyWith(
          name: name,
          phone: phone,
          pincode: pincode,
          city: city,
          state: state,
        );
        
        await _authService.updateUserData(updatedUser);
        
        if (mounted) {
          setState(() {
            _userData = updatedUser;
          });
          
          _showSuccessSnackBar('Profile updated successfully!');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error updating profile: $e');
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signOut();
            },
                    style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor,
          foregroundColor: AppTheme.creamColor,
        ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _showErrorSnackBar('Error signing out: $e');
    }
  }

  // Unused helper kept for future features; suppress unused_element lint
  // ignore: unused_element
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature feature is coming soon!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      // Check if URL can be launched
      if (await canLaunchUrl(uri)) {
        // Extract title from URL for better UX
        String title = 'Web Page';
        if (url.contains('privacy.html')) {
          title = 'Privacy Policy';
        } else if (url.contains('terms.html')) {
          title = 'Terms & Conditions';
        } else if (url.contains('faq.html')) {
          title = 'Help & FAQ';
        } else if (url.contains('about.html')) {
          title = 'About Hindu Connect';
        }
        
        // Navigate to custom WebView screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(
                url: url,
                title: title,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: $url'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
              content: Text('Error opening link: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
        );
      }
    }
  }

  Future<void> _rateApp() async {
    try {
      // Open Play Store for rating the app
      const String packageName = 'com.dikonda.hinduconnect';
      final Uri playStoreUri = Uri.parse('market://details?id=$packageName');
      final Uri webPlayStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
      
      // Try to open Play Store app first
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(
          playStoreUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to web Play Store
        if (await canLaunchUrl(webPlayStoreUri)) {
          await launchUrl(
            webPlayStoreUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open Play Store'),
                backgroundColor: AppTheme.warningColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
              content: Text('Error opening Play Store: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
        );
      }
    }
  }

  // Unused helper kept for future features; suppress unused_element lint
  // ignore: unused_element
  Future<void> _launchEmail(String email) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=Hindu Connect Support',
      );
      
      // Check if email can be launched
      if (await canLaunchUrl(emailUri)) {
        // Force launch in external email app
        await launchUrl(
          emailUri, 
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open email client'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
              content: Text('Error opening email: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
        );
      }
    }
  }

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
    {'name': 'Bhaiksuki', 'code': 'hi'}, // Fixed: Use 'hi' instead of 'bh'
    {'name': 'Brahmi', 'code': 'hi'}, // Fixed: Use 'hi' instead of 'br'
    {'name': 'Burmese (Myanmar)', 'code': 'my'},
    {'name': 'Cyrillic (Russian)', 'code': 'ru'},
    {'name': 'Grantha', 'code': 'hi'}, // Fixed: Use 'hi' instead of 'gr'
    {'name': 'Hebrew', 'code': 'he'},
    {'name': 'Hebrew (Judeo-Arabic)', 'code': 'he'}, // Fixed: Use 'he' instead of 'ja'
    {'name': 'Imperial Aramaic', 'code': 'ar'},
    {'name': 'Japanese (Hiragana)', 'code': 'ja-hira'},
    {'name': 'Japanese (Katakana)', 'code': 'ja-kata'},
    {'name': 'Javanese', 'code': 'jv'},
    {'name': 'Kharoshthi', 'code': 'hi'}, // Fixed: Use 'hi' instead of 'kh'
    {'name': 'Khmer (Cambodian)', 'code': 'km'},
    {'name': 'Lao', 'code': 'lo'},
    {'name': 'Meetei Mayek (Manipuri)', 'code': 'mni'},
    {'name': 'Mongolian', 'code': 'mn'},
    {'name': 'Newa (Nepal Bhasa)', 'code': 'new'},
    {'name': 'Old Persian', 'code': 'peo'},
    {'name': 'Old South Arabian', 'code': 'ar'}, // Fixed: Use 'ar' instead of 'srb'
    {'name': 'Persian', 'code': 'fa'},
    {'name': 'Phoenician', 'code': 'ar'}, // Fixed: Use 'ar' instead of 'phn'
    {'name': 'Psalter Pahlavi', 'code': 'fa'}, // Fixed: Use 'fa' instead of 'pal'
    {
      'name': 'Ranjana (Lantsa)',
      'code': 'ranj',
    }, // Use 'ranj' for proper Ranjana script support
    {'name': 'Samaritan', 'code': 'he'}, // Fixed: Use 'he' instead of 'sam'
    {'name': 'Santali (Ol Chiki)', 'code': 'sat'},
    {'name': 'Sharada', 'code': 'hi'}, // Fixed: Use 'hi' instead of 'sa'
    {'name': 'Siddham', 'code': 'hi'}, // Fixed: Use 'hi' instead of 'sid'
    {'name': 'Sinhala', 'code': 'si'},
    {'name': 'Sogdian', 'code': 'fa'}, // Fixed: Use 'fa' instead of 'sog'
    {'name': 'Soyombo', 'code': 'hi'}, // Fixed: Use 'hi' instead of 'soy'
    {'name': 'Syriac (Eastern)', 'code': 'ar'}, // Fixed: Use 'ar' instead of 'syr-e'
    {'name': 'Syriac (Estrangela)', 'code': 'ar'}, // Fixed: Use 'ar' instead of 'syr-s'
    {'name': 'Syriac (Western)', 'code': 'ar'}, // Fixed: Use 'ar' instead of 'syr-w'
    {'name': 'Tamil Brahmi', 'code': 'ta'}, // Fixed: Use 'ta' instead of 'ta-bra'
    {'name': 'Thaana (Dhivehi)', 'code': 'dv'},
    {'name': 'Thai', 'code': 'th'},
    {'name': 'Tibetan', 'code': 'bo'},
  ];

  void _showLanguageSelectionDialog() {
    final currentLanguage = _userData?.language ?? 'Roman itrans (English)';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Your Preferred Language'),
          content: SizedBox(
            width: double.maxFinite,
            height: AppTheme.dialogHeight,
            child: ListView.builder(
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = language['name'] == currentLanguage;
                
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        language['name']!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                        ),
                      ),
                      trailing: isSelected 
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                      onTap: () async {
                        // Store context before async operation
                        final navigatorContext = context;
                        await _updateUserLanguage(language['name']!, language['code']!);
                        if (mounted && navigatorContext.mounted) {
                          Navigator.pop(navigatorContext);
                        }
                      },
                    ),
                    if (index < _languages.length - 1)
                      Divider(
                        height: 1,
                        color: AppTheme.lightGrayColor,
                        indent: AppTheme.spacingL,
                        endIndent: AppTheme.spacingL,
                      ),
                  ],
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

  Future<void> _updateUserLanguage(String language, String languageCode) async {
    try {
      if (_userData != null) {
        final updatedUser = _userData!.copyWith(
          language: language,
          languageCode: languageCode,
        );
        
        // Save to Firestore
        await _authService.updateUserData(updatedUser);
        
        // ALSO save to LocalStorage so other screens can access it
        await LocalStorageService.saveUserLanguagePreference(language, languageCode);
        
        // Update local state
        setState(() {
          _userData = updatedUser;
        });
        
        // Clear cached conversions when language changes
        await LanguageConversionService().clearCachedConversions();
        
        // Update language in Riverpod provider - this will trigger automatic refresh
        await ref.read(languageProvider.notifier).updateLanguage(language);
        
        _showInfoSnackBar('Language updated to $language');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating language: $e');
    }
  }

  // Helper methods to avoid BuildContext issues in async callbacks
  void _showSnackBar(String message, {Color backgroundColor = AppTheme.errorColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    _showSnackBar(message, backgroundColor: AppTheme.successColor);
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(message, backgroundColor: AppTheme.errorColor);
  }

  void _showInfoSnackBar(String message) {
    _showSnackBar(message, backgroundColor: AppTheme.primaryColor);
  }
}