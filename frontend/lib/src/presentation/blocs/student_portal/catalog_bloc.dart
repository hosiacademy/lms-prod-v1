// lib/src/presentation/blocs/student_portal/catalog_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/course_catalog.dart';
import '../../../core/api/student_portal_api_service.dart';

// ===================================
// EVENTS
// ===================================

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class LoadCatalog extends CatalogEvent {
  final String? trainingType;
  final int? providerId;
  final bool? featured;
  final String? search;

  const LoadCatalog({
    this.trainingType,
    this.providerId,
    this.featured,
    this.search,
  });

  @override
  List<Object?> get props => [trainingType, providerId, featured, search];
}

class FilterCatalog extends CatalogEvent {
  final String? trainingType;
  final int? providerId;
  final bool? featured;

  const FilterCatalog({
    this.trainingType,
    this.providerId,
    this.featured,
  });

  @override
  List<Object?> get props => [trainingType, providerId, featured];
}

class SearchCatalog extends CatalogEvent {
  final String query;

  const SearchCatalog(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadCatalogByTrainingType extends CatalogEvent {
  final String trainingType;

  const LoadCatalogByTrainingType(this.trainingType);

  @override
  List<Object?> get props => [trainingType];
}

class LoadProviders extends CatalogEvent {}

class LoadProviderCourses extends CatalogEvent {
  final int providerId;

  const LoadProviderCourses(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

// ===================================
// STATES
// ===================================

abstract class CatalogState extends Equatable {
  const CatalogState();

  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<CourseCatalogItem> items;
  final String? filterTrainingType;
  final int? filterProviderId;
  final bool? filterFeatured;
  final String? searchQuery;

  const CatalogLoaded(
    this.items, {
    this.filterTrainingType,
    this.filterProviderId,
    this.filterFeatured,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [items, filterTrainingType, filterProviderId, filterFeatured, searchQuery];

  List<CourseCatalogItem> get featuredItems => items.where((item) => item.isFeatured).toList();

  Map<String, List<CourseCatalogItem>> get itemsByType {
    final map = <String, List<CourseCatalogItem>>{};
    for (final item in items) {
      if (!map.containsKey(item.trainingType)) {
        map[item.trainingType] = [];
      }
      map[item.trainingType]!.add(item);
    }
    return map;
  }

  Map<int, List<CourseCatalogItem>> get itemsByProvider {
    final map = <int, List<CourseCatalogItem>>{};
    for (final item in items) {
      if (!map.containsKey(item.providerId)) {
        map[item.providerId] = [];
      }
      map[item.providerId]!.add(item);
    }
    return map;
  }

  bool get hasFilters =>
      filterTrainingType != null || filterProviderId != null || filterFeatured != null || searchQuery != null;
}

class CatalogError extends CatalogState {
  final String message;

  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProvidersLoaded extends CatalogState {
  final List<CourseProvider> providers;

  const ProvidersLoaded(this.providers);

  @override
  List<Object?> get props => [providers];
}

class ProviderCoursesLoaded extends CatalogState {
  final int providerId;
  final List<CourseCatalogItem> courses;

  const ProviderCoursesLoaded(this.providerId, this.courses);

  @override
  List<Object?> get props => [providerId, courses];
}

// ===================================
// BLOC
// ===================================

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc() : super(CatalogInitial()) {
    on<LoadCatalog>(_onLoadCatalog);
    on<FilterCatalog>(_onFilterCatalog);
    on<SearchCatalog>(_onSearchCatalog);
    on<LoadCatalogByTrainingType>(_onLoadCatalogByTrainingType);
    on<LoadProviders>(_onLoadProviders);
    on<LoadProviderCourses>(_onLoadProviderCourses);
  }

  Future<void> _onLoadCatalog(
    LoadCatalog event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());
    try {
      final items = await LearnerPortalApiService.getCourseCatalog(
        trainingType: event.trainingType,
        providerId: event.providerId,
        featured: event.featured,
        search: event.search,
      );
      emit(CatalogLoaded(
        items,
        filterTrainingType: event.trainingType,
        filterProviderId: event.providerId,
        filterFeatured: event.featured,
        searchQuery: event.search,
      ));
    } catch (e) {
      emit(CatalogError('Failed to load catalog: ${e.toString()}'));
    }
  }

  Future<void> _onFilterCatalog(
    FilterCatalog event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());
    try {
      final items = await LearnerPortalApiService.getCourseCatalog(
        trainingType: event.trainingType,
        providerId: event.providerId,
        featured: event.featured,
      );
      emit(CatalogLoaded(
        items,
        filterTrainingType: event.trainingType,
        filterProviderId: event.providerId,
        filterFeatured: event.featured,
      ));
    } catch (e) {
      emit(CatalogError('Failed to filter catalog: ${e.toString()}'));
    }
  }

  Future<void> _onSearchCatalog(
    SearchCatalog event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());
    try {
      final items = await LearnerPortalApiService.getCourseCatalog(
        search: event.query,
      );
      emit(CatalogLoaded(
        items,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(CatalogError('Failed to search catalog: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCatalogByTrainingType(
    LoadCatalogByTrainingType event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());
    try {
      final items = await LearnerPortalApiService.getCatalogByTrainingType(event.trainingType);
      emit(CatalogLoaded(
        items,
        filterTrainingType: event.trainingType,
      ));
    } catch (e) {
      emit(CatalogError('Failed to load catalog: ${e.toString()}'));
    }
  }

  Future<void> _onLoadProviders(
    LoadProviders event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());
    try {
      final providers = await LearnerPortalApiService.getCourseProviders();
      emit(ProvidersLoaded(providers));
    } catch (e) {
      emit(CatalogError('Failed to load providers: ${e.toString()}'));
    }
  }

  Future<void> _onLoadProviderCourses(
    LoadProviderCourses event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());
    try {
      final courses = await LearnerPortalApiService.getProviderCourses(event.providerId);
      emit(ProviderCoursesLoaded(event.providerId, courses));
    } catch (e) {
      emit(CatalogError('Failed to load provider courses: ${e.toString()}'));
    }
  }
}
