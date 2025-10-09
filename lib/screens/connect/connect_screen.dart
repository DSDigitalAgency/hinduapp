import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/post_model.dart';
import '../post_reader_screen.dart';
import '../../services/favorites_service.dart';
import '../../constants/app_theme.dart';
import 'dart:async';
import 'dart:math' as math;
import 'widgets/connect_app_bar.dart';
import 'widgets/connect_header.dart';
import 'widgets/search_results_indicator.dart';
import 'widgets/category_filter.dart';
import 'widgets/posts_list.dart';

// Helper class for scoring posts
class ScoredPost {
  final PostModel post;
  final double score;

  ScoredPost({required this.post, required this.score});
}

/// Connect Screen - Displays posts from all available categories
///
/// Features:
/// - Category filtering: Filter posts by different categories
/// - Pull-to-refresh: Reloads posts with latest content
/// - Search functionality: Search through post titles and content
/// - Pagination: Load more posts as user scrolls
/// - Favorites: Save and manage favorite posts
/// - Caching: Posts are cached until app closes
/// - Auto-reload: Content refreshes when user returns to screen

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final FavoritesService _favoritesService = FavoritesService();

  // Static cache to persist data across navigation
  static List<PostModel> _cachedPosts = [];
  static List<PostModel> _cachedFilteredPosts = [];
  static bool _hasInitialized = false;
  static bool _isLoading = true;
  static String? _cachedErrorMessage;
  static String _cachedSelectedCategory = 'All';
  static int _cachedCurrentPage = 1;
  static bool _cachedHasMoreData = true;
  static bool _cachedIsLoadingMore = false;

  // Instance variables for UI state
  List<PostModel> get _posts => _cachedPosts;
  List<PostModel> get _filteredPosts => _cachedFilteredPosts;
  bool get _isLoadingState => _isLoading;
  String? get _errorMessage => _cachedErrorMessage;
  String get _selectedCategory => _cachedSelectedCategory;
  int get _currentPage => _cachedCurrentPage;
  bool get _hasMoreData => _cachedHasMoreData;
  bool get _isLoadingMore => _cachedIsLoadingMore;

  // Search and sort variables
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'title', 'category', 'author'
  bool _sortAscending = false; // Default to descending (API default order)
  bool _isSearchExpanded = false;
  bool _showPlaceholder = false;
  final TextEditingController _searchController = TextEditingController();

  // Pagination variables
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  // Cache for faster loading
  final Map<String, List<PostModel>> _postCache = {};
  final Map<String, DateTime> _cacheTimestamp = {};
  static const Duration _cacheValidity = Duration(hours: 24);

  Timer? _debounce;
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (!_hasInitialized) {
      _loadPosts();
    }

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }


  Future<void> _loadPosts({bool isLoadMore = false}) async {
    try {
      print('🔍 Connect Screen: _loadPosts called - isLoadMore: $isLoadMore, category: $_selectedCategory, sortBy: $_sortBy, sortAscending: $_sortAscending');
      if (!isLoadMore) {
        setState(() {
          _isLoading = true;
          _cachedErrorMessage = null;
          _cachedCurrentPage = 1;
          _cachedHasMoreData = true;
        });
        print('🔍 Connect Screen: Loading state set to true');
      } else {
        setState(() {
          _cachedIsLoadingMore = true;
        });
      }

      // For load more, skip cache to ensure fresh data
      // Check cache first only for initial load
      final cacheKey =
          '${_selectedCategory}_page1'; // Always use page 1 for base cache
      if (_postCache.containsKey(cacheKey) &&
          !isLoadMore &&
          _currentPage == 1) {
        final cachedPosts = _postCache[cacheKey]!;
        final timestamp = _cacheTimestamp[cacheKey]!;
        final now = DateTime.now();

        if (now.difference(timestamp) <= _cacheValidity) {
          setState(() {
            _cachedPosts = List.from(
              cachedPosts,
            ); // Create new list to avoid reference issues
            _cachedFilteredPosts = List.from(cachedPosts);
            _isLoading = false;
          });
          _applySearchAndSort();
          return;
        }
      }

      dynamic response;

      if (_selectedCategory == 'All') {
        try {
          final sortParams = _getSortParameters();
          print('🔍 Connect Screen: Calling searchPosts with sort params: $sortParams');
          response = await _apiService.searchPosts({
            'q': '',
            'page': _currentPage.toString(),
            'limit': _pageSize.toString(),
            'sortOrder': sortParams['sortOrder']!,
            'fuzzy': 'false',
            'sortBy': sortParams['sortBy']!,
          });
          print('🔍 Connect Screen: searchPosts API call completed');
        } catch (apiError) {
          print('🔍 Connect Screen: searchPosts API error: $apiError');
          rethrow;
        }
      } else {
        try {
          final sortParams = _getSortParameters();
          print('🔍 Connect Screen: Calling getPostsByCategory with sort params: $sortParams');
          response = await _apiService.getPostsByCategory(_selectedCategory, {
            'page': _currentPage.toString(),
            'limit': _pageSize.toString(),
            'sortBy': sortParams['sortBy']!,
            'sortOrder': sortParams['sortOrder']!,
          });
          print('🔍 Connect Screen: getPostsByCategory API call completed');
        } catch (apiError) {
          print('🔍 Connect Screen: getPostsByCategory API error: $apiError');
          rethrow;
        }
      }

      // Process API response
      List<Map<String, dynamic>> postData;
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        postData = ApiService.safeCastToList(response, 'results');
      } else if (response is Map<String, dynamic> &&
          response.containsKey('posts')) {
        postData = ApiService.safeCastToList(response, 'posts');
      } else if (response is Map<String, dynamic> &&
          response.containsKey('data')) {
        postData = ApiService.safeCastToList(response, 'data');
      } else if (response is Map<String, dynamic> &&
          response.containsKey('blogs')) {
        postData = ApiService.safeCastToList(response, 'blogs');
      } else {
        if (response is List) {
          postData = response.whereType<Map<String, dynamic>>().toList();
        } else {
          postData = [];
        }
      }

      // Debug: Log the first few post titles and available fields to see if sorting is working
      if (postData.isNotEmpty) {
        print('🔍 Connect Screen: First 5 post titles from API:');
        for (int i = 0; i < math.min(5, postData.length); i++) {
          final title = postData[i]['title'] ?? postData[i]['basicInfo']?['title'] ?? 'No title';
          final category = postData[i]['category'] ?? postData[i]['basicInfo']?['category'] ?? 'No category';
          print('🔍 Connect Screen: Post $i: "$title" (category: "$category")');
        }
        
        // Log available fields in the first post to debug field names
        if (postData.isNotEmpty) {
          print('🔍 Connect Screen: Available fields in first post: ${postData[0].keys.toList()}');
        }
      }

      List<Map<String, dynamic>> filteredPostData = postData;

      if (filteredPostData.isEmpty) {
        setState(() {
          _cachedPosts = [];
          _isLoading = false;
          _cachedErrorMessage = 'No posts available';
        });
        return;
      }

      final newPosts = await _processPostsWithContentFetching(filteredPostData);

      // Apply client-side sorting as fallback if API sorting doesn't work properly
      final sortedPosts = _applyClientSideSorting(newPosts);

      if (isLoadMore) {
        // For pagination, maintain order by adding new posts at the end
        final updatedPosts = List<PostModel>.from(_cachedPosts);

        // Remove duplicates while maintaining order
        final existingIds = _cachedPosts.map((p) => p.id).toSet();
        final uniqueNewPosts = sortedPosts
            .where((p) => !existingIds.contains(p.id))
            .toList();

        updatedPosts.addAll(uniqueNewPosts);

        setState(() {
          _cachedPosts = updatedPosts;
          _cachedFilteredPosts = List.from(updatedPosts);
          _cachedIsLoadingMore = false;
        });
      } else {
        print('🔍 Connect Screen: Setting posts and completing load');
        setState(() {
          _cachedPosts = List.from(sortedPosts);
          _cachedFilteredPosts = List.from(sortedPosts);
          _isLoading = false;
        });
        print('🔍 Connect Screen: Load completed successfully with ${sortedPosts.length} posts');

        // Only cache the initial load (page 1)
        if (_currentPage == 1) {
          _postCache[cacheKey] = List.from(_cachedPosts);
          _cacheTimestamp[cacheKey] = DateTime.now();
        }
      }

      // Only apply sorting if it's not a load more operation to maintain scroll order
      if (!isLoadMore) {
        _applySearchAndSort();
      }

      if (newPosts.length < _pageSize) {
        setState(() {
          _cachedHasMoreData = false;
        });
      }

      if (!_hasInitialized) {
        _hasInitialized = true;
      }
    } catch (e) {
      print('🔍 Connect Screen: _loadPosts error: $e');
      setState(() {
        _cachedErrorMessage = 'Failed to load posts. Please try again.';
        _isLoading = false;
        if (isLoadMore) {
          _cachedIsLoadingMore = false;
        }
      });
    }
  }

  Future<void> _refreshPosts() async {
    // Clear all cache for current category to force fresh load
    _postCache.removeWhere((key, _) => key.startsWith('${_selectedCategory}_'));
    _cacheTimestamp.removeWhere(
      (key, _) => key.startsWith('${_selectedCategory}_'),
    );

    setState(() {
      _cachedCurrentPage = 1;
      _cachedHasMoreData = true;
      _cachedPosts = [];
      _cachedFilteredPosts = [];
    });

    await _loadPosts();
  }

  void _onCategoryChanged(String category) {
    if (_selectedCategory == category) return;

    setState(() {
      _cachedSelectedCategory = category;
      _cachedCurrentPage = 1;
      _cachedHasMoreData = true;
      _cachedPosts = [];
      _cachedFilteredPosts = [];
    });

    _loadPosts();
  }

  // Helper method to apply client-side sorting as fallback
  List<PostModel> _applyClientSideSorting(List<PostModel> posts) {
    if (posts.isEmpty) return posts;
    
    print('🔍 Connect Screen: Applying client-side sorting by $_sortBy, ascending: $_sortAscending');
    
    final sortedPosts = List<PostModel>.from(posts);
    
    switch (_sortBy) {
      case 'title':
        sortedPosts.sort((a, b) {
          final comparison = a.basicInfo.title.toLowerCase().compareTo(b.basicInfo.title.toLowerCase());
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case 'date':
        sortedPosts.sort((a, b) {
          final comparison = a.createddt.compareTo(b.createddt);
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case 'category':
        sortedPosts.sort((a, b) {
          final comparison = a.basicInfo.category.toLowerCase().compareTo(b.basicInfo.category.toLowerCase());
          return _sortAscending ? comparison : -comparison;
        });
        break;
      case 'author':
        sortedPosts.sort((a, b) {
          final comparison = a.author.authorName.toLowerCase().compareTo(b.author.authorName.toLowerCase());
          return _sortAscending ? comparison : -comparison;
        });
        break;
    }
    
    // Log first few titles after sorting
    print('🔍 Connect Screen: After client-side sorting:');
    for (int i = 0; i < math.min(3, sortedPosts.length); i++) {
      print('🔍 Connect Screen: Post $i: "${sortedPosts[i].basicInfo.title}"');
    }
    
    return sortedPosts;
  }

  // Helper method to convert local sort parameters to API parameters
  Map<String, String> _getSortParameters() {
    String apiSortBy;
    String apiSortOrder;

    switch (_sortBy) {
      case 'title':
        // Try different possible field names for title sorting
        apiSortBy = 'title'; // Try the basic title field first
        break;
      case 'date':
        apiSortBy = 'createddt';
        break;
      case 'category':
        apiSortBy = 'category';
        break;
      case 'author':
        // API doesn't support author sorting, fallback to title
        apiSortBy = 'title';
        break;
      default:
        apiSortBy = 'createddt';
    }

    apiSortOrder = _sortAscending ? 'asc' : 'desc';

    print('🔍 Connect Screen: Sort parameters - local: $_sortBy, api: $apiSortBy, order: $apiSortOrder');

    return {
      'sortBy': apiSortBy,
      'sortOrder': apiSortOrder,
    };
  }

  void _applySearchAndSort() {
    // Preserve original order while removing duplicates
    final seenIds = <String>{};
    final deduplicatedPosts = <PostModel>[];

    for (final post in _cachedPosts) {
      if (!seenIds.contains(post.id)) {
        seenIds.add(post.id);
        deduplicatedPosts.add(post);
      }
    }

    // Since we're now getting sorted data from the API, we don't need to sort locally
    // Just apply search filtering if there's a search query
    List<PostModel> filtered = List.from(deduplicatedPosts);

    if (_searchQuery.isNotEmpty) {
      filtered = _sortBySearchRelevance(filtered, _searchQuery);
    }

    setState(() {
      _cachedFilteredPosts = filtered;
    });
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      await _loadPosts();
      return;
    }

    setState(() {
      _isLoading = true;
      _cachedErrorMessage = null;
    });

    try {
      dynamic response;

      if (_selectedCategory == 'All') {
        final sortParams = _getSortParameters();
        response = await _apiService.searchPosts({
          'q': _searchQuery,
          'page': '1',
          'limit': _pageSize.toString(),
          'sortOrder': sortParams['sortOrder']!,
          'fuzzy': 'true',
          'sortBy': sortParams['sortBy']!,
        });
      } else {
        final sortParams = _getSortParameters();
        response = await _apiService.getPostsByCategory(_selectedCategory, {
          'q': _searchQuery,
          'page': '1',
          'limit': _pageSize.toString(),
          'fuzzy': 'true',
          'sortBy': sortParams['sortBy']!,
          'sortOrder': sortParams['sortOrder']!,
        });
      }

      List<Map<String, dynamic>> postData;
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        postData = ApiService.safeCastToList(response, 'results');
      } else if (response is Map<String, dynamic> &&
          response.containsKey('posts')) {
        postData = ApiService.safeCastToList(response, 'posts');
      } else if (response is Map<String, dynamic> &&
          response.containsKey('data')) {
        postData = ApiService.safeCastToList(response, 'data');
      } else if (response is Map<String, dynamic> &&
          response.containsKey('blogs')) {
        postData = ApiService.safeCastToList(response, 'blogs');
      } else {
        postData = [];
      }

      if (postData.isEmpty) {
        setState(() {
          _cachedPosts = [];
          _cachedFilteredPosts = [];
          _isLoading = false;
          _cachedErrorMessage = 'No results found for "$_searchQuery"';
        });
        return;
      }

      final newPosts = await _processPostsWithContentFetching(postData);
      final sortedPosts = _sortBySearchRelevance(newPosts, _searchQuery);

      setState(() {
        _cachedPosts = sortedPosts;
        _cachedFilteredPosts = sortedPosts;
        _isLoading = false;
        _cachedCurrentPage = 1;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _cachedErrorMessage = 'Search failed: ${error.toString()}';
      });
    }
  }

  List<PostModel> _sortBySearchRelevance(List<PostModel> posts, String query) {
    if (query.isEmpty) return posts;

    final queryLower = query.toLowerCase();

    final scoredPosts = posts.map((post) {
      double score = 0.0;

      final titleLower = post.basicInfo.title.toLowerCase();
      if (titleLower.contains(queryLower)) {
        score += 100.0;
        if (titleLower == queryLower) {
          score += 50.0;
        }
        if (titleLower.startsWith(queryLower)) {
          score += 25.0;
        }
      }

      final authorLower = post.author.authorName.toLowerCase();
      if (authorLower.contains(queryLower)) {
        score += 50.0;
        if (authorLower == queryLower) {
          score += 25.0;
        }
      }

      final categoryLower = post.basicInfo.category.toLowerCase();
      if (categoryLower.contains(queryLower)) {
        score += 30.0;
      }

      if (post.content.body.isNotEmpty) {
        final contentLower = post.content.body.toLowerCase();
        if (contentLower.contains(queryLower)) {
          score += 10.0;
        }
      }

      return ScoredPost(post: post, score: score);
    }).toList();

    scoredPosts.sort((a, b) => b.score.compareTo(a.score));
    return scoredPosts.map((scored) => scored.post).toList();
  }

  void _onScroll() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
      _handleScrollEvent();
    });
  }

  void _handleScrollEvent() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_cachedHasMoreData && !_cachedIsLoadingMore && !_isLoading) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_cachedHasMoreData && !_cachedIsLoadingMore) {
      setState(() {
        _cachedCurrentPage++;
      });
      await _loadPosts(isLoadMore: true);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      _showPlaceholder = false;
      if (!_isSearchExpanded) {
        _searchController.clear();
        _searchQuery = '';
        if (_cachedFilteredPosts.length != _cachedPosts.length) {
          _performSearch();
        }
      }
    });

    if (_isSearchExpanded) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _showPlaceholder = true;
          });
          FocusScope.of(context).requestFocus(FocusNode());
        }
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final newQuery = _searchController.text.trim();
        if (_searchQuery != newQuery) {
          _searchQuery = newQuery;
          _performSearch();
        }
      }
    });
  }

  void _showSortDialog() {
    String tempSortBy = _sortBy;
    bool tempSortAscending = _sortAscending;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sort Posts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempSortBy = 'date';
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tempSortBy == 'date' ? AppTheme.primaryColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: tempSortBy == 'date'
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                    ),
                    title: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        const Text('Date'),
                      ],
                    ),
                    onTap: () {
                      setDialogState(() {
                        tempSortBy = 'date';
                      });
                    },
                  ),
                  ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempSortBy = 'title';
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tempSortBy == 'title' ? AppTheme.primaryColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: tempSortBy == 'title'
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.title, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        const Text('Title'),
                      ],
                    ),
                    onTap: () {
                      setDialogState(() {
                        tempSortBy = 'title';
                      });
                    },
                  ),
                  ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempSortBy = 'category';
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tempSortBy == 'category' ? AppTheme.primaryColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: tempSortBy == 'category'
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        const Text('Category'),
                      ],
                    ),
                    onTap: () {
                      setDialogState(() {
                        tempSortBy = 'category';
                      });
                    },
                  ),
                  ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempSortBy = 'author';
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tempSortBy == 'author' ? AppTheme.primaryColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: tempSortBy == 'author'
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        const Text('Author'),
                      ],
                    ),
                    onTap: () {
                      setDialogState(() {
                        tempSortBy = 'author';
                      });
                    },
                  ),
                ],
              ),
              const Divider(),
              const Text(
                'Sort order:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempSortAscending = true;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tempSortAscending == true ? AppTheme.primaryColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: tempSortAscending == true
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        const Text('Ascending'),
                      ],
                    ),
                    onTap: () {
                      setDialogState(() {
                        tempSortAscending = true;
                      });
                    },
                  ),
                  ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempSortAscending = false;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tempSortAscending == false ? AppTheme.primaryColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: tempSortAscending == false
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                    ),
                    title: Row(
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        const Text('Descending'),
                      ],
                    ),
                    onTap: () {
                      setDialogState(() {
                        tempSortAscending = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigatorContext = context;
                print('🔍 Connect Screen: Applying sort - $_sortBy, ascending: $_sortAscending');
                setState(() {
                  _sortBy = tempSortBy;
                  _sortAscending = tempSortAscending;
                });
                print('🔍 Connect Screen: Sort applied - $_sortBy, ascending: $_sortAscending');
                // Reset pagination and reload data with new sort parameters
                _cachedCurrentPage = 1;
                _cachedHasMoreData = true;
                _cachedPosts = [];
                _cachedFilteredPosts = [];
                
                // Clear cache for current category to force fresh load with new sort
                _postCache.removeWhere((key, _) => key.startsWith('${_selectedCategory}_'));
                _cacheTimestamp.removeWhere((key, _) => key.startsWith('${_selectedCategory}_'));
                
                print('🔍 Connect Screen: Starting to load posts with new sort...');
                // Add a small delay to ensure UI updates
                await Future.delayed(const Duration(milliseconds: 100));
                await _loadPosts();
                print('🔍 Connect Screen: Posts loaded successfully');
                if (navigatorContext.mounted) {
                  Navigator.pop(navigatorContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9933),
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<PostModel>> _processPostsWithContentFetching(
    List<Map<String, dynamic>> postData,
  ) async {
    final List<PostModel> posts = [];

    for (final json in postData) {
      try {
        final modifiedJson = Map<String, dynamic>.from(json);

        String actualContent =
            json['content'] ??
            json['body'] ??
            json['excerpt'] ??
            json['summary'] ??
            json['description'] ??
            json['text'] ??
            '';

        modifiedJson['content'] = {
          'body': actualContent,
          'language': json['language'] ?? 'English',
          'isLoading': false,
        };

        final post = PostModel.fromJson(modifiedJson);
        posts.add(post);
      } catch (e) {
        // Handle post processing error silently
      }
    }

    return posts;
  }

  Future<void> _togglePostFavorite(PostModel post) async {
    try {
      if (post.id.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot favorite post: Invalid post ID'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final isFavorited = await _favoritesService.isFavorited(post.id);

      if (isFavorited) {
        await _favoritesService.removeFromFavorites(post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        await _favoritesService.addToFavorites(
          itemId: post.id,
          itemType: 'post',
          title: post.basicInfo.title,
          description: post.basicInfo.title,
          imageUrl: '',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              backgroundColor: Color(0xFFFF9933),
            ),
          );
        }
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _scrollDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar
            ConnectAppBar(
              isSearchExpanded: _isSearchExpanded,
              searchController: _searchController,
              showPlaceholder: _showPlaceholder,
              onToggleSearch: _toggleSearch,
              onShowSortDialog: _showSortDialog,
              onSearchClear: () {
                _searchController.clear();
                _searchQuery = '';
                if (_cachedFilteredPosts.length != _cachedPosts.length) {
                  _performSearch();
                }
              },
            ),

            // Header Section
            const ConnectHeader(),

            // Search Results Indicator
            if (_searchQuery.isNotEmpty)
              SearchResultsIndicator(
                searchQuery: _searchQuery,
                filteredPostsLength: _filteredPosts.length,
                onClearSearch: () {
                  _searchController.clear();
                  _searchQuery = '';
                  if (_cachedFilteredPosts.length != _cachedPosts.length) {
                    _performSearch();
                  }
                },
              ),

            // Category Filter
            CategoryFilter(
              selectedCategory: _selectedCategory,
              onCategoryChanged: _onCategoryChanged,
            ),

            // Posts Section
            Expanded(
              child: PostsList(
                isLoading: _isLoadingState,
                errorMessage: _errorMessage,
                posts: _posts,
                filteredPosts: _filteredPosts,
                hasMoreData: _hasMoreData,
                isLoadingMore: _isLoadingMore,
                scrollController: _scrollController,
                onRefresh: _refreshPosts,
                onToggleFavorite: _togglePostFavorite,
                onPostTap: (post) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostReaderScreen(post: post),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
