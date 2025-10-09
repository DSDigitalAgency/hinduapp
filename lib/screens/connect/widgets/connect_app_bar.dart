import 'package:flutter/material.dart';

class ConnectAppBar extends StatelessWidget {
  final bool isSearchExpanded;
  final TextEditingController searchController;
  final bool showPlaceholder;
  final VoidCallback onToggleSearch;
  final VoidCallback onShowSortDialog;
  final VoidCallback onSearchClear;

  const ConnectAppBar({
    super.key,
    required this.isSearchExpanded,
    required this.searchController,
    required this.showPlaceholder,
    required this.onToggleSearch,
    required this.onShowSortDialog,
    required this.onSearchClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Color(0xFFFF9933)),
      child: Row(
        children: [
          Expanded(
            child: AnimatedOpacity(
              opacity: isSearchExpanded ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: const Row(
                children: [
                  Text(
                    'Connect',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Enhanced Search Bar
          GestureDetector(
            onTap: () {
              // Close search if it's empty and expanded
              if (isSearchExpanded && searchController.text.isEmpty) {
                onToggleSearch();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isSearchExpanded
                  ? MediaQuery.of(context).size.width - 80
                  : 48,
              child: isSearchExpanded
                  ? Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.search,
                            color: Color(0xFFFF9933),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: showPlaceholder
                                    ? 'Search titles or authors...'
                                    : '',
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          if (searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: onSearchClear,
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                        ],
                      ),
                    )
                  : IconButton(
                      onPressed: onToggleSearch,
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: const EdgeInsets.all(10),
                    ),
            ),
          ),
          IconButton(
            onPressed: onShowSortDialog,
            icon: const Icon(Icons.tune, color: Colors.white),
            tooltip: 'Advanced sort options',
          ),
        ],
      ),
    );
  }
}
