import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/biography_model.dart';
import 'biography_reading_screen.dart';

class BiographiesSearchScreen extends StatefulWidget {
  const BiographiesSearchScreen({super.key});

  @override
  State<BiographiesSearchScreen> createState() => _BiographiesSearchScreenState();
}

class _BiographiesSearchScreenState extends State<BiographiesSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  Timer? _debounce;
  Timer? _scrollDebounce; // Add scroll debounce timer
  
  List<BiographyModel> _searchResults = [];
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
      List<BiographyModel> biographies = [];
      
      // Try the main biography search API first
      try {
                 final response = await _apiService.searchBiographies({
          'q': query,
           'page': _currentPage.toString(),
           'limit': _pageSize.toString(),
          'sortOrder': 'desc',
          'fuzzy': 'false',
           'sortBy': 'relevance',
         });
        
        final results = ApiService.safeCastToList(response, 'biographies');
        biographies = results.map((json) => BiographyModel.fromJson(json)).toList();
        
        if (!mounted || localToken != _searchToken) return;
        setState(() {
          if (refresh) {
            _searchResults = biographies;
          _isSearching = false;
          } else {
            // Append unique items by id
            final existingIds = _searchResults.map((b) => b.biographyId ?? b.id).toSet();
            final uniques = biographies.where((b) => !existingIds.contains(b.biographyId ?? b.id)).toList();
            _searchResults.addAll(uniques);
            _isLoadingMore = false;
          }
          // Determine if more data is available
          _hasMore = biographies.length >= _pageSize;
        });
        
        return;
      } catch (e) {
        // If main search fails, try fallback methods
                 try {
           final response = await _apiService.biographySearch({
             'q': query,
             'page': _currentPage.toString(),
             'limit': _pageSize.toString(),
             'sortOrder': 'desc',
             'fuzzy': 'false',
             'sortBy': 'relevance',
           });
          
          final results = ApiService.safeCastToList(response, 'biographies');
          biographies = results.map((json) => BiographyModel.fromJson(json)).toList();
          
        if (!mounted || localToken != _searchToken) return;
        setState(() {
            if (refresh) {
              _searchResults = biographies;
          _isSearching = false;
            } else {
              _searchResults.addAll(biographies);
              _isLoadingMore = false;
            }
            _hasMore = biographies.length >= _pageSize;
          });
          return;
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
          _errorMessage = 'Biography search service is temporarily unavailable. Please try again later.';
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
          _errorMessage = 'Biography search service is temporarily unavailable. Please try again later.';
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
      backgroundColor: const Color(0xFFFFFAF0),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Search Biographies'),
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
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
                    color: Color(0xFFFF9933),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search biography names...',
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
                        borderRadius: BorderRadius.circular(20),
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
              margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF9933).withValues(alpha: 0.1),
                    const Color(0xFFFF9933).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                  color: const Color(0xFFFF9933).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9933).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: const Color(0xFFFF9933),
                      size: 20,
                    ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                      'Biography information is provided in English. Use English names or titles to discover inspiring life stories.',
                      style: const TextStyle(
                        color: Color(0xFFFF9933),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9933)),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Searching biographies...',
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
                                  'No biographies found',
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
                                    color: const Color(0xFFFF9933),
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
                                        color: const Color(0xFFFF9933).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: 64,
                                        color: const Color(0xFFFF9933),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      _searchController.text.isEmpty 
                                          ? 'All Biographies'
                                          : 'Search Biographies',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF9933),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isEmpty
                                          ? 'You can find comprehensive information on saints, sages, spiritual leaders, and many more inspiring personalities here.'
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
                                          color: const Color(0xFFFF9933),
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
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9933)),
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading more biographies...',
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
                    final biography = _searchResults[index];
                    return _buildSearchResult(biography);
                  },
                ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResult(BiographyModel biography) {
    return GestureDetector(
      onTap: () => _navigateToReading(biography),
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
                  color: const Color(0xFFFF9933).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFFF9933),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      biography.displayTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (biography.excerpt != null && biography.excerpt!.isNotEmpty)
                      Text(
                        biography.excerpt!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                                         // Era or time period indicator if available
                     if (biography.era != null && biography.era!.isNotEmpty)
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(
                           color: const Color(0xFFFF9933).withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(
                             color: const Color(0xFFFF9933).withValues(alpha: 0.3),
                             width: 1,
                           ),
                         ),
                         child: Text(
                           biography.era!,
                           style: const TextStyle(
                             fontSize: 12,
                             color: Color(0xFFFF9933),
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                       ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFFF9933),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReading(BiographyModel biography) {
    // Get the biography ID - priority: biographyId, _id, id
    String biographyId = '';
    if (biography.biographyId != null && biography.biographyId!.isNotEmpty) {
      biographyId = biography.biographyId!;
    } else if (biography.id.isNotEmpty) {
      biographyId = biography.id;
    } else if (biography.toJson().containsKey('_id') &&
        biography.toJson()['_id'] != null) {
      biographyId = biography.toJson()['_id'].toString();
    }

    if (biographyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open biography: Invalid ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiographyReadingScreen(
          title: biography.displayTitle,
          biographyId: biographyId, // Pass biography ID for complete content
          // Don't pass preview content - let the reading screen fetch full content from API
        ),
      ),
    );
  }
  
  
}
