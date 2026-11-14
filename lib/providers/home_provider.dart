import 'package:flutter/foundation.dart' hide Category;
import '../core/config.dart';
import '../core/graphql_client.dart';
import '../core/queries.dart';
import '../models/category.dart';
import '../models/product.dart';

class HomeProvider extends ChangeNotifier {
  ProviderStatus _status = ProviderStatus.loading;
  String _errorMessage = '';
  List<Product> _products = [];
  bool _isFallbackMode = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  ProviderStatus get status => _status;
  String get errorMessage => _errorMessage;
  List<Product> get products => _products;
  bool get isFallbackMode => _isFallbackMode;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => !_isFallbackMode && _currentPage < _totalPages;

  Future<void> load() async {
    _status = ProviderStatus.loading;
    _errorMessage = '';
    notifyListeners();
    await _fetchData();
  }

  Future<void> refresh() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      _currentPage = 1;
      _totalPages = 1;

      // 1. Fetch products with $id = "2", page 1
      final data = await query(
        productsByCategoryQuery,
        variables: {
          'id': '2',
          'page': 1,
          'size': 20,
        },
      );

      final productsData = data['products'] as Map<String, dynamic>? ?? {};
      final response = ProductsResponse.fromJson(productsData);

      if (response.items.isNotEmpty) {
        // 2. Result has 1 or more items -> show them with pagination
        _products = response.items;
        _currentPage = response.pageInfo.currentPage;
        _totalPages = response.pageInfo.totalPages;
        _isFallbackMode = false;
      } else {
        // 3. EMPTY -> fetch Query 1 for subcategories, fetch page 1 for each, merge deduplicated
        _isFallbackMode = true;
        final catData = await query(categoriesQuery);
        final catList = catData['categoryList'] as List? ?? [];
        final children = (catList.isNotEmpty && catList[0]['children'] is List)
            ? (catList[0]['children'] as List)
            : [];

        final categories = children
            .whereType<Map<String, dynamic>>()
            .map(Category.fromJson)
            .toList();

        final Map<String, Product> uniqueProducts = {};

        // Fetch products for each sub-category
        final results = await Future.wait(
          categories.map((c) async {
            try {
              final subData = await query(
                productsByCategoryQuery,
                variables: {
                  'id': c.id,
                  'page': 1,
                  'size': 20,
                },
              );
              final subProductsData =
                  subData['products'] as Map<String, dynamic>? ?? {};
              return ProductsResponse.fromJson(subProductsData).items;
            } catch (_) {
              return <Product>[];
            }
          }),
        );

        for (final productList in results) {
          for (final prod in productList) {
            if (!uniqueProducts.containsKey(prod.sku)) {
              uniqueProducts[prod.sku] = prod;
            }
          }
        }

        _products = uniqueProducts.values.toList();
        _currentPage = 1;
        _totalPages = 1;
      }

      _status = ProviderStatus.data;
      _errorMessage = '';
      notifyListeners();
    } catch (e) {
      _status = ProviderStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isFallbackMode ||
        _isLoadingMore ||
        _currentPage >= _totalPages ||
        _status != ProviderStatus.data) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final data = await query(
        productsByCategoryQuery,
        variables: {
          'id': '2',
          'page': nextPage,
          'size': 20,
        },
      );

      final productsData = data['products'] as Map<String, dynamic>? ?? {};
      final response = ProductsResponse.fromJson(productsData);

      _currentPage = response.pageInfo.currentPage;
      _totalPages = response.pageInfo.totalPages;

      final existingSkus = _products.map((p) => p.sku).toSet();
      for (final item in response.items) {
        if (!existingSkus.contains(item.sku)) {
          _products.add(item);
          existingSkus.add(item.sku);
        }
      }
    } catch (_) {
      // In case of pagination error, preserve existing loaded products
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
