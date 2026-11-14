import '../core/config.dart';

class Product {
  final String id;
  final String name;
  final String sku;
  final String stockStatus;
  final bool isInStock;
  final String imageUrl;
  final String imageLabel;
  final double regularPrice;
  final double finalPrice;
  final String currency;
  final double discountPercent;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.stockStatus,
    required this.isInStock,
    required this.imageUrl,
    required this.imageLabel,
    required this.regularPrice,
    required this.finalPrice,
    required this.currency,
    required this.discountPercent,
  });

  bool get hasDiscount => discountPercent > 0 && regularPrice > finalPrice;

  factory Product.fromJson(Map<String, dynamic> json) {
    final smallImage = json['small_image'] as Map<String, dynamic>?;
    final rawUrl = smallImage?['url']?.toString() ?? '';
    final fixedUrl = rawUrl.isNotEmpty ? fixImageUrl(rawUrl) : '';

    final priceRange = json['price_range'] as Map<String, dynamic>?;
    final minPrice = priceRange?['minimum_price'] as Map<String, dynamic>?;
    final regularPriceObj = minPrice?['regular_price'] as Map<String, dynamic>?;
    final finalPriceObj = minPrice?['final_price'] as Map<String, dynamic>?;
    final discountObj = minPrice?['discount'] as Map<String, dynamic>?;

    final finalVal = (finalPriceObj?['value'] as num?)?.toDouble() ?? 0.0;
    final regVal = (regularPriceObj?['value'] as num?)?.toDouble() ?? finalVal;
    final curr = finalPriceObj?['currency']?.toString() ??
        regularPriceObj?['currency']?.toString() ??
        'USD';
    final discountPercent =
        (discountObj?['percent_off'] as num?)?.toDouble() ?? 0.0;
    final status = json['stock_status']?.toString() ?? 'OUT_OF_STOCK';

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      stockStatus: status,
      isInStock: status.toUpperCase() == 'IN_STOCK',
      imageUrl: fixedUrl,
      imageLabel: smallImage?['label']?.toString() ?? '',
      regularPrice: regVal,
      finalPrice: finalVal,
      currency: curr,
      discountPercent: discountPercent,
    );
  }
}

class PageInfo {
  final int currentPage;
  final int totalPages;

  const PageInfo({
    required this.currentPage,
    required this.totalPages,
  });

  factory PageInfo.fromJson(Map<String, dynamic>? json) {
    return PageInfo(
      currentPage: (json?['current_page'] as num?)?.toInt() ?? 1,
      totalPages: (json?['total_pages'] as num?)?.toInt() ?? 1,
    );
  }
}

class ProductsResponse {
  final int totalCount;
  final PageInfo pageInfo;
  final List<Product> items;

  const ProductsResponse({
    required this.totalCount,
    required this.pageInfo,
    required this.items,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    final pageInfo =
        PageInfo.fromJson(json['page_info'] as Map<String, dynamic>?);
    final itemsList = json['items'] as List? ?? [];
    final items = itemsList
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();

    return ProductsResponse(
      totalCount: (json['total_count'] as num?)?.toInt() ?? items.length,
      pageInfo: pageInfo,
      items: items,
    );
  }
}
