import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/resource.dart';

part 'resource_state.freezed.dart';

@freezed
abstract class ResourceState with _$ResourceState {
  const factory ResourceState({
    @Default([]) List<Resource> ebooks,
    @Default([]) List<Resource> studyMaterials,
    @Default([]) List<Resource> pyqs,
    @Default([]) List<Resource> currentAffairs,
    @Default({}) Set<int> purchasedResourceIds,
    @Default([]) List<Resource> purchasedResources,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _ResourceState;
}
