import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../core/graphql_client.dart' as gql;
import '../core/queries.dart';
import '../models/product.dart';

class SearchProvider extends ChangeNotifier {
  String _query = '';
  List<Product> _results = [];
  ProviderStatus _status = ProviderStatus.data;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  int _requestId = 0;
  Timer? _debounceTimer;

  String get query => _query;
  List<Product> get results => _results;
  ProviderStatus get status => _status;
  String get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => !_isLoadingMore && _currentPage < _totalPages;
  bool get isInitial => _query.trim().length < 2;

  void onQueryChanged(String newQuery) {
    _debounceTimer?.cancel();
    _query = newQuery;

    final trimmed = newQuery.trim();
    if (trimmed.length < 2) {
      _results = [];
      _status = ProviderStatus.data;
      _errorMessage = '';
      _currentPage = 1;
      _totalPages = 1;
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      search(trimmed);
    });
  }

  Future<void> search(String queryText) async {
    _query = queryText;
    _debounceTimer?.cancel();

    if (queryText.trim().length < 2) {
      _results = [];
      _status = ProviderStatus.data;
      _errorMessage = '';
      notifyListeners();
      return;
    }

    final currentId = ++_requestId;
    _status = ProviderStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = await gql.query(
        productsQuery,
        variables: {
          'search': queryText.trim(),
          'page': 1,
          'size': 20,
        },
      );

      // Ignore outdated response
      if (currentId != _requestId) return;

      final productsData = data['products'] as Map<String, dynamic>? ?? {};
      final response = ProductsResponse.fromJson(productsData);

      _results = response.items;
      _currentPage = response.pageInfo.currentPage;
      _totalPages = response.pageInfo.totalPages;
      _status = ProviderStatus.data;
      _errorMessage = '';
      notifyListeners();
    } catch (e) {
      if (currentId != _requestId) return;
      _status = ProviderStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> retry() async {
    await search(_query);
  }

  Future<void> loadMore() async {
    if (_isLoadingMore ||
        _currentPage >= _totalPages ||
        _query.trim().length < 2 ||
        _status != ProviderStatus.data) {
      return;
    }

    final currentId = _requestId;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final data = await gql.query(
        productsQuery,
        variables: {
          'search': _query.trim(),
          'page': nextPage,
          'size': 20,
        },
      );

      if (currentId != _requestId) return;

      final productsData = data['products'] as Map<String, dynamic>? ?? {};
      final response = ProductsResponse.fromJson(productsData);

      _currentPage = response.pageInfo.currentPage;
      _totalPages = response.pageInfo.totalPages;

      final existingSkus = _results.map((p) => p.sku).toSet();
      for (final item in response.items) {
        if (!existingSkus.contains(item.sku)) {
          _results.add(item);
          existingSkus.add(item.sku);
        }
      }
    } catch (_) {
      // Preserve existing results on pagination failure
    } finally {
      if (currentId == _requestId) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    _query = '';
    _results = [];
    _status = ProviderStatus.data;
    _errorMessage = '';
    _currentPage = 1;
    _totalPages = 1;
    _isLoadingMore = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
