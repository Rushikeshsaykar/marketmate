import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../models/category.dart';
import '../providers/category_products_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_grid.dart';
import 'product_detail_screen.dart';

class CategoryProductsScreen extends StatelessWidget {
  final Category category;

  const CategoryProductsScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryProductsProvider(categoryId: category.id)..load(),
      child: _CategoryProductsView(category: category),
    );
  }
}

class _CategoryProductsView extends StatefulWidget {
  final Category category;

  const _CategoryProductsView({required this.category});

  @override
  State<_CategoryProductsView> createState() => _CategoryProductsViewState();
}

class _CategoryProductsViewState extends State<_CategoryProductsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 300) {
        context.read<CategoryProductsProvider>().loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProductsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: Builder(
        builder: (context) {
          if (provider.status == ProviderStatus.loading) {
            return const ShimmerGrid();
          }

          if (provider.status == ProviderStatus.error) {
            return ErrorView(
              message: provider.errorMessage,
              onRetry: () => provider.load(),
            );
          }

          if (provider.products.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: EmptyView(
                title: 'No products found',
                message: 'No products are currently available in this category.',
                onRefresh: () => provider.refresh(),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

                return CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = provider.products[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                      sku: product.sku,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: provider.products.length,
                        ),
                      ),
                    ),
                    if (provider.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
