// lib/src/presentation/pages/industry_training/providers/industry_training_data_provider.dart
import 'package:flutter/foundation.dart';
import '../../../../data/models/course.dart';
import '../../../../core/api/api_client.dart';

class IndustryTrainingState {
  final List<Course> courses;
  final List<Course> upcoming;
  final List<Course> enrollmentOpen;
  final String selectedIndustry;
  final String selectedLevel;
  final String selectedRole;
  final String? selectedCountry;
  final String? selectedCity;
  final List<String> countries;
  final List<String> cities;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  IndustryTrainingState({
    required this.courses,
    required this.upcoming,
    required this.enrollmentOpen,
    required this.selectedIndustry,
    required this.selectedLevel,
    required this.selectedRole,
    this.selectedCountry,
    this.selectedCity,
    required this.countries,
    required this.cities,
    required this.searchQuery,
    required this.isLoading,
    this.error,
  });

  IndustryTrainingState copyWith({
    List<Course>? courses,
    List<Course>? upcoming,
    List<Course>? enrollmentOpen,
    String? selectedIndustry,
    String? selectedLevel,
    String? selectedRole,
    String? selectedCountry,
    String? selectedCity,
    List<String>? countries,
    List<String>? cities,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return IndustryTrainingState(
      courses: courses ?? this.courses,
      upcoming: upcoming ?? this.upcoming,
      enrollmentOpen: enrollmentOpen ?? this.enrollmentOpen,
      selectedIndustry: selectedIndustry ?? this.selectedIndustry,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      selectedRole: selectedRole ?? this.selectedRole,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedCity: selectedCity ?? this.selectedCity,
      countries: countries ?? this.countries,
      cities: cities ?? this.cities,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class IndustryTrainingDataProvider {
  final ValueNotifier<IndustryTrainingState> stateNotifier;
  List<Course> _allCourses = [];

  IndustryTrainingDataProvider({
    String? initialIndustry,
    String? initialLevel,
    String? initialRole,
  }) : stateNotifier = ValueNotifier(IndustryTrainingState(
          courses: [],
          upcoming: [],
          enrollmentOpen: [],
          selectedIndustry: initialIndustry ?? 'all',
          selectedLevel: initialLevel ?? 'all',
          selectedRole: initialRole ?? 'all',
          countries: [],
          cities: [],
          searchQuery: '',
          isLoading: true,
        ));

  IndustryTrainingState get state => stateNotifier.value;

  void dispose() {
    stateNotifier.dispose();
  }

  Future<void> loadCourses() async {
    _updateState(isLoading: true, error: null);

    try {
      final courses = await ApiClient.getIndustryTraining(
        industry: state.selectedIndustry != 'all' ? state.selectedIndustry : null,
        roleType: state.selectedRole != 'all' ? state.selectedRole : null,
        certificationLevel: state.selectedLevel != 'all' ? state.selectedLevel : null,
      );
      _allCourses = courses;

      // Extract unique countries and cities
      final countries = <String>{};
      final cities = <String>{};

      for (final course in courses) {
        if (course.country != null) countries.add(course.country!);
        if (course.city != null) cities.add(course.city!);
      }

      _updateState(
        courses: courses,
        countries: countries.toList()..sort(),
        cities: cities.toList()..sort(),
        isLoading: false,
      );

      _applyFilters();
    } catch (e) {
      _updateState(
        isLoading: false,
        error: 'Failed to load industry training courses: $e',
      );
    }
  }

  void setIndustry(String industry) {
    _updateState(selectedIndustry: industry);
    loadCourses();
  }

  void setLevel(String level) {
    _updateState(selectedLevel: level);
    _applyFilters();
  }

  void setRole(String role) {
    _updateState(selectedRole: role);
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
    var filtered = List<Course>.from(_allCourses);

    // Filter by level
    if (state.selectedLevel != 'all') {
      filtered = filtered.where((c) {
        return c.certificationLevel?.toLowerCase().contains(state.selectedLevel.toLowerCase()) ?? false;
      }).toList();
    }

    // Filter by role
    if (state.selectedRole != 'all') {
      filtered = filtered.where((c) {
        return c.roleType?.toLowerCase().contains(state.selectedRole.toLowerCase()) ?? false;
      }).toList();
    }

    // Filter by country
    if (state.selectedCountry != null) {
      filtered = filtered.where((c) => c.country == state.selectedCountry).toList();
    }

    // Filter by city
    if (state.selectedCity != null) {
      filtered = filtered.where((c) => c.city == state.selectedCity).toList();
    }

    // Filter by search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.title.toLowerCase().contains(query) ||
               (c.description?.toLowerCase().contains(query) ?? false) ||
               (c.industry?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Separate upcoming and enrollment open
    final upcoming = filtered.where((c) => c.isUpcoming).toList();
    final enrollmentOpen = filtered.where((c) => c.isEnrollmentOpen).toList();

    _updateState(
      courses: filtered,
      upcoming: upcoming,
      enrollmentOpen: enrollmentOpen,
    );
  }

  void refresh() {
    loadCourses();
  }

  void _updateState({
    List<Course>? courses,
    List<Course>? upcoming,
    List<Course>? enrollmentOpen,
    String? selectedIndustry,
    String? selectedLevel,
    String? selectedRole,
    String? selectedCountry,
    String? selectedCity,
    List<String>? countries,
    List<String>? cities,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    stateNotifier.value = state.copyWith(
      courses: courses,
      upcoming: upcoming,
      enrollmentOpen: enrollmentOpen,
      selectedIndustry: selectedIndustry,
      selectedLevel: selectedLevel,
      selectedRole: selectedRole,
      selectedCountry: selectedCountry,
      selectedCity: selectedCity,
      countries: countries,
      cities: cities,
      searchQuery: searchQuery,
      isLoading: isLoading,
      error: error,
    );
  }
}
