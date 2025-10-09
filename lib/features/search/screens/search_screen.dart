import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
import 'sacred_texts_search_screen.dart';
import 'temples_search_screen.dart';
import 'biographies_search_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCreamColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            children: [
              // Header
              const Text(
                'Explore Hindu Heritage',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingS),
              const Text(
                'Discover the vast treasures of Sanatana Dharma',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXXXL),

              // Search categories
              Expanded(
                child: Column(
                  children: [
                    _buildCategoryCard(
                      context,
                      'Sacred Texts',
                      'Discover Sacred Hymns, Mantras & Chants',
                      Icons.auto_stories,
                      () => _navigateToSearch(
                        context,
                        const SacredTextsSearchScreen(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildCategoryCard(
                      context,
                      'Temples',
                      'Explore Sacred Places & Pilgrimage Sites',
                      Icons.temple_hindu,
                      () => _navigateToSearch(
                        context,
                        const TemplesSearchScreen(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildCategoryCard(
                      context,
                      'Biographies',
                      'Learn about Saints & Spiritual Leaders',
                      Icons.person,
                      () => _navigateToSearch(
                        context,
                        const BiographiesSearchScreen(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    // Define gradient colors based on the card type
    List<Color> gradientColors;
    Color shadowColor;
    
    // All cards now use the same orange gradient
    gradientColors = [
      const Color(0xFFFFB74D), // Rich orange
      const Color(0xFFFF8A65), // Coral orange
    ];
    shadowColor = Colors.deepOrange.withValues(alpha: 0.4);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXL),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingL),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon, 
            color: Colors.deepOrange[600], 
            size: 26
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            fontSize: 14, 
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withValues(alpha: 0.8),
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  void _navigateToSearch(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
