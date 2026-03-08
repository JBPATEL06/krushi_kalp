import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0;
  String _selectedStoreCategory = 'All';

  int get selectedIndex => _selectedIndex;
  String get selectedStoreCategory => _selectedStoreCategory;

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setStoreCategory(String category) {
    _selectedStoreCategory = category;
    notifyListeners();
  }

  void reset() {
    _selectedIndex = 0;
    _selectedStoreCategory = 'All';
    notifyListeners();
  }
}
