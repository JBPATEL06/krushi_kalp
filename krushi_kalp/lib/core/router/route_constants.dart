class RouteConstants {
  // Auth & Core
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/';
  static const String about = '/about';
  static const String profile = '/profile';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminOrders = '/admin/orders';
  static const String adminResources = '/admin/resources';
  static const String adminMockTests = '/admin/mock-tests';

  // Feature: Mock Tests
  static const String allTests = '/tests';
  static const String testDetail = '/tests/:id';
  static const String testAttempt = '/tests/:id/attempt';
  static const String testResult = '/tests/:id/result';

  // Utils
  static const String pdfViewer = '/pdf-viewer';
  static const String maintenance = '/maintenance';
  static const String updateRequired = '/update-required';
}
