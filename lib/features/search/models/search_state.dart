enum SearchStatus { idle, searching, loadingMore, success, error, noResults }

enum SearchType { sacredTexts, temples, biographies }

class SearchState<T> {
  final SearchStatus status;
  final String query;
  final List<T> results;
  final bool hasMore;
  final int currentPage;
  final int totalResults;
  final String? error;
  final bool isPreloading;

  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    required this.results,
    this.hasMore = false,
    this.currentPage = 1,
    this.totalResults = 0,
    this.error,
    this.isPreloading = false,
  });

  // Factory constructor for creating empty state
  factory SearchState.empty() {
    return SearchState<T>(results: <T>[]);
  }

  bool get isLoading => status == SearchStatus.searching;
  bool get isLoadingMore => status == SearchStatus.loadingMore;
  bool get isError => status == SearchStatus.error;
  bool get isEmpty => results.isEmpty && !isLoading;
  bool get hasResults => results.isNotEmpty;

  SearchState<T> copyWith({
    SearchStatus? status,
    String? query,
    List<T>? results,
    bool? hasMore,
    int? currentPage,
    int? totalResults,
    String? error,
    bool? isPreloading,
  }) {
    return SearchState<T>(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalResults: totalResults ?? this.totalResults,
      error: error ?? this.error,
      isPreloading: isPreloading ?? this.isPreloading,
    );
  }
}
