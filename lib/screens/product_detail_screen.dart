import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../core/config.dart';
import '../models/product_detail.dart';
import '../providers/product_detail_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/price_text.dart';

class ProductDetailScreen extends StatelessWidget {
  final String sku;

  const ProductDetailScreen({
    super.key,
    required this.sku,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailProvider(sku: sku)..load(),
      child: _ProductDetailView(sku: sku),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  final String sku;

  const _ProductDetailView({required this.sku});

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildNetworkImage(String url, {required bool isHero}) {
    final imageWidget = Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey.shade400,
            size: 48,
          ),
        );
      },
    );

    if (isHero) {
      return Hero(
        tag: widget.sku,
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _buildImageGallery(ProductDetail product) {
    final images = product.mediaGallery;

    if (images.isEmpty) {
      return Container(
        height: 360,
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: Colors.grey.shade400,
            size: 56,
          ),
        ),
      );
    }

    if (images.length == 1) {
      return Container(
        height: 360,
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: _buildNetworkImage(images.first, isHero: true),
      );
    }

    return Container(
      height: 380,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: _buildNetworkImage(
                  images[index],
                  isHero: index == 0,
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                final isSelected = _currentImageIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.indigo
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(ProductDetail product) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'SKU: ${product.sku}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: product.isInStock
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: product.isInStock
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      product.isInStock
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 14,
                      color: product.isInStock
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      product.isInStock ? 'In stock' : 'Out of stock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: product.isInStock
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PriceText(
            regularPrice: product.regularPrice,
            finalPrice: product.finalPrice,
            currency: product.currency,
            discountPercent: product.discountPercent,
            showBadge: true,
            priceStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.indigo,
            ),
            regularPriceStyle: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 20),
          if (product.shortDescription.isNotEmpty) ...[
            Html(
              data: product.shortDescription,
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(14),
                  color: const Color(0xFF4B5563),
                  lineHeight: const LineHeight(1.5),
                ),
              },
            ),
            const SizedBox(height: 16),
          ],
          if (product.description.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Html(
              data: product.description,
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(14),
                  color: const Color(0xFF4B5563),
                  lineHeight: const LineHeight(1.6),
                ),
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 24,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 28,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductDetailProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          provider.product?.name ?? 'Product Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      bottomNavigationBar: provider.product != null
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demo only'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Add to cart'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            )
          : null,
      body: Builder(
        builder: (context) {
          if (provider.status == ProviderStatus.loading) {
            return _buildShimmerLoading();
          }

          if (provider.status == ProviderStatus.error) {
            return ErrorView(
              message: provider.errorMessage,
              onRetry: () => provider.load(),
            );
          }

          final product = provider.product;
          if (product == null) {
            return const EmptyView(
              title: 'Product not found',
              message: 'The requested product could not be loaded.',
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              if (isWide) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildImageGallery(product),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 6,
                            child: _buildProductInfo(product),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(product),
                    _buildProductInfo(product),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
