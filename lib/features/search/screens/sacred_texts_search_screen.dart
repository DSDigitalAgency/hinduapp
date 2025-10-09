import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hindu_connect/providers/language_provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/font_utils.dart';
import '../providers/sacred_texts_search_provider.dart';
import '../widgets/search_bar.dart' as search_widgets;
import '../widgets/search_result_card.dart';
import '../widgets/loading_widgets.dart';
import '../widgets/empty_states.dart';
import '../widgets/info_banner.dart';
import '../models/search_state.dart';
import '../../../screens/sacred_text_reading_screen.dart';

class SacredTextsSearchScreen extends ConsumerStatefulWidget {
  const SacredTextsSearchScreen({super.key});

  @override
  ConsumerState<SacredTextsSearchScreen> createState() =>
      _SacredTextsSearchScreenState();
}

class _SacredTextsSearchScreenState
    extends ConsumerState<SacredTextsSearchScreen> {
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
      ref.read(sacredTextsSearchProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    ref.read(sacredTextsSearchProvider.notifier).search(query);
  }

  void _onClear() {
    _controller.clear();
    ref.read(sacredTextsSearchProvider.notifier).clear();
  }

  void _onRetry() {
    ref.read(sacredTextsSearchProvider.notifier).retry();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(sacredTextsSearchProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);
    return Scaffold(
      backgroundColor: AppTheme.warmCreamColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Search Sacred Texts',
          style: FontUtils.getTextStyleForLanguage(
            currentLanguage,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
            decoration: TextDecoration.none,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                currentLanguage,
                style: FontUtils.getTextStyleForLanguage(
                  currentLanguage,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          search_widgets.SearchBar(
            controller: _controller,
            hintText: 'Search hymns, mantras, chants...',
            onChanged: _onSearchChanged,
            onClear: _onClear,
            showClearButton: _controller.text.isNotEmpty,
          ),

          // Info Banner
          const InfoBanner(
            message:
                'You can search in English or in your preferred language; results will be shown in your preferred language.',
            icon: Icons.language,
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(child: _buildContent(searchState, currentLanguage)),
        ],
      ),
    );
  }

  Widget _buildContent(SearchState searchState, String currentLanguage) {
    if (searchState.query.isEmpty) {
      return const EmptyState(
        message: 'Sacred Texts Library',
        description:
            'You can find Vedas, Upavedas, Upanishads, Puranas, Itihasas, Dharma Shastras, Agama Shastras, Prabandhas, Keerthanas, Sakala Devata Stotras, and much more Hindu literature here.',
        icon: Icons.auto_stories,
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
          const LoadingIndicator(message: 'Searching sacred texts...'),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const SkeletonCard()),
        ],
      );
    }

    if (searchState.status == SearchStatus.noResults) {
      return NoResultsState(query: searchState.query);
    }
    // Progress notice and results list
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
                        style: FontUtils.getTextStyleForLanguage(
                          currentLanguage,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700]!,
                          height: 1.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (searchState.hasMore)
                        Text(
                          'Scroll to load more',
                          style: FontUtils.getTextStyleForLanguage(
                            currentLanguage,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.blue[700]!,
                            height: 1.2,
                            decoration: TextDecoration.none,
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
                    message: 'Loading more texts...',
                  );
                }

                final sacredText = searchState.results[index];
                return SearchResultCard(
                  title: sacredText.displayTitle,
                  preview: sacredText.contentPreview,
                  icon: Icons.auto_stories,
                  currentLanguage: currentLanguage,
                  onTap: () => _navigateToReading(sacredText),
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

  void _navigateToReading(dynamic sacredText) {
    // Get the sacred text ID - priority: sacredTextId, _id, id
    String sacredTextId = '';
    if (sacredText.sacredTextId != null &&
        sacredText.sacredTextId!.isNotEmpty) {
      sacredTextId = sacredText.sacredTextId!;
    } else if (sacredText.id != null && sacredText.id!.isNotEmpty) {
      sacredTextId = sacredText.id!;
    } else if (sacredText.toJson().containsKey('_id') &&
        sacredText.toJson()['_id'] != null) {
      sacredTextId = sacredText.toJson()['_id'].toString();
    }

    if (sacredTextId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open sacred text: Invalid ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Log the clicked search result model data
    if (sacredText.excerpt != null && sacredText.excerpt!.isNotEmpty) {
      // Preview available
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SacredTextReadingScreen(
          sacredTextId: sacredTextId,
          sacredText: sacredText.toJson(), // Pass the sacredText data
        ),
      ),
    );
  }
}
