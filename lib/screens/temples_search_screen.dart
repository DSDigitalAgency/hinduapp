import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/temple_model.dart';
import '../constants/app_theme.dart';
import 'temple_reading_screen.dart';

class TemplesSearchScreen extends StatefulWidget {
  const TemplesSearchScreen({super.key});

  @override
  State<TemplesSearchScreen> createState() => _TemplesSearchScreenState();
}

class _TemplesSearchScreenState extends State<TemplesSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  Timer? _debounce;
  Timer? _scrollDebounce; // Add scroll debounce timer
  
  List<TempleModel> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _scrollDebounce?.cancel(); // Cancel scroll debounce timer
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = null;
      });
      return;
    }
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      // Reset pagination when query changes
      _currentPage = 1;
      _hasMore = true;
      _searchToken++;
      _performSearch(query, refresh: true, callerToken: _searchToken);
    });
  }

  Future<void> _performSearch(String query, {bool refresh = false, int? callerToken}) async {
    final int localToken = callerToken ?? _searchToken;
    if (refresh) {
      setState(() {
        _isSearching = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      List<TempleModel> temples = [];
      
      // Try the main temple search API first
      try {
        final response = await _apiService.searchTemples({
          'q': query,
          'page': _currentPage.toString(),
          'limit': _pageSize.toString(),
          'sortOrder': 'desc',
          'fuzzy': 'true', // Enable fuzzy search for better results
          'sortBy': 'title', // Sort by title for better relevance
        });
        
        final results = ApiService.safeCastToList(response, 'temples');
        temples = results.map((json) => TempleModel.fromJson(json)).toList();

        // Sort by relevance score (highest first) - similar to sacred text search
        temples.sort((a, b) {
          final titleA = a.displayTitle.toLowerCase();
          final titleB = b.displayTitle.toLowerCase();
          final queryLower = query.toLowerCase();
          
          // Calculate relevance scores
          final scoreA = _calculateRelevanceScore(titleA, queryLower);
          final scoreB = _calculateRelevanceScore(titleB, queryLower);
          
          // Primary sort by relevance score (descending)
          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA);
          }
          
          // Secondary sort by title length (shorter = more specific)
          if (a.displayTitle.length != b.displayTitle.length) {
            return a.displayTitle.length.compareTo(b.displayTitle.length);
          }
          
          // Tertiary sort alphabetically
          return titleA.compareTo(titleB);
        });
        
        // Fallback to broader search if main search returns few results
        if (temples.length < 5) {
          try {
            // Try to get more temples and filter by search query
            final randomResponse = await _apiService.getRandomTemples(count: 50);
            final randomTemples = ApiService.safeCastToList(randomResponse, 'temples');
            
            if (randomTemples.isNotEmpty) {
              final additionalTemples = randomTemples
                  .map((json) => TempleModel.fromJson(json))
                  .where((temple) {
                    final title = temple.displayTitle.toLowerCase();
                    final queryLower = query.toLowerCase();
                    return title.contains(queryLower);
                  })
                  .toList();
              
              // Add unique temples that weren't already in results
              final existingIds = temples.map((t) => t.templeId ?? t.displayTitle).toSet();
              final uniqueAdditional = additionalTemples
                  .where((t) => !existingIds.contains(t.templeId ?? t.displayTitle))
                  .take(10) // Limit additional results
                  .toList();
              
              temples.addAll(uniqueAdditional);
              
              // Re-sort with the additional temples using same logic
              temples.sort((a, b) {
                final titleA = a.displayTitle.toLowerCase();
                final titleB = b.displayTitle.toLowerCase();
                final queryLower = query.toLowerCase();
                
                // Calculate relevance scores
                final scoreA = _calculateRelevanceScore(titleA, queryLower);
                final scoreB = _calculateRelevanceScore(titleB, queryLower);
                
                // Primary sort by relevance score (descending)
                if (scoreA != scoreB) {
                  return scoreB.compareTo(scoreA);
                }
                
                // Secondary sort by title length (shorter = more specific)
                if (a.displayTitle.length != b.displayTitle.length) {
                  return a.displayTitle.length.compareTo(b.displayTitle.length);
                }
                
                // Tertiary sort alphabetically
                return titleA.compareTo(titleB);
              });
            }
          } catch (fallbackError) {
            // Handle fallback error silently
          }
        }
        
        // Individual temple search as last resort
        try {
          final response = await _apiService.getTempleByTitle(query);
          if (response['templeId'] != null) {
            final temple = TempleModel.fromJson(response);
            // Check if this temple is already in results
            final exists = temples.any((t) => 
              (t.templeId ?? t.displayTitle) == (temple.templeId ?? temple.displayTitle)
            );
            
            if (!exists) {
              temples.insert(0, temple); // Insert at beginning for high relevance
            }
          }
        } catch (fallbackError) {
          // Handle fallback error silently
        }
        
        if (!mounted || localToken != _searchToken) return;
        setState(() {
          if (refresh) {
            _searchResults = temples;
            _isSearching = false;
          } else {
            // Append unique items by id
            final existingIds = _searchResults.map((t) => t.templeId ?? t.displayTitle).toSet();
            final uniques = temples.where((t) => !existingIds.contains(t.templeId ?? t.displayTitle)).toList();
            _searchResults.addAll(uniques);
            _isLoadingMore = false;
          }
          // Determine if more data is available
          _hasMore = temples.length >= _pageSize;
        });
        
        return;
      } catch (e) {
        // If main search fails, try individual temple search
        try {
          final response = await _apiService.getTempleByTitle(query);
          if (response['templeId'] != null) {
            final temple = TempleModel.fromJson(response);
            temples = [temple];
            
            if (!mounted || localToken != _searchToken) return;
            setState(() {
              if (refresh) {
                _searchResults = temples;
                _isSearching = false;
              } else {
                _searchResults.addAll(temples);
                _isLoadingMore = false;
              }
              _hasMore = false;
            });
            return;
          }
        } catch (fallbackError) {
          // Handle fallback error silently
        }
      }
      
      // If both methods fail, show error
      if (!mounted || localToken != _searchToken) return;
      if (refresh) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _errorMessage = 'Temple search service is temporarily unavailable. Please try again later.';
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted || localToken != _searchToken) return;
      setState(() {
        if (refresh) {
          _searchResults = [];
          _isSearching = false;
          _errorMessage = 'Temple search service is temporarily unavailable. Please try again later.';
        } else {
          _isLoadingMore = false;
        }
      });
    }
  }

  void _onScroll() {
    // Cancel any existing scroll debounce timer
    _scrollDebounce?.cancel();
    
    // Use debounce timer to prevent excessive scroll events
    _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
      _handleScrollEvent();
    });
  }
  
  void _handleScrollEvent() {
    if (!_hasMore || _isLoadingMore || _isSearching) return;
    // Load more when user reaches 70% of the scroll (instead of 200px from bottom)
    // This provides better UX by loading content before user hits the bottom
    final scrollPosition = _scrollController.position.pixels;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    
    if (maxScrollExtent > 0 && scrollPosition >= maxScrollExtent * 0.7) {
      // Load next page
      _currentPage += 1;
      _performSearch(_searchController.text.trim(), refresh: false, callerToken: _searchToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCreamColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Search Temples'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(AppTheme.spacingXL),
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL, vertical: AppTheme.spacingXS),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusXL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search temple names...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                                          Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXL),
                        ),
                      child: IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear, size: 20),
                        color: Colors.grey[600],
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Note about English content
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      'Temple information is provided in English. Use English temple names or locations to discover sacred places.',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Error message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Loading indicator - positioned below the info note
            if (_isSearching)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Searching temples...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Search results or empty states
            if (!_isSearching) // Only show content when not loading
              Expanded(
                child: _searchResults.isEmpty && _searchController.text.length >= 3
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No temples found',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Try different keywords or check your spelling',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: const Text(
                                    'Try Again',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _searchController.text.length < 3
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Icon(
                                        Icons.temple_hindu,
                                        size: 64,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      _searchController.text.isEmpty 
                                          ? 'All Temples'
                                          : 'Search Temples',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isEmpty
                                          ? 'You can find comprehensive information on Punya Kshetras, Teertha Yatras, Temples, and many more sacred places here.'
                                          : 'Enter at least 3 characters to search',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),
                                    if (_searchController.text.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: const Text(
                                          'Start Exploring',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  controller: _scrollController,
                  itemCount: _searchResults.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _searchResults.length) {
                      // Bottom loader while fetching next page
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading more temples...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final temple = _searchResults[index];
                    return _buildSearchResult(temple);
                  },
                ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResult(TempleModel temple) {
    return GestureDetector(
      onTap: () {
        // Navigate to temple reading screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TempleReadingScreen(
              templeId: temple.templeId ?? '',
              temple: temple.toJson(), // Keep for backward compatibility
            ),
          ),
        );
      },
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
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.temple_hindu,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temple.displayTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (temple.hasContent)
                      Text(
                        temple.contentPreview,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // Relevance indicator

                    const SizedBox(height: 12),
                    if (temple.categoryDisplay.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          temple.categoryDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to calculate relevance score for temple search
  int _calculateRelevanceScore(String title, String query) {
    if (query.isEmpty) return 0;
    
    final t = title.toLowerCase();
    final q = query.toLowerCase();
    
    // Split query into words for better matching
    final queryWords = q.split(' ').where((word) => word.isNotEmpty).toList();
    
    int score = 0;
    
    // Exact title match gets highest score
    if (t == q) {
      score += 10000;
    }
    
    // Title starts with query gets very high score
    if (t.startsWith(q)) {
      score += 5000;
    }
    
    // Title ends with query gets high score
    if (t.endsWith(q)) {
      score += 3000;
    }
    
    // Check each query word with better weighting
    for (final word in queryWords) {
      if (word.length < 2) continue; // Skip very short words
      
      // Word at start of title (highest priority)
      if (t.startsWith(word)) {
        score += 2000;
      }
      // Word at end of title (high priority)
      else if (t.endsWith(word)) {
        score += 1500;
      }
      // Word at word boundary (after space, dash, etc.)
      else if (RegExp(r'(?:^|\s|[-_.,:/()])' + RegExp.escape(word)).hasMatch(t)) {
        score += 1000;
      }
      // Word appears anywhere in title
      else if (t.contains(word)) {
        score += 200; // Reduced from 500 to prevent generic word inflation
      }
    }
    
    // Special bonus for "ganesh" related matches
    if (q.contains('ganesh') || q.contains('ganesha')) {
      if (t.contains('ganesh') || t.contains('ganesha') || t.contains('vignesh') || t.contains('vigneshwara')) {
        score += 2000; // Extra bonus for ganesh-related temples
      }
      // Only give context bonus if the temple actually contains ganesh-related content
      if ((t.contains('ganesh') || t.contains('ganesha') || t.contains('vignesh') || t.contains('vigneshwara')) &&
          (t.contains('temple') || t.contains('mandir') || t.contains('ashram'))) {
        score += 200; // Reduced context bonus
      }
    }
    
    // Special bonus for "hanuman" related matches
    if (q.contains('hanuman') || q.contains('hanumana')) {
      if (t.contains('hanuman') || t.contains('hanumana')) {
        score += 2000; // Extra bonus for hanuman temples
      }
      // Only give context bonus if the temple actually contains hanuman-related content
      if ((t.contains('hanuman') || t.contains('hanumana')) &&
          (t.contains('temple') || t.contains('mandir') || t.contains('ashram'))) {
        score += 200; // Reduced context bonus
      }
    }
    
    // Special bonus for "shiva" related matches
    if (q.contains('shiva') || q.contains('siva')) {
      if (t.contains('shiva') || t.contains('siva')) {
        score += 2000; // Extra bonus for shiva temples
      }
      // Only give context bonus if the temple actually contains shiva-related content
      if ((t.contains('shiva') || t.contains('siva')) &&
          (t.contains('temple') || t.contains('mandir') || t.contains('ashram'))) {
        score += 200; // Reduced context bonus
      }
    }
    
    // Bonus for shorter titles (more specific matches)
    score += (200 - title.length).clamp(0, 100);
    
    // Debug logging for specific cases
    
    return score;
  }
} 