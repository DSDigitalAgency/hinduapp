import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/temple_model.dart';

class TemplesSection extends StatelessWidget {
  final List<TempleModel> temples;
  final bool isLoading;
  final String? errorMessage;
  final Function(TempleModel) onTempleTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onSeeAllPressed;

  const TemplesSection({
    super.key,
    required this.temples,
    required this.isLoading,
    required this.errorMessage,
    required this.onTempleTap,
    this.onRefresh,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Temples',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onSeeAllPressed != null)
                    TextButton(
                      onPressed: onSeeAllPressed,
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  if (errorMessage != null && onRefresh != null)
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Retry loading',
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Temples Horizontal Scroll
        SizedBox(
          height: 80,
          child: isLoading
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildTempleSkeleton(),
                )
              : errorMessage != null
              ? _buildErrorWidget(errorMessage!)
              : temples.isEmpty
              ? _buildEmptyWidget()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: temples.length,
                  itemBuilder: (context, index) {
                    final temple = temples[index];
                    return _buildTempleCard(temple, onTempleTap);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTempleCard(TempleModel temple, Function(TempleModel) onTap) {
    return GestureDetector(
      onTap: () => onTap(temple),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(right: 16, bottom: 4, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Title with exactly 2 lines max
              Text(
                temple.displayTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description text
              Expanded(
                child: Text(
                  _getDisplayText(temple),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayText(TempleModel temple) {
    String displayText =
        temple.excerpt ?? temple.text ?? 'Explore this sacred temple';

    // Clean up any HTML tags or extra whitespace
    displayText = displayText.replaceAll(RegExp(r'<[^>]*>'), '');
    displayText = displayText.replaceAll(RegExp(r'\s+'), ' ');
    displayText = displayText.trim();

    // Limit length to prevent overflow (reduced for 2 lines)
    if (displayText.length > 60) {
      displayText = '${displayText.substring(0, 60)}...';
    }

    return displayText;
  }

  Widget _buildTempleSkeleton() {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.temple_hindu, color: Colors.grey, size: 32),
          SizedBox(height: 8),
          Text(
            'No temples available',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
