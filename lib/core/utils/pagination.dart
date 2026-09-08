// lib/core/utils/pagination.dart

/// Generic pagination model for API responses
class Pagination<T> {
  const Pagination({
    required this.totalPages,
    required this.totalElements,
    required this.currentPage,
    required this.pageSize,
    required this.content,
    required this.isFirst,
    required this.isLast,
    required this.isEmpty,
  });

  /// Create from JSON with custom mapper
  factory Pagination.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final contentList = json['content'] as List? ?? [];

    // Safe extraction with null handling
    final pageable = json['pageable'] as Map<String, dynamic>?;
    final sort = json['sort'] as Map<String, dynamic>?;

    return Pagination(
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      currentPage: (pageable?['pageNumber'] as num?)?.toInt() ?? 0,
      pageSize: (pageable?['pageSize'] as num?)?.toInt() ?? 10,
      content: contentList
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      isFirst: json['first'] as bool? ?? true,
      isLast: json['last'] as bool? ?? true,
      isEmpty: json['empty'] as bool? ?? true,
    );
  }

  /// Create empty pagination
  factory Pagination.empty() {
    return const Pagination(
      totalPages: 0,
      totalElements: 0,
      currentPage: 0,
      pageSize: 10,
      content: [],
      isFirst: true,
      isLast: true,
      isEmpty: true,
    );
  }
  final int totalPages;
  final int totalElements;
  final int currentPage;
  final int pageSize;
  final List<T> content;
  final bool isFirst;
  final bool isLast;
  final bool isEmpty;

  /// Map content to different type
  Pagination<R> map<R>(R Function(T) mapper) {
    return Pagination<R>(
      totalPages: totalPages,
      totalElements: totalElements,
      currentPage: currentPage,
      pageSize: pageSize,
      content: content.map(mapper).toList(),
      isFirst: isFirst,
      isLast: isLast,
      isEmpty: isEmpty,
    );
  }

  @override
  String toString() {
    return 'Pagination(totalPages: $totalPages, totalElements: $totalElements, contentLength: ${content.length})';
  }
}
