import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String description;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const EmptyState({
    super.key,
    required this.message,
    required this.description,
    required this.icon,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(retryButtonText ?? 'Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: 'Something went wrong',
      description: error,
      icon: Icons.error_outline,
      onRetry: onRetry,
      retryButtonText: 'Try Again',
    );
  }
}

class NoResultsState extends StatelessWidget {
  final String query;

  const NoResultsState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: 'No Results Found',
      description:
          'We couldn\'t find any results for "$query".\nTry different keywords or check your spelling.',
      icon: Icons.search_off,
    );
  }
}
