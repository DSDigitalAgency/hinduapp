import 'package:flutter/material.dart';

class SearchResultsIndicator extends StatelessWidget {
  final String searchQuery;
  final int filteredPostsLength;
  final int totalResults;
  final VoidCallback onClearSearch;

  const SearchResultsIndicator({
    super.key,
    required this.searchQuery,
    required this.filteredPostsLength,
    required this.totalResults,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: filteredPostsLength == 0 ? Colors.orange[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filteredPostsLength == 0
              ? Colors.orange[200]!
              : Colors.blue[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            filteredPostsLength == 0 ? Icons.search_off : Icons.search,
            color: filteredPostsLength == 0
                ? Colors.orange[600]
                : Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filteredPostsLength == 0
                      ? 'No results found for "$searchQuery"'
                      : totalResults > 0 && totalResults > filteredPostsLength
                          ? 'Showing $filteredPostsLength out of $totalResults results'
                          : 'Found $filteredPostsLength result${filteredPostsLength == 1 ? '' : 's'} for "$searchQuery"',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: filteredPostsLength == 0
                        ? Colors.orange[700]
                        : Colors.blue[700],
                  ),
                ),
                if (filteredPostsLength > 0)
                  Text(
                    'Showing posts with matching titles or authors',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClearSearch,
            icon: Icon(
              Icons.clear,
              color: filteredPostsLength == 0
                  ? Colors.orange[600]
                  : Colors.blue[600],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
