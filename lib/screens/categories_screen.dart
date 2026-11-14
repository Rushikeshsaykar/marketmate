import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../core/config.dart';
import '../core/graphql_client.dart' as gql;
import '../core/queries.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/category_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import 'category_products_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedIndex = 0;
  final Map<String, List<Product>> _productsCache = {};
  final Set<String> _loadingCategories = {};

  final List<Color> _pastelColors = const [
    Color(0xFFE8EEFC), // Soft lavender blue
    Color(0xFFFEEFE4), // Soft peach
    Color(0xFFE5F5EC), // Soft mint green
    Color(0xFFF1F4F9), // Soft ice blue
    Color(0xFFEDE8FC), // Soft purple
    Color(0xFFFEECE0), // Soft warm apricot
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFirstCategory();
    });
  }

  void _initFirstCategory() {
    final provider = context.read<CategoryProvider>();
    if (provider.categories.isNotEmpty) {
      _fetchProductsForCategory(provider.categories[0]);
    }
  }

  Future<void> _fetchProductsForCategory(Category category,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _productsCache.containsKey(category.id)) {
      return;
    }

    if (_loadingCategories.contains(category.id)) {
      return;
    }

    setState(() {
      _loadingCategories.add(category.id);
    });

    try {
      final categoryIds = [
        category.id,
        ...category.children.map((c) => c.id),
      ];

      final data = await gql.query(
        productsQuery,
        variables: {
          'filter': {
            'category_id': {'in': categoryIds},
          },
          'page': 1,
          'size': 50,
        },
      );

      final productsData = data['products'] as Map<String, dynamic>? ?? {};
      final response = ProductsResponse.fromJson(productsData);

      if (mounted) {
        setState(() {
          _productsCache[category.id] = response.items;
          _loadingCategories.remove(category.id);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _productsCache[category.id] = [];
          _loadingCategories.remove(category.id);
        });
      }
    }
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cloth') ||
        lower.contains('fashion') ||
        lower.contains('apparel')) {
      return Icons.checkroom_rounded;
    }
    if (lower.contains('elect') ||
        lower.contains('gadget') ||
        lower.contains('tech') ||
        lower.contains('phone')) {
      return Icons.headphones_rounded;
    }
    if (lower.contains('furn') ||
        lower.contains('home') ||
        lower.contains('decor')) {
      return Icons.home_outlined;
    }
    if (lower.contains('gros') ||
        lower.contains('groc') ||
        lower.contains('food') ||
        lower.contains('market')) {
      return Icons.shopping_bag_outlined;
    }
    if (lower.contains('beauty') || lower.contains('cosmetic')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (lower.contains('sport') || lower.contains('fit')) {
      return Icons.public_rounded;
    }
    return Icons.widgets_outlined;
  }

  String _formatCategoryName(String rawName) {
    if (rawName.isEmpty) return rawName;
    final lower = rawName.toLowerCase();
    if (lower == 'cloths') return 'Fashion';
    if (lower == 'electronic') return 'Gadgets';
    if (lower == 'furniture') return 'Home';
    if (lower == 'grosary') return 'Grocery';
    return rawName[0].toUpperCase() + rawName.substring(1);
  }

  void _openCategoryProducts(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(
          category: category,
        ),
      ),
    );
  }

  void _openProductDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          sku: product.sku,
        ),
      ),
    );
  }

  List<_SubCategoryData> _buildSubCategories(
      Category category, List<Product> products) {
    final List<_SubCategoryData> sections = [];

    // If the category has explicit child subcategories from Magento API
    if (category.children.isNotEmpty) {
      for (final child in category.children) {
        // Filter strictly by this subcategory
        final matching = products
            .where((p) => p.matchesCategory(child.id, child.name))
            .toList();

        // Sort the products alphabetically
        matching.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (matching.isNotEmpty) {
          sections.add(
            _SubCategoryData(
              title: _formatCategoryName(child.name),
              category: child,
              products: matching,
              totalCount: child.productCount > matching.length
                  ? child.productCount
                  : matching.length,
            ),
          );
        }
      }

      // Products in the parent category that do not belong to any child subcategory
      final otherProducts = products.where((p) {
        return !category.children
            .any((child) => p.matchesCategory(child.id, child.name));
      }).toList();

      if (otherProducts.isNotEmpty) {
        otherProducts.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        sections.add(
          _SubCategoryData(
            title: 'More in ${_formatCategoryName(category.name)}',
            category: category,
            products: otherProducts,
            totalCount: otherProducts.length,
          ),
        );
      }
    } else {
      // Category has no children (e.g. electronic)
      final allSorted = List<Product>.from(products)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (allSorted.isNotEmpty) {
        sections.add(
          _SubCategoryData(
            title: 'All ${_formatCategoryName(category.name)}',
            category: category,
            products: allSorted,
            totalCount: allSorted.length,
          ),
        );
      }
    }

    return sections;
  }

  Widget _buildProductCircle(Product product, int index) {
    final bgColor = _pastelColors[index % _pastelColors.length];

    return InkWell(
      onTap: () => _openProductDetail(product),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.indigo.shade300,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.grey.shade400,
                            size: 26,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.grey.shade500,
                        size: 26,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '\$${product.finalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(height: 16, width: 120, color: Colors.white),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              itemCount: 6,
              itemBuilder: (_, _) => Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 50, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Categories',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF1F2937),
                size: 22,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SearchScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.status == ProviderStatus.loading) {
            return Row(
              children: [
                SizedBox(
                  width: 84,
                  child: ListView.builder(
                    itemCount: 6,
                    itemBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 10,
                              width: 48,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildRightShimmer()),
              ],
            );
          }

          if (provider.status == ProviderStatus.error) {
            return ErrorView(
              message: provider.errorMessage,
              onRetry: () => provider.load(),
            );
          }

          if (provider.categories.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: EmptyView(
                title: 'No categories found',
                message: 'No categories were found. Pull down to refresh.',
                onRefresh: () => provider.refresh(),
              ),
            );
          }

          final categories = provider.categories;
          final safeIndex =
              _selectedIndex >= categories.length ? 0 : _selectedIndex;
          final selectedCategory = categories[safeIndex];

          // Trigger fetch if not loaded
          if (!_productsCache.containsKey(selectedCategory.id) &&
              !_loadingCategories.contains(selectedCategory.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchProductsForCategory(selectedCategory);
            });
          }

          final isLoadingCurrent =
              _loadingCategories.contains(selectedCategory.id);
          final products = _productsCache[selectedCategory.id] ?? [];
          final subSections = _buildSubCategories(selectedCategory, products);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Category Directory Rail
              Container(
                width: 84,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(
                    right: BorderSide(
                      color: Color(0xFFF3F4F6),
                      width: 1.5,
                    ),
                  ),
                ),
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = index == safeIndex;
                    final displayName = _formatCategoryName(category.name);
                    final icon = _getCategoryIcon(category.name);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        _fetchProductsForCategory(category);
                      },
                      child: Stack(
                        children: [
                          if (isSelected)
                            Positioned(
                              left: 0,
                              top: 6,
                              bottom: 6,
                              child: Container(
                                width: 3.5,
                                decoration: const BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 6,
                            ),
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 26,
                                  color: isSelected
                                      ? Colors.indigo
                                      : const Color(0xFF4B5563),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  displayName,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.indigo
                                        : const Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Right Content Panel
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.refresh();
                    await _fetchProductsForCategory(selectedCategory,
                        forceRefresh: true);
                  },
                  child: isLoadingCurrent && products.isEmpty
                      ? _buildRightShimmer()
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Promo Banner ("New season")
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                child: InkWell(
                                  onTap: () =>
                                      _openCategoryProducts(selectedCategory),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0E5),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Text(
                                                'New season',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFFC2410C),
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Explore the latest drops',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF9A3412),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Color(0xFFC2410C),
                                          size: 26,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Subcategory Sections (Max 2 rows of 3 = 6 products per subcategory)
                              if (subSections.isEmpty && !isLoadingCurrent)
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      'No products in this category yet.',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...subSections.map((section) {
                                  final hasMore = section.totalCount > 6 ||
                                      section.products.length > 6;
                                  // Exactly allow maximum 2 rows (3 columns * 2 rows = 6 items)
                                  final visibleProducts =
                                      section.products.take(6).toList();

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Subcategory Header with "See more" if more products exist
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  section.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF111827),
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () =>
                                                    _openCategoryProducts(
                                                        section.category),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        hasMore
                                                            ? 'See more'
                                                            : 'View all',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.indigo,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      const Icon(
                                                        Icons
                                                            .chevron_right_rounded,
                                                        size: 16,
                                                        color: Colors.indigo,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Product Circles Grid (3 columns, max 2 rows)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              childAspectRatio: 0.60,
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 10,
                                            ),
                                            itemCount: visibleProducts.length,
                                            itemBuilder: (context, itemIndex) {
                                              return _buildProductCircle(
                                                visibleProducts[itemIndex],
                                                itemIndex,
                                              );
                                            },
                                          ),
                                        ),

                                        // If more products exist, also show an explicit "See more" link button
                                        if (hasMore)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 14,
                                              right: 14,
                                              top: 4,
                                              bottom: 8,
                                            ),
                                            child: InkWell(
                                              onTap: () => _openCategoryProducts(
                                                  section.category),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFEEF2FF),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'See more ${section.title} (${section.totalCount > 6 ? section.totalCount : section.products.length})',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.indigo,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 14,
                                                      color: Colors.indigo,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SubCategoryData {
  final String title;
  final Category category;
  final List<Product> products;
  final int totalCount;

  const _SubCategoryData({
    required this.title,
    required this.category,
    required this.products,
    required this.totalCount,
  });
}
