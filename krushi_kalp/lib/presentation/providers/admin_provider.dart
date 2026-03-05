import 'package:flutter/foundation.dart';

class AdminProvider extends ChangeNotifier {
  // We can still use the Static Service for heavy lifting if we want,
  // or move the logic here. For now, wrapping the service is cleaner for migration.

  // Deprecated: UI now uses Streams directly from AdminService.
  // Keeping rudimentary state for nav index only.

  int _navIndex = 0;
  int get navIndex => _navIndex;

  void setNavIndex(int index) {
    _navIndex = index;
    notifyListeners();
  }
}
