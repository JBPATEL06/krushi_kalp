import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/resource_service.dart';
import '../../domain/models/resource.dart';

class ResourceProvider extends ChangeNotifier {
  final ResourceService _resourceService = ResourceService.instance;
  static const String _purchasedResourcesKey =
      'cached_user_purchased_resources';

  // State for different resource types
  List<Resource> _ebooks = [];
  List<Resource> _studyMaterials = [];
  List<Resource> _pyqs = [];
  List<Resource> _currentAffairs = [];
  Set<int> _purchasedResourceIds = {};
  List<Resource> _purchasedResources = [];

  bool _isLoading = false;
  String? _errorMessage;

  ResourceProvider() {
    _loadFromPrefs();
  }

  // Getters
  List<Resource> get ebooks => _ebooks;
  List<Resource> get studyMaterials => _studyMaterials;
  List<Resource> get pyqs => _pyqs;
  List<Resource> get currentAffairs => _currentAffairs;
  Set<int> get purchasedResourceIds => _purchasedResourceIds;
  List<Resource> get purchasedResources => _purchasedResources;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_purchasedResourcesKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        _purchasedResources =
            jsonList.map((j) => Resource.fromJson(j)).toList();
        _purchasedResourceIds = _purchasedResources.map((r) => r.id).toSet();
        debugPrint(
          'ResourceProvider: Loaded ${_purchasedResources.length} resources from cache',
        );
        Future.microtask(() => notifyListeners());
      }
    } catch (e) {
      debugPrint('ResourceProvider: Error loading from cache: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = json.encode(
        _purchasedResources.map((r) => r.toJson()).toList(),
      );
      await prefs.setString(_purchasedResourcesKey, encodedData);
      debugPrint(
        'ResourceProvider: Saved ${_purchasedResources.length} resources to cache',
      );
    } catch (e) {
      debugPrint('ResourceProvider: Error saving to cache: $e');
    }
  }

  Future<void> fetchResources(
    ResourceType type, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      bool hasData = false;
      switch (type) {
        case ResourceType.eBook:
          hasData = _ebooks.isNotEmpty;
          break;
        case ResourceType.studyMaterial:
          hasData = _studyMaterials.isNotEmpty;
          break;
        case ResourceType.pyq:
          hasData = _pyqs.isNotEmpty;
          break;
        case ResourceType.currentAffair:
          hasData = _currentAffairs.isNotEmpty;
          break;
      }
      if (hasData) return;
    }

    _setLoading(true);
    try {
      final resources = await _resourceService.fetchResources(type: type);
      debugPrint(
          'ResourceProvider: Fetched ${resources.length} items for type $type');

      switch (type) {
        case ResourceType.eBook:
          _ebooks = resources;
          break;
        case ResourceType.studyMaterial:
          _studyMaterials = resources;
          break;
        case ResourceType.pyq:
          _pyqs = resources;
          break;
        case ResourceType.currentAffair:
          _currentAffairs = resources;
          break;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load ${type.toString().split('.').last}: $e';
      debugPrint('ResourceProvider: Error fetching $type: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPurchasedResources(String userId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final resources = await _resourceService.fetchPurchasedResources(userId);
      _purchasedResources = resources;
      _purchasedResourceIds = resources.map((r) => r.id).toSet();
      debugPrint(
          'ResourceProvider: Updated purchasedResourceIds. Total: ${_purchasedResourceIds.length}, IDs: $_purchasedResourceIds');
      _saveToPrefs();
    } catch (e) {
      debugPrint(
          'ResourceProvider: Error fetching purchased resources for $userId: $e');
      _errorMessage = 'Failed to load purchased resources: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAll({bool forceRefresh = false}) async {
    _setLoading(true);
    try {
      await Future.wait([
        fetchResources(ResourceType.eBook, forceRefresh: forceRefresh),
        fetchResources(ResourceType.studyMaterial, forceRefresh: forceRefresh),
        fetchResources(ResourceType.pyq, forceRefresh: forceRefresh),
        fetchResources(ResourceType.currentAffair, forceRefresh: forceRefresh),
      ]);
    } catch (e) {
    } finally {
      _setLoading(false);
    }
  }

  Future<void> claimResource(int resourceId, String userId) async {
    debugPrint(
        'ResourceProvider: claimResource called for $resourceId (user: $userId)');
    if (_isLoading) {
      debugPrint('ResourceProvider: Skipping claim, already loading');
      return;
    }
    _setLoading(true);
    try {
      await _resourceService.claimResource(
        resourceId: resourceId,
        userId: userId,
      );
      await fetchPurchasedResources(userId);
    } catch (e) {
      debugPrint('Error claiming resource: $e');
      rethrow;
    }
  }

  int _loadingCount = 0;

  void _setLoading(bool value) {
    if (value) {
      _loadingCount++;
    } else {
      if (_loadingCount > 0) _loadingCount--;
    }
    _isLoading = _loadingCount > 0;
    Future.microtask(() => notifyListeners());
  }
}
