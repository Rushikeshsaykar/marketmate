import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../core/graphql_client.dart';
import '../core/queries.dart';
import '../models/product_detail.dart';

class ProductDetailProvider extends ChangeNotifier {
  final String sku;

  ProviderStatus _status = ProviderStatus.loading;
  String _errorMessage = '';
  ProductDetail? _product;

  ProductDetailProvider({required this.sku});

  ProviderStatus get status => _status;
  String get errorMessage => _errorMessage;
  ProductDetail? get product => _product;

  Future<void> load() async {
    _status = ProviderStatus.loading;
    _errorMessage = '';
    notifyListeners();
    await _fetchDetail();
  }

  Future<void> refresh() async {
    await _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await query(
        productDetailQuery,
        variables: {'sku': sku},
      );

      final productsData = data['products'] as Map<String, dynamic>?;
      final items = productsData?['items'] as List? ?? [];

      if (items.isNotEmpty && items[0] is Map<String, dynamic>) {
        _product = ProductDetail.fromJson(items[0] as Map<String, dynamic>);
      } else {
        _product = null;
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
}
