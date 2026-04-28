// lib/src/presentation/pages/learnerships/providers/learnership_data_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../data/models/learnership.dart';
import '../../../../core/api/api_client.dart';

class LearnershipState {
  final List<Learnership> learnerships;
  final List<Learnership> upcoming;
  final List<Learnership> enrollmentOpen;
  final String selectedSpecialization;
  final String? selectedCountry;
  final String? selectedCity;
  final List<String> countries;
  final List<String> cities;
  final String searchQuery;
  final bool isLoading;
  final String? error;
  // Derived from API data — no hardcoding
  final String? categoryName;
  final List<String> specializations;

  LearnershipState({
    required this.learnerships,
    required this.upcoming,
    required this.enrollmentOpen,
    required this.selectedSpecialization,
    this.selectedCountry,
    this.selectedCity,
    required this.countries,
    required this.cities,
    required this.searchQuery,
    required this.isLoading,
    this.error,
    this.categoryName,
    this.specializations = const [],
  });

  LearnershipState copyWith({
    List<Learnership>? learnerships,
    List<Learnership>? upcoming,
    List<Learnership>? enrollmentOpen,
    String? selectedSpecialization,
    String? selectedCountry,
    String? selectedCity,
    List<String>? countries,
    List<String>? cities,
    String? searchQuery,
    bool? isLoading,
    String? error,
    String? categoryName,
    List<String>? specializations,
  }) {
    return LearnershipState(
      learnerships: learnerships ?? this.learnerships,
      upcoming: upcoming ?? this.upcoming,
      enrollmentOpen: enrollmentOpen ?? this.enrollmentOpen,
      selectedSpecialization:
          selectedSpecialization ?? this.selectedSpecialization,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedCity: selectedCity ?? this.selectedCity,
      countries: countries ?? this.countries,
      cities: cities ?? this.cities,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      categoryName: categoryName ?? this.categoryName,
      specializations: specializations ?? this.specializations,
    );
  }
}

class LearnershipDataProvider {
  final ValueNotifier<LearnershipState> stateNotifier;
  List<Learnership> _allLearnerships = [];
  final String? _categoryFilter;

  LearnershipDataProvider({String? initialSpecialization, String? categoryFilter})
      : _categoryFilter = categoryFilter,
        stateNotifier = ValueNotifier(LearnershipState(
          learnerships: [],
          upcoming: [],
          enrollmentOpen: [],
          selectedSpecialization: initialSpecialization ?? 'all',
          countries: [],
          cities: [],
          searchQuery: '',
          isLoading: true,
          specializations: [],
        ));

  LearnershipState get state => stateNotifier.value;

  void dispose() {
    stateNotifier.dispose();
  }

  Future<void> loadLearnerships() async {
    _updateState(isLoading: true, error: null);

    try {
      List<Learnership> learnerships;
      
      if (_categoryFilter == 'Cybersecurity') {
        learnerships = await ApiClient.getCybersecurityLearnerships()
            .timeout(const Duration(seconds: 15));
      } else if (_categoryFilter == 'AI & Blockchain') {
        learnerships = await ApiClient.getAIBlockchainLearnerships()
            .timeout(const Duration(seconds: 15));
      } else {
        learnerships = await ApiClient.getLearnerships(
          category: _categoryFilter,
        ).timeout(const Duration(seconds: 15));
      }

      _allLearnerships = learnerships;

      // Derive category name and specializations directly from API data
      final categoryName = _categoryFilter ??
          learnerships
              .map((l) => l.category)
              .where((c) => c != null && c!.isNotEmpty)
              .map((c) => c!)
              .toSet()
              .join(' / ');

      final specializations = learnerships
          .map((l) => l.specialization)
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      final countries = learnerships
          .map((l) => l.country)
          .where((c) => c != null)
          .map((c) => c!)
          .toSet()
          .toList()
        ..sort();

      final cities = learnerships
          .map((l) => l.city)
          .where((c) => c != null)
          .map((c) => c!)
          .toSet()
          .toList()
        ..sort();

      _updateState(
        learnerships: learnerships,
        countries: countries,
        cities: cities,
        categoryName: categoryName.isNotEmpty ? categoryName : null,
        specializations: specializations,
        isLoading: false,
      );

      _applyFilters();
    } on TimeoutException catch (_) {
      _updateState(
        isLoading: false,
        error: 'Learnerships could not be loaded — server is taking too long. Please try again.',
      );
    } catch (e) {
      _updateState(
        isLoading: false,
        error: 'Unable to load learnerships. Please check your connection and try again.',
      );
    }
  }

  void setSpecialization(String specialization) {
    _updateState(selectedSpecialization: specialization);
    _applyFilters();
  }

  void setCountry(String? country) {
    _updateState(selectedCountry: country, selectedCity: null);
    _applyFilters();
  }

  void setCity(String? city) {
    _updateState(selectedCity: city);
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _updateState(searchQuery: query);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Learnership>.from(_allLearnerships);

    // CRITICAL: Filter out learnerships that are not offered
    filtered = filtered.where((l) => l.isOffered).toList();

    if (state.selectedSpecialization != 'all') {
      final selected = state.selectedSpecialization.toLowerCase();
      filtered = filtered.where((l) {
        final spec = l.specialization.toLowerCase();
        final cat = l.category?.toLowerCase() ?? '';
        final role = l.role?.toLowerCase() ?? '';
        return spec == selected ||
            spec.contains(selected) ||
            cat.contains(selected) ||
            role.contains(selected);
      }).toList();
    }

    if (state.selectedCountry != null) {
      filtered = filtered.where((l) => l.country == state.selectedCountry).toList();
    }

    if (state.selectedCity != null) {
      filtered = filtered.where((l) => l.city == state.selectedCity).toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((l) {
        return l.title.toLowerCase().contains(query) ||
            l.specialization.toLowerCase().contains(query) ||
            (l.role?.toLowerCase().contains(query) ?? false) ||
            (l.description?.toLowerCase().contains(query) ?? false) ||
            (l.focus?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    final upcoming = filtered.where((l) => l.isUpcoming).toList();
    final enrollmentOpen = filtered.where((l) => l.isEnrollmentOpen).toList();

    _updateState(
      learnerships: filtered,
      upcoming: upcoming,
      enrollmentOpen: enrollmentOpen,
    );
  }

  void refresh() {
    loadLearnerships();
  }

  void _updateState({
    List<Learnership>? learnerships,
    List<Learnership>? upcoming,
    List<Learnership>? enrollmentOpen,
    String? selectedSpecialization,
    String? selectedCountry,
    String? selectedCity,
    List<String>? countries,
    List<String>? cities,
    String? searchQuery,
    bool? isLoading,
    String? error,
    String? categoryName,
    List<String>? specializations,
  }) {
    stateNotifier.value = state.copyWith(
      learnerships: learnerships,
      upcoming: upcoming,
      enrollmentOpen: enrollmentOpen,
      selectedSpecialization: selectedSpecialization,
      selectedCountry: selectedCountry,
      selectedCity: selectedCity,
      countries: countries,
      cities: cities,
      searchQuery: searchQuery,
      isLoading: isLoading,
      error: error,
      categoryName: categoryName,
      specializations: specializations,
    );
  }
}
