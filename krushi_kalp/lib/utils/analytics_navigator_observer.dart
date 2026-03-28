import 'package:flutter/material.dart';
import 'crashlytics_service.dart';

/// A NavigatorObserver that logs screen transitions to Firebase Crashlytics as breadcrumbs.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _logScreenView(previousRoute);
    }
  }

  void _logScreenView(Route<dynamic> route) {
    final screenName = route.settings.name ?? 'Unknown Screen';
    // If the route doesn't have a name, we can try to get it from the widget type if it's a PageRoute
    String? name = screenName;

    if (name == 'Unknown Screen' || name == '/') {
      // Optional: You can add more complex logic here to extract names from specific route types
      // For now, we rely on properly named routes or generic breadcrumbs.
    }

    CrashlyticsService.instance.log('ScreenView: $name');
  }
}
