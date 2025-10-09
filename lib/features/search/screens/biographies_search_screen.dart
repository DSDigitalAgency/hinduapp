import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hindu_connect/services/logger_service.dart';
import '../../../constants/app_theme.dart';
import '../providers/biographies_search_provider.dart';
import '../widgets/search_bar.dart' as search_widgets;
import '../widgets/search_result_card.dart';
import '../widgets/loading_widgets.dart';
import '../widgets/empty_states.dart';
import '../widgets/info_banner.dart';
import '../models/search_state.dart';
import '../../../screens/biography_reading_screen.dart';

class BiographiesSearchScreen extends ConsumerStatefulWidget {
  const BiographiesSearchScreen({super.key});

  @override
  ConsumerState<BiographiesSearchScreen> createState() =>
      _BiographiesSearchScreenState();
}

class _BiographiesSearchScreenState
    extends ConsumerState<BiographiesSearchScreen> {
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
      ref.read(biographiesSearchProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    ref.read(biographiesSearchProvider.notifier).search(query);
  }

  void _onClear() {
    _controller.clear();
    ref.read(biographiesSearchProvider.notifier).clear();
  }

  void _onRetry() {
    ref.read(biographiesSearchProvider.notifier).retry();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(biographiesSearchProvider);

    return Scaffold(
      backgroundColor: AppTheme.warmCreamColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Search Biographies'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          search_widgets.SearchBar(
            controller: _controller,
            hintText: 'Search saints, gurus, spiritual leaders...',
            onChanged: _onSearchChanged,
            onClear: _onClear,
            showClearButton: _controller.text.isNotEmpty,
          ),

          // Info Banner
          const InfoBanner(
            message:
                'Biography information is provided in English. Use English names or titles to discover inspiring life stories.',
            icon: Icons.person,
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
        message: 'Discover Spiritual Lives',
        description:
            'You can find comprehensive information on saints, sages, spiritual leaders, and many more inspiring personalities here.',
        icon: Icons.person,
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
          const LoadingIndicator(message: 'Searching biographies...'),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const SkeletonCard()),
        ],
      );
    }

    if (searchState.status == SearchStatus.noResults) {
      return NoResultsState(query: searchState.query);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: searchState.results.length + (searchState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == searchState.results.length) {
          return const LoadingIndicator(message: 'Loading more biographies...');
        }

        final biography = searchState.results[index];
        logger.debug(
          'Rendering biography: title: ${biography.displayTitle} id: (${biography.id}) content: ${biography.displayContent}',
        );
        return SearchResultCard(
          title: biography.displayTitle,
          preview: biography.displayContent,
          icon: Icons.person,
          onTap: () => _navigateToReading(biography),
        );
      },
    );
  }

  void _navigateToReading(dynamic biography) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BiographyReadingScreen(
          title: biography.displayTitle,
          content: biography.displayContent,
          biographyId: biography.biographyId ?? biography.id ?? '',
        ),
      ),
    );
  }
}
