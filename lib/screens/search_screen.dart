import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../providers/search_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_grid.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _textController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final currentQuery = context.read<SearchProvider>().query;
    _textController = TextEditingController(text: currentQuery);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 300) {
        context.read<SearchProvider>().loadMore();
      }
    }
  }

  void _performSearch() {
    final text = _textController.text.trim();
    if (text.length >= 2) {
      _focusNode.unfocus();
      context.read<SearchProvider>().search(text);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: canPop ? 0 : 16,
        leading: canPop
            ? null
            : const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.search_rounded,
                  color: Colors.indigo,
                  size: 24,
                ),
              ),
        title: TextField(
          controller: _textController,
          focusNode: _focusNode,
          autofocus: canPop,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _performSearch(),
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            suffixIcon: _textController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      _textController.clear();
                      context.read<SearchProvider>().clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
          onChanged: (value) {
            context.read<SearchProvider>().onQueryChanged(value);
            setState(() {});
          },
        ),
        actions: [
          if (_textController.text.trim().length >= 2)
            IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.indigo),
              tooltip: 'Search',
              onPressed: _performSearch,
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (searchProvider.isInitial) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 40,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Search for products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Type at least 2 characters to search catalog',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (searchProvider.status == ProviderStatus.loading &&
              searchProvider.results.isEmpty) {
            return const ShimmerGrid();
          }

          if (searchProvider.status == ProviderStatus.error &&
              searchProvider.results.isEmpty) {
            return ErrorView(
              message: searchProvider.errorMessage,
              onRetry: () => searchProvider.retry(),
            );
          }

          if (searchProvider.results.isEmpty) {
            return EmptyView(
              title: "No results for '${searchProvider.query}'",
              message:
                  'We could not find anything matching your search. Try different keywords.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => searchProvider.retry(),
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
                            final product = searchProvider.results[index];
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
                          childCount: searchProvider.results.length,
                        ),
                      ),
                    ),
                    if (searchProvider.isLoadingMore)
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
