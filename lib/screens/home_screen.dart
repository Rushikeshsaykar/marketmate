import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../providers/home_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_grid.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onSearchTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        context.read<HomeProvider>().loadMore();
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

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: InkWell(
        onTap: () {
          if (widget.onSearchTap != null) {
            widget.onSearchTap!();
          } else {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SearchScreen()));
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Colors.indigo, size: 22),
              const SizedBox(width: 12),
              Text(
                'Search products...',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF312E81), // Deep indigo
              Color(0xFF4F46E5), // Indigo
              Color(0xFF7C3AED), // Purple
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                right: 50,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Banner Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'SPECIAL OFFER • LIMITED TIME',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Catchy marketing headline
                    const Text(
                      'Unbeatable Deals,\nDelivered To You.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Catchy marketing tagline
                    Text(
                      'Upgrade your lifestyle with up to 50% OFF on top trending essentials today!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // CTA pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Store')),
      body: Builder(
        builder: (context) {
          if (homeProvider.status == ProviderStatus.loading) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(context),
                  _buildPromoBanner(context),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Featured products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const ShimmerGrid(),
                ],
              ),
            );
          }

          if (homeProvider.status == ProviderStatus.error) {
            return ErrorView(
              message: homeProvider.errorMessage,
              onRetry: () => homeProvider.load(),
            );
          }

          if (homeProvider.products.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => homeProvider.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildSearchBar(context),
                    _buildPromoBanner(context),
                    EmptyView(
                      title: 'No products available',
                      message:
                          'No featured products found. Pull down to refresh.',
                      onRefresh: () => homeProvider.refresh(),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => homeProvider.refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

                return CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildSearchBar(context)),
                    SliverToBoxAdapter(child: _buildPromoBanner(context)),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Text(
                          'Featured products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = homeProvider.products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(sku: product.sku),
                                ),
                              );
                            },
                          );
                        }, childCount: homeProvider.products.length),
                      ),
                    ),
                    if (homeProvider.isLoadingMore)
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
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
