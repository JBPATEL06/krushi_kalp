import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/resource.dart';
import '../../data/services/resource_service.dart';
import '../../utils/crashlytics_service.dart';
import '../../data/services/local_caching_service.dart';
import '../../data/local/entities/resource_entity.dart';
import 'resource_state.dart';

part 'resource_notifier.g.dart';

@Riverpod(keepAlive: true)
class ResourceNotifier extends _$ResourceNotifier {
  static const String _purchasedResourcesKey = 'cached_user_purchased_resources';

  @override
  ResourceState build() {
    // Load from cache after build completion safely
    Future(() => _loadFromPrefs());
    return const ResourceState();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_purchasedResourcesKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        final purchasedResources = jsonList.map((j) => Resource.fromJson(j)).toList();
        state = state.copyWith(
          purchasedResources: purchasedResources,
          purchasedResourceIds: purchasedResources.map((r) => r.id).toSet(),
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'ResourceNotifier: _loadFromPrefs');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = json.encode(state.purchasedResources.map((r) => r.toJson()).toList());
      await prefs.setString(_purchasedResourcesKey, encodedData);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'ResourceNotifier: _saveToPrefs');
    }
  }

  Future<void> fetchResources(ResourceType type, {bool forceRefresh = false, bool isBatch = false}) async {
    // Defer to next event loop tick to avoid "setState during build"
    await Future(() {});

    if (!forceRefresh) {
      bool hasData = false;
      switch (type) {
        case ResourceType.eBook: hasData = state.ebooks.isNotEmpty; break;
        case ResourceType.studyMaterial: hasData = state.studyMaterials.isNotEmpty; break;
        case ResourceType.pyq: hasData = state.pyqs.isNotEmpty; break;
        case ResourceType.currentAffair: hasData = state.currentAffairs.isNotEmpty; break;
      }
      if (hasData) return;
    }

    if (!isBatch) state = state.copyWith(isLoading: true);
    CrashlyticsService.instance.log('ResourceNotifier: Fetching resources (type: $type, force: $forceRefresh)');

    try {
      // 1. Instantly load from Isar NoSQL (Local Cache)
      final cachedEntities = await LocalCachingService.getCachedResources();
      if (cachedEntities.isNotEmpty) {
        final localData = cachedEntities.map((e) => e.toResource()).where((r) => r.type == type).toList();
        if (localData.isNotEmpty) {
           _updateTypeState(type, localData);
        }
      }

      // 2. Fetch fresh data from Supabase
      final resources = await ResourceService.instance.fetchResources(type: type).timeout(const Duration(seconds: 15));

      // 3. Save to Isar
      if (resources.isNotEmpty) {
        LocalCachingService.saveResources(resources.map((r) => ResourceEntity.fromResource(r)).toList());
      }

      _updateTypeState(type, resources);
      state = state.copyWith(errorMessage: null);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'ResourceNotifier: fetchResources($type)');
      
      // Only set error message if we have no data for this type
      final currentList = _getTypeResources(type);
      if (currentList.isEmpty) {
        state = state.copyWith(errorMessage: 'Failed to load ${type.toString().split('.').last}. Please check connection.');
      }
    } finally {
      if (!isBatch) state = state.copyWith(isLoading: false);
    }
  }

  List<Resource> _getTypeResources(ResourceType type) {
    switch (type) {
      case ResourceType.eBook: return state.ebooks;
      case ResourceType.studyMaterial: return state.studyMaterials;
      case ResourceType.pyq: return state.pyqs;
      case ResourceType.currentAffair: return state.currentAffairs;
    }
  }

  void _updateTypeState(ResourceType type, List<Resource> resources) {
    switch (type) {
      case ResourceType.eBook: state = state.copyWith(ebooks: resources); break;
      case ResourceType.studyMaterial: state = state.copyWith(studyMaterials: resources); break;
      case ResourceType.pyq: state = state.copyWith(pyqs: resources); break;
      case ResourceType.currentAffair: state = state.copyWith(currentAffairs: resources); break;
    }
  }

  Future<void> fetchPurchasedResources(String userId) async {
    // Defer to next event loop tick to avoid "setState during build"
    await Future(() {});
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resources = await ResourceService.instance.fetchPurchasedResources(userId).timeout(const Duration(seconds: 15));
      state = state.copyWith(
        purchasedResources: resources,
        purchasedResourceIds: resources.map((r) => r.id).toSet(),
      );
      _saveToPrefs();
    } catch (e, stack) {
      state = state.copyWith(errorMessage: 'Failed to load purchased resources: $e');
      CrashlyticsService.instance.recordError(e, stack, reason: 'ResourceNotifier: fetchPurchasedResources');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchAll({bool forceRefresh = false}) async {
    // Defer to next event loop tick to avoid "setState during build"
    await Future(() {});

    if (state.isLoading) return; // Prevent concurrent batch fetches
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Run all fetches in parallel, each will update its own slice of state
      // We pass a flag or handle loading internally to prevent flickering
      await Future.wait([
        fetchResources(ResourceType.eBook, forceRefresh: forceRefresh, isBatch: true),
        fetchResources(ResourceType.studyMaterial, forceRefresh: forceRefresh, isBatch: true),
        fetchResources(ResourceType.pyq, forceRefresh: forceRefresh, isBatch: true),
        fetchResources(ResourceType.currentAffair, forceRefresh: forceRefresh, isBatch: true),
      ]);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'ResourceNotifier: fetchAll');
      state = state.copyWith(errorMessage: 'Error refreshing library: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> claimResource(int resourceId, String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      await ResourceService.instance.claimResource(resourceId: resourceId, userId: userId);
      await fetchPurchasedResources(userId);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'ResourceNotifier: claimResource($resourceId)');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

}
