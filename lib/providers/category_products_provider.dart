import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../core/graphql_client.dart';
import '../core/queries.dart';
import '../models/product.dart';

class CategoryProductsProvider extends ChangeNotifier {
  final String categoryId;

  ProviderStatus _status = ProviderStatus.loading;
  String _errorMessage = '';
  List<Product> _products = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  CategoryProductsProvider({required this.categoryId});

  ProviderStatus get status => _status;
  String get errorMessage => _errorMessage;
  List<Product> get products => _products;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _currentPage < _totalPages;

  Future<void> load() async {
    _status = ProviderStatus.loading;
    _errorMessage = '';
    notifyListeners();
    await _fetchProducts();
  }

  Future<void> refresh() async {
    await _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      _currentPage = 1;
      _totalPages = 1;

      final data = await query(
        productsByCategoryQuery,
        variables: {
          'id': categoryId,
          'page': 1,
          'size': 20,
        },
      );

      final productsData = data['products'] as Map<String, dynamic>? ?? {};
      final response = ProductsResponse.fromJson(productsData);

      _products = response.items;
      _currentPage = response.pageInfo.currentPage;
      _totalPages = response.pageInfo.totalPages;

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
    if (_isLoadingMore ||
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
          'id': categoryId,
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
      // In case of error, preserve existing items
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
