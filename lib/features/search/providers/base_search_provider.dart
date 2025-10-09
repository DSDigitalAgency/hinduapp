import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_state.dart';

abstract class BaseSearchNotifier<T> extends StateNotifier<SearchState<T>> {
  BaseSearchNotifier() : super(SearchState<T>.empty());

  Timer? _debounce;
  Timer? _scrollDebounce;
  int _searchToken = 0;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _scrollDebounceDelay = Duration(milliseconds: 100);
  static const int _pageSize = 20;
  static const int _minQueryLength = 3;

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollDebounce?.cancel();
    super.dispose();
  }

  /// Abstract method to perform the actual search
  Future<SearchResult<T>> performSearch(String query, int page, int limit);

  /// Abstract method to get display title for an item
  String getDisplayTitle(T item);

  /// Abstract method to get content preview for an item
  String getContentPreview(T item);

  /// Start search with debounce
  void search(String query) {
    _debounce?.cancel();

    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      state = SearchState<T>.empty();
      return;
    }

    if (trimmedQuery.length < _minQueryLength) {
      state = state.copyWith(
        query: trimmedQuery,
        results: <T>[],
        status: SearchStatus.idle,
        error: null,
      );
      return;
    }

    _debounce = Timer(_debounceDelay, () {
      if (mounted) {
        _searchToken++;
        _performSearch(trimmedQuery, refresh: true, token: _searchToken);
      }
    });
  }

  /// Load more results for pagination
  void loadMore() {
    _scrollDebounce?.cancel();

    _scrollDebounce = Timer(_scrollDebounceDelay, () {
      if (mounted &&
          state.hasMore &&
          !state.isLoadingMore &&
          !state.isLoading) {
        _performSearch(
          state.query,
          refresh: false,
          token: _searchToken,
          page: state.currentPage + 1,
        );
      }
    });
  }

  /// Clear search results
  void clear() {
    _debounce?.cancel();
    _scrollDebounce?.cancel();
    if (mounted) {
      state = SearchState<T>.empty();
    }
  }

  /// Retry current search
  void retry() {
    if (mounted && state.query.isNotEmpty) {
      _searchToken++;
      _performSearch(state.query, refresh: true, token: _searchToken);
    }
  }

  /// Refresh search when language changes
  void refreshForLanguageChange() {
    if (mounted &&
        state.query.isNotEmpty &&
        state.query.length >= _minQueryLength) {
      _searchToken++;
      _performSearch(state.query, refresh: true, token: _searchToken);
    }
  }

  /// Internal search method
  Future<void> _performSearch(
    String query, {
    required bool refresh,
    required int token,
    int? page,
  }) async {
    if (!mounted || token != _searchToken) return;

    final currentPage = page ?? (refresh ? 1 : state.currentPage);

    if (refresh) {
      state = state.copyWith(
        status: SearchStatus.searching,
        query: query,
        error: null,
        currentPage: 1,
        results: <T>[],
      );
    } else {
      state = state.copyWith(status: SearchStatus.loadingMore);
    }

    try {
      final result = await performSearch(query, currentPage, _pageSize);

      if (!mounted || token != _searchToken) return;

      final newResults = refresh
          ? result.items
          : [...state.results, ...result.items];

      state = state.copyWith(
        status: result.items.isEmpty && refresh
            ? SearchStatus.noResults
            : SearchStatus.success,
        results: newResults,
        hasMore: result.hasMore,
        currentPage: currentPage,
        totalResults: result.total,
        error: null,
      );
    } catch (error) {
      if (!mounted || token != _searchToken) return;

      state = state.copyWith(
        status: SearchStatus.error,
        error: _formatError(error),
      );
    }
  }

  /// Format error message
  String _formatError(dynamic error) {
    if (error is String) return error;
    return 'Search service is temporarily unavailable. Please try again later.';
  }
}

/// Search result wrapper
class SearchResult<T> {
  final List<T> items;
  final bool hasMore;
  final int total;

  const SearchResult({
    required this.items,
    required this.hasMore,
    required this.total,
  });
}
