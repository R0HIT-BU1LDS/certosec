import '../core/utils/model_utils.dart';

/// Paginated wraps a page of list results together with the pagination
/// metadata the server reports. `T` is the item model.
///
/// [Paginated.fromJson] accepts the two most common Express pagination
/// shapes and normalizes them:
///   {items: [...], total, page, pageSize, totalPages}
///   {data: [...], meta: {total, page, pageSize, totalPages}}
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final itemsJson = ModelUtils.pickList(json, ['items', 'data', 'results']);
    final items = itemsJson
        .map((item) => fromItem(item as Map<String, dynamic>))
        .toList(growable: false);

    final meta = ModelUtils.pickMap(json, ['meta']);
    final total = ModelUtils.pickInt(
      json,
      ['total', 'count'],
      fallback: items.length,
      meta: meta,
    );
    final page = ModelUtils.pickInt(json, ['page'], fallback: 1, meta: meta);
    final pageSize = ModelUtils.pickInt(
      json,
      ['pageSize', 'page_size', 'limit', 'perPage'],
      fallback: items.isEmpty ? 1 : items.length,
      meta: meta,
    );
    final totalPages = ModelUtils.pickInt(
      json,
      ['totalPages', 'total_pages', 'pages'],
      fallback: total == 0 ? 0 : (total / pageSize).ceil(),
      meta: meta,
    );

    return Paginated(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }
}
