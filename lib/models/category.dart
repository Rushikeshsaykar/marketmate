class Category {
  final String id;
  final String name;
  final int productCount;

  const Category({
    required this.id,
    required this.name,
    required this.productCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    );
  }
}
