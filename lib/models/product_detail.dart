import '../core/config.dart';

class ProductDetail {
  final String id;
  final String name;
  final String sku;
  final String stockStatus;
  final bool isInStock;
  final String shortDescription;
  final String description;
  final String imageUrl;
  final List<String> mediaGallery;
  final double regularPrice;
  final double finalPrice;
  final String currency;
  final double discountPercent;
  final List<String> categories;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.sku,
    required this.stockStatus,
    required this.isInStock,
    required this.shortDescription,
    required this.description,
    required this.imageUrl,
    required this.mediaGallery,
    required this.regularPrice,
    required this.finalPrice,
    required this.currency,
    required this.discountPercent,
    required this.categories,
  });

  bool get hasDiscount => discountPercent > 0 && regularPrice > finalPrice;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final imageMap = json['image'] as Map<String, dynamic>?;
    final rawMainUrl = imageMap?['url']?.toString() ?? '';
    final fixedMainUrl =
        rawMainUrl.isNotEmpty ? fixImageUrl(rawMainUrl) : '';

    final rawGallery = json['media_gallery'] as List? ?? [];
    final List<String> gallery = [];
    for (final item in rawGallery) {
      if (item is Map<String, dynamic>) {
        final url = item['url']?.toString();
        if (url != null && url.isNotEmpty) {
          gallery.add(fixImageUrl(url));
        }
      }
    }

    // media_gallery may be empty; fall back to image.url
    if (gallery.isEmpty && fixedMainUrl.isNotEmpty) {
      gallery.add(fixedMainUrl);
    }

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

    final shortDescObj = json['short_description'] as Map<String, dynamic>?;
    final descObj = json['description'] as Map<String, dynamic>?;

    final categoriesList = json['categories'] as List? ?? [];
    final categoryNames = categoriesList
        .whereType<Map<String, dynamic>>()
        .map((c) => c['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    return ProductDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      stockStatus: status,
      isInStock: status.toUpperCase() == 'IN_STOCK',
      shortDescription: shortDescObj?['html']?.toString() ?? '',
      description: descObj?['html']?.toString() ?? '',
      imageUrl: fixedMainUrl,
      mediaGallery: gallery,
      regularPrice: regVal,
      finalPrice: finalVal,
      currency: curr,
      discountPercent: discountPercent,
      categories: categoryNames,
    );
  }
}
