class Category {
  final String id;
  final String name;
  final int productCount;
  final List<Category> children;

  const Category({
    required this.id,
    required this.name,
    required this.productCount,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final childrenRaw = json['children'] as List? ?? [];
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
      children: childrenRaw
          .whereType<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList(),
    );
  }
}
