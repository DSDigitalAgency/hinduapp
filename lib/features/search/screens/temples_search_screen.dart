import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_theme.dart';
import '../providers/temples_search_provider.dart';
import '../widgets/search_bar.dart' as search_widgets;
import '../widgets/search_result_card.dart';
import '../widgets/loading_widgets.dart';
import '../widgets/empty_states.dart';
import '../widgets/info_banner.dart';
import '../models/search_state.dart';
import '../../../screens/temple_reading_screen.dart';

class TemplesSearchScreen extends ConsumerStatefulWidget {
  const TemplesSearchScreen({super.key});

  @override
  ConsumerState<TemplesSearchScreen> createState() =>
      _TemplesSearchScreenState();
}

class _TemplesSearchScreenState extends ConsumerState<TemplesSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      ref.read(templesSearchProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    ref.read(templesSearchProvider.notifier).search(query);
  }

  void _onClear() {
    _controller.clear();
    ref.read(templesSearchProvider.notifier).clear();
  }

  void _onRetry() {
    ref.read(templesSearchProvider.notifier).retry();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(templesSearchProvider);

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
          // Search Bar
          search_widgets.SearchBar(
            controller: _controller,
            hintText: 'Search temples, deities, locations...',
            onChanged: _onSearchChanged,
            onClear: _onClear,
            showClearButton: _controller.text.isNotEmpty,
          ),

          // Info Banner
          const InfoBanner(
            message:
                'Temple information is provided in English. Use English temple names or locations to discover sacred places.',
            icon: Icons.info_outline,
            backgroundColor: AppTheme.primaryColor,
            borderColor: AppTheme.primaryColor,
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(child: _buildContent(searchState)),
        ],
      ),
    );
  }

  Widget _buildContent(SearchState searchState) {
    if (searchState.query.isEmpty) {
      return const EmptyState(
        message: 'Discover Sacred Temples',
        description:
            'You can find comprehensive information on Punya Kshetras, Teertha Yatras, Temples, and many more sacred places here.',
        icon: Icons.temple_hindu,
      );
    }

    if (searchState.query.length < 3) {
      return const EmptyState(
        message: 'Keep Typing...',
        description: 'Please enter at least 3 characters to search.',
        icon: Icons.keyboard,
      );
    }

    if (searchState.isError) {
      return ErrorState(
        error: searchState.error ?? 'An error occurred',
        onRetry: _onRetry,
      );
    }

    if (searchState.isLoading && searchState.results.isEmpty) {
      return Column(
        children: [
          const LoadingIndicator(message: 'Searching temples...'),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const SkeletonCard()),
        ],
      );
    }

    if (searchState.status == SearchStatus.noResults) {
      return NoResultsState(query: searchState.query);
    }

    // Results list with progress indicator
    if (searchState.results.isNotEmpty) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXL,
              vertical: AppTheme.spacingM,
            ),
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
              border: Border.all(
                color: Colors.blue[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Showing ${searchState.results.length} out of ${searchState.totalResults} results',
                        style: TextStyle(
                          color: Colors.blue[700]!,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (searchState.hasMore)
                        Text(
                          'Scroll to load more',
                          style: TextStyle(
                            color: Colors.blue[700]!,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
                  searchState.results.length + (searchState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == searchState.results.length) {
                  return const LoadingIndicator(
                    message: 'Loading more temples...',
                  );
                }

                final temple = searchState.results[index];
                return SearchResultCard(
                  title: temple.displayTitle,
                  preview: temple.contentPreview,
                  icon: Icons.temple_hindu,
                  onTap: () => _navigateToReading(temple),
                );
              },
            ),
          ),
        ],
      );
    }

    // If no results, return empty container
    return Container();
    
  }

  void _navigateToReading(dynamic temple) {
    // Get the temple ID - priority: templeId, _id, id
    String templeId = '';
    if (temple.templeId != null && temple.templeId!.isNotEmpty) {
      templeId = temple.templeId!;
    } else if (temple.id != null && temple.id!.isNotEmpty) {
      templeId = temple.id!;
    } else if (temple.toJson().containsKey('_id') &&
        temple.toJson()['_id'] != null) {
      templeId = temple.toJson()['_id'].toString();
    }

    if (templeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open temple: Invalid ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TempleReadingScreen(
          templeId: templeId,
          // Don't pass temple data - let the reading screen fetch full content from API
        ),
      ),
    );
  }
}
