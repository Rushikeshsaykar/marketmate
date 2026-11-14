import 'package:flutter/foundation.dart' hide Category;
import '../core/config.dart';
import '../core/graphql_client.dart';
import '../core/queries.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  ProviderStatus _status = ProviderStatus.loading;
  String _errorMessage = '';
  List<Category> _categories = [];

  ProviderStatus get status => _status;
  String get errorMessage => _errorMessage;
  List<Category> get categories => _categories;

  Future<void> load() async {
    _status = ProviderStatus.loading;
    _errorMessage = '';
    notifyListeners();
    await _fetchCategories();
  }

  Future<void> refresh() async {
    await _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await query(categoriesQuery);
      final catList = data['categoryList'] as List? ?? [];

      if (catList.isNotEmpty && catList[0] is Map<String, dynamic>) {
        final children = catList[0]['children'] as List? ?? [];
        _categories = children
            .whereType<Map<String, dynamic>>()
            .map(Category.fromJson)
            .toList();
      } else {
        _categories = [];
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
