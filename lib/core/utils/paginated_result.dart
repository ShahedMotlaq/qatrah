class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
  });

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT, {
    String contentKey = 'content',
  }) {
    final List<dynamic> rawList;
    if (json[contentKey] is List) {
      rawList = json[contentKey] as List;
    } else if (json['data'] is List) {
      rawList = json['data'] as List;
    } else if (json['data'] is Map &&
        (json['data'] as Map)[contentKey] is List) {
      rawList = (json['data'] as Map)[contentKey] as List;
    } else if (json['items'] is List) {
      rawList = json['items'] as List;
    } else {
      rawList = [];
    }

    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(fromJsonT)
        .toList();

    final pageable = json['pageable'] as Map<String, dynamic>?;

    return PaginatedResult(
      items: items,
      currentPage:
          pageable?['pageNumber'] as int? ??
          (json['number'] as num?)?.toInt() ??
          0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? items.length,
      isLast: json['last'] as bool? ?? true,
    );
  }

  factory PaginatedResult.empty() => const PaginatedResult(
    items: [],
    currentPage: 0,
    totalPages: 0,
    totalElements: 0,
    isLast: true,
  );
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  bool get hasMore => !isLast;
}
