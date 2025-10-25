class PaginationConfig {
  final int pageSize;
  final int initialPage;

  const PaginationConfig({
    this.pageSize = 20,
    this.initialPage = 0,
  });
}

class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final bool hasMore;
  final int totalCount;

  PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.totalCount = 0,
  });
}
