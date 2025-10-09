import 'dart:io';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'web_view_screen.dart';
import '../constants/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _signInWithGoogle() async {
    // debug log disabled in production
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Perform Google Sign In with Firebase
      final result = await _authService.signInWithGoogle();
      
      if (result != null && mounted) {
        // debug log disabled
        
        // Check if user profile is complete
        final isProfileComplete = await _authService.isUserProfileComplete();
        
                  if (isProfileComplete) {
            // debug log disabled
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Successfully signed in with Google!'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            // debug log disabled
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please complete your profile setup'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
              Navigator.pushReplacementNamed(context, '/profile-setup');
            }
          }
      } else {
        // debug log disabled
      }
    } catch (e) {
      // debug log disabled
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: AppTheme.errorColor,
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

  Future<void> _signInWithApple() async {
    if (!Platform.isIOS) {
      // debug log disabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple Sign In is only available on iOS devices'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // debug log disabled
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Perform Apple Sign In with Firebase
      final result = await _authService.signInWithApple();
      
      if (result != null && mounted) {
        // debug log disabled
        
        // Check if user profile is complete
        final isProfileComplete = await _authService.isUserProfileComplete();
        
        if (isProfileComplete) {
          // debug log disabled
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully signed in with Apple!'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // debug log disabled
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
              content: Text('Please complete your profile setup'),
              backgroundColor: AppTheme.primaryColor,
            ),
            );
            Navigator.pushReplacementNamed(context, '/profile-setup');
          }
        }
      } else {
        // debug log disabled
      }
    } catch (e) {
      // debug log disabled
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple Sign in failed: $e'),
            backgroundColor: AppTheme.errorColor,
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
      backgroundColor: AppTheme.warmCreamColor, // Light cream background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppTheme.spacingXXXL),
                
                // Logo and branding
                Container(
                  width: AppTheme.logoSize,
                  height: AppTheme.logoSize,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: AppTheme.borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                  ),
                  child: Padding(
                                          padding: const EdgeInsets.all(AppTheme.spacingS),
                    child: Image.asset(
                      'assets/app_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXL),
                
                const Text(
                  'Hindu Connect',
                  style: TextStyle(
                    fontSize: AppTheme.textSizeXXXL,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                
                const Text(
                  'World\'s 1ˢᵗ Complete\nDevotional Mobile App',
                  style: TextStyle(
                    fontSize: AppTheme.textSizeM,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXXXL),
                
                // Welcome text
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: AppTheme.textSizeXXL,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                
                const Text(
                  'Sign in to continue your spiritual journey',
                  style: TextStyle(
                    fontSize: AppTheme.textSizeM,
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXXXL),
                
                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.creamColor,
                      foregroundColor: AppTheme.textPrimaryColor,
                      side: BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: AppTheme.loadingSize,
                            height: AppTheme.loadingSize,
                            child: CircularProgressIndicator(
                              strokeWidth: AppTheme.strokeWidth,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'public/google.svg',
                                                            height: AppTheme.iconSize,
                            width: AppTheme.iconSize,
                                placeholderBuilder: (context) => const Icon(
                                  Icons.login,
                                  size: AppTheme.iconSize,
                                  color: AppTheme.languageBlueColor,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: AppTheme.textSizeM,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Apple Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithApple,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkGrayColor,
                      foregroundColor: AppTheme.creamColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.apple,
                          size: AppTheme.iconSize,
                          color: AppTheme.creamColor,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        const Text(
                          'Continue with Apple',
                          style: TextStyle(
                            fontSize: AppTheme.textSizeM,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingXXL),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.borderColor)),
                    Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                      child: Text(
                        'Secure & Fast Login',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: AppTheme.textSizeS,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.borderColor)),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingXXL),
                
                // Terms and privacy
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: AppTheme.textSizeXS,
                      color: AppTheme.textSecondaryColor,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WebViewScreen(
                                  url: 'https://hinduconnect.app/terms.html',
                                  title: 'Terms of Service',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Terms of Service',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WebViewScreen(
                                  url: 'https://hinduconnect.app/privacy.html',
                                  title: 'Privacy Policy',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingXXL),
                
                // Bottom tagline
                const Text(
                  'Connecting Hearts with Devotion',
                  style: TextStyle(
                    fontSize: AppTheme.textSizeS,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 