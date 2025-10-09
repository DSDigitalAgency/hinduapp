import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class HomeAppBar extends StatelessWidget {
  final VoidCallback onFavoritesPressed;

  const HomeAppBar({
    super.key,
    required this.onFavoritesPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Hindu Connect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: onFavoritesPressed,
              icon: const Icon(Icons.favorite, color: Colors.white),
              tooltip: 'Favorites',
            ),
          ],
        ),
      ),
    );
  }
}
