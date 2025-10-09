import 'package:flutter/material.dart';
import '../../../utils/font_utils.dart';

class SearchResultCard extends StatelessWidget {
  final String title;
  final String preview;
  final IconData icon;
  final VoidCallback onTap;
  final String? currentLanguage;

  const SearchResultCard({
    super.key,
    required this.title,
    required this.preview,
    required this.icon,
    required this.onTap,
    this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FontUtils.getTextStyleForLanguage(
                        currentLanguage ?? 'English',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // const SizedBox(height: 8),
                    // Text(
                    //   preview,
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     color: Colors.grey[600],
                    //     height: 1.4,
                    //   ),
                    //   maxLines: 2,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
