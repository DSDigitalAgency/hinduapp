import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/biography_model.dart';

class BiographiesSection extends StatelessWidget {
  final List<BiographyModel> biographies;
  final bool isLoading;
  final String? errorMessage;
  final Function(BiographyModel) onBiographyTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onSeeAllPressed;

  const BiographiesSection({
    super.key,
    required this.biographies,
    required this.isLoading,
    required this.errorMessage,
    required this.onBiographyTap,
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
                'Biographies',
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

        // Biographies Horizontal Scroll
        SizedBox(
          height: 80,
          child: isLoading
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildBiographySkeleton(),
                )
              : errorMessage != null
              ? _buildErrorWidget(errorMessage!)
              : biographies.isEmpty
              ? _buildEmptyWidget()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: biographies.length,
                  itemBuilder: (context, index) {
                    final biography = biographies[index];
                    return _buildBiographyCard(biography, onBiographyTap);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBiographyCard(
    BiographyModel biography,
    Function(BiographyModel) onTap,
  ) {
    return GestureDetector(
      onTap: () => onTap(biography),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                biography.displayTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiographySkeleton() {
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
                width: 100,
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
          Icon(Icons.person_outline, color: Colors.grey, size: 32),
          SizedBox(height: 8),
          Text(
            'No biographies available',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
