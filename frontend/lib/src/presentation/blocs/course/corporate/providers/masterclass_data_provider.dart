// lib/src/presentation/blocs/course/corporate/providers/masterclass_data_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../data/models/masterclass.dart';
import '../../../../../data/models/course.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/services/aicerts_service.dart';

class MasterclassState {
  final bool isLoading;
  final String? error;
  final String selectedType;
  final String? selectedCountry;
  final String? selectedCity;
  final String? selectedVenue;
  final List<String> countries;
  final List<String> cities;
  final List<String> venues;
  final List<Masterclass> allMasterclasses;
  final List<Masterclass> filteredMasterclasses;
  final List<Masterclass> running;
  final List<Masterclass> upcoming;
  final Map<DateTime, List<Masterclass>> events;

  // AI Search/Prompting fields
  final String searchQuery;
  final List<Course> aicertsCourses;
  final bool isLoadingCourses;

  MasterclassState({
    this.isLoading = false,
    this.error,
    this.selectedType = 'all',
    this.selectedCountry,
    this.selectedCity,
    this.selectedVenue,
    this.countries = const [],
    this.cities = const [],
    this.venues = const [],
    this.allMasterclasses = const [],
    this.filteredMasterclasses = const [],
    this.running = const [],
    this.upcoming = const [],
    this.events = const {},
    this.searchQuery = '',
    this.aicertsCourses = const [],
    this.isLoadingCourses = false,
  });

  MasterclassState copyWith({
    bool? isLoading,
    String? error,
    String? selectedType,
    String? selectedCountry,
    String? selectedCity,
    String? selectedVenue,
    List<String>? countries,
    List<String>? cities,
    List<String>? venues,
    List<Masterclass>? allMasterclasses,
    List<Masterclass>? filteredMasterclasses,
    List<Masterclass>? running,
    List<Masterclass>? upcoming,
    Map<DateTime, List<Masterclass>>? events,
    String? searchQuery,
    List<Course>? aicertsCourses,
    bool? isLoadingCourses,
  }) {
    return MasterclassState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedType: selectedType ?? this.selectedType,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedVenue: selectedVenue ?? this.selectedVenue,
      countries: countries ?? this.countries,
      cities: cities ?? this.cities,
      venues: venues ?? this.venues,
      allMasterclasses: allMasterclasses ?? this.allMasterclasses,
      filteredMasterclasses:
          filteredMasterclasses ?? this.filteredMasterclasses,
      running: running ?? this.running,
      upcoming: upcoming ?? this.upcoming,
      events: events ?? this.events,
      searchQuery: searchQuery ?? this.searchQuery,
      aicertsCourses: aicertsCourses ?? this.aicertsCourses,
      isLoadingCourses: isLoadingCourses ?? this.isLoadingCourses,
    );
  }
}

class MasterclassDataProvider {
  final ValueNotifier<MasterclassState> _stateNotifier;
  Timer? _refreshTimer;
  bool _isDisposed = false;
  final Map<String, String> _imageAssignments =
      {}; // Track unique image assignments

  ValueNotifier<MasterclassState> get stateNotifier => _stateNotifier;

  MasterclassDataProvider({String? initialType})
      : _stateNotifier = ValueNotifier(
            MasterclassState(selectedType: initialType ?? 'all')) {
    _initializeApiClient();
    _loadAICertsCourses();
  }

  void _initializeApiClient() {
    try {
      ApiClient.initialize();
    } catch (e) {
      print('Failed to initialize API client: $e');
    }
  }

  Future<void> loadMasterclasses() async {
    if (_isDisposed) return;
    _updateState(
        state: _stateNotifier.value.copyWith(isLoading: true, error: null));

    try {
      // Fetch ALL masterclasses (no pagination - page_size=500 in API client)
      final data = await ApiClient.getMasterclasses(streamType: null);

      if (_isDisposed) return;
      print('Loaded ${data.length} masterclasses from API');

      if (data.isNotEmpty) {
        _processMasterclassData(data);
        _scheduleAutoRefresh();
      } else {
        _updateState(
            state: _stateNotifier.value.copyWith(
          isLoading: false,
          error: 'No masterclasses found',
        ));
      }
    } catch (e) {
      if (_isDisposed) return;
      print('Error loading masterclasses: $e');
      _updateState(
          state: _stateNotifier.value.copyWith(
        isLoading: false,
        error: 'Failed to load masterclasses: $e',
      ));
    }
  }

  // Load AICerts courses for certification images
  Future<void> _loadAICertsCourses() async {
    if (_isDisposed) return;
    _updateState(state: _stateNotifier.value.copyWith(isLoadingCourses: true));

    try {
      final courses = await AICertsService.fetchCourses();
      if (_isDisposed) return;
      _updateState(
          state: _stateNotifier.value.copyWith(
        aicertsCourses: courses,
        isLoadingCourses: false,
      ));
      print('Loaded ${courses.length} AICerts courses for image matching');
    } catch (e) {
      if (_isDisposed) return;
      print('Error loading AICerts courses: $e');
      _updateState(
          state: _stateNotifier.value.copyWith(isLoadingCourses: false));
    }
  }

  // Get certification image URL for a masterclass with unique assignment
  String? getCertificationImage(Masterclass masterclass) {
    if (_isDisposed) return null;
    final courses = _stateNotifier.value.aicertsCourses;
    final masterclassKey = masterclass.title ?? '';

    if (courses.isEmpty) return null;

    // Check if this masterclass already has an assigned image
    if (_imageAssignments.containsKey(masterclassKey)) {
      return _imageAssignments[masterclassKey];
    }

    // Find matching course
    final matchedCourse = AICertsService.findMatchingCourse(
      masterclassName: masterclass.title,
      courses: courses,
    );

    if (matchedCourse != null) {
      final imageUrl =
          matchedCourse.certificateBadgeUrl ?? matchedCourse.featureImageUrl;

      // Check if this image is already assigned to another masterclass
      if (_imageAssignments.containsValue(imageUrl)) {
        // Find an unused image from courses
        for (final course in courses) {
          final altImageUrl =
              course.certificateBadgeUrl ?? course.featureImageUrl;
          if (altImageUrl != null &&
              !_imageAssignments.containsValue(altImageUrl)) {
            _imageAssignments[masterclassKey] = altImageUrl;
            return altImageUrl;
          }
        }

        // If all images are used, generate unique placeholder based on index
        final uniquePlaceholder = 'placeholder_${_imageAssignments.length}';
        _imageAssignments[masterclassKey] = uniquePlaceholder;
        return null;
      }

      // Assign this image to the masterclass
      _imageAssignments[masterclassKey] = imageUrl ?? '';
      return imageUrl;
    } else {
      // If no match, try to assign an unused image
      for (final course in courses) {
        final altImageUrl =
            course.certificateBadgeUrl ?? course.featureImageUrl;
        if (altImageUrl != null &&
            !_imageAssignments.containsValue(altImageUrl)) {
          _imageAssignments[masterclassKey] = altImageUrl;
          return altImageUrl;
        }
      }

      // If all images are used, just use the first one from courses
      if (courses.isNotEmpty) {
        final firstImageUrl =
            courses.first.certificateBadgeUrl ?? courses.first.featureImageUrl;
        _imageAssignments[masterclassKey] = firstImageUrl ?? '';
        return firstImageUrl;
      }

      return null;
    }
  }

  // Set AI search query
  void setSearchQuery(String query) {
    if (_isDisposed) return;
    _updateState(state: _stateNotifier.value.copyWith(searchQuery: query));
  }

  // Reset all filters
  void resetFilters() {
    if (_isDisposed) return;
    _updateState(
        state: _stateNotifier.value.copyWith(
      selectedType: 'all',
      selectedCountry: null,
      selectedCity: null,
      selectedVenue: null,
      searchQuery: '',
    ));
    _updateLocationLists();
    _applyFilters();
  }

  void _processMasterclassData(List<Masterclass> data) {
    if (_isDisposed) return;
    final now = DateTime.now();

    final running = data.where((m) {
      if (m.startDate == null || m.endDate == null) return false;
      return now.isAfter(m.startDate!) && now.isBefore(m.endDate!);
    }).toList();

    final upcoming = data.where((m) {
      if (m.startDate == null) return false;
      return now.isBefore(m.startDate!);
    }).toList();

    final countries = _extractCountries(data);

    _updateState(
        state: _stateNotifier.value.copyWith(
      isLoading: false,
      allMasterclasses: data,
      running: running,
      upcoming: upcoming,
      countries: countries,
    ));

    _updateLocationLists();
    _applyFilters();
  }

  void setType(String type) {
    if (_isDisposed) return;
    _updateState(state: _stateNotifier.value.copyWith(selectedType: type));
    _applyFilters();
  }

  void setCountry(String? country) {
    if (_isDisposed) return;
    final state = _stateNotifier.value;

    _updateState(
        state: state.copyWith(
      selectedCountry: country,
      selectedCity: null,
      selectedVenue: null,
    ));

    _updateLocationLists();
    _applyFilters();
  }

  void setCity(String? city) {
    if (_isDisposed) return;
    final state = _stateNotifier.value;

    _updateState(
        state: state.copyWith(
      selectedCity: city,
      selectedVenue: null,
    ));

    _updateLocationLists();
    _applyFilters();
  }

  void setVenue(String? venue) {
    if (_isDisposed) return;
    _updateState(state: _stateNotifier.value.copyWith(selectedVenue: venue));
    _applyFilters();
  }

  void _updateLocationLists() {
    if (_isDisposed) return;
    final state = _stateNotifier.value;
    final allMasterclasses = state.allMasterclasses;

    // Filter by type first so location lists only show locations with that type
    final typeFiltered = allMasterclasses.where((mc) {
      return state.selectedType == 'all' ||
          (mc.streamType != null && mc.streamType == state.selectedType);
    }).toList();

    // 1. Available Countries (based on type)
    final availableCountries = typeFiltered
        .where((e) => e.countryName != null && e.countryName!.isNotEmpty)
        .map((e) => e.countryName!)
        .toSet()
        .toList()
      ..sort();

    // 2. Available Cities (based on type + country)
    List<String> availableCities = [];
    final countryFiltered = typeFiltered.where((mc) {
      return state.selectedCountry == null ||
          mc.countryName == state.selectedCountry;
    }).toList();

    availableCities = countryFiltered
        .where((e) => e.city != null && e.city!.isNotEmpty)
        .map((e) => e.city!)
        .toSet()
        .toList()
      ..sort();

    // 3. Available Venues (based on type + country + city)
    List<String> availableVenues = [];
    final cityFiltered = countryFiltered.where((mc) {
      return state.selectedCity == null || mc.city == state.selectedCity;
    }).toList();

    availableVenues = cityFiltered
        .where((e) => e.venue != null && e.venue!.isNotEmpty)
        .map((e) => e.venue!)
        .toSet()
        .toList()
      ..sort();

    _updateState(
        state: state.copyWith(
      countries: availableCountries,
      cities: availableCities,
      venues: availableVenues,
    ));
  }

  void _applyFilters() {
    if (_isDisposed) return;
    final state = _stateNotifier.value;
    final allMasterclasses = state.allMasterclasses;

    final filtered = allMasterclasses.where((mc) {
      final typeMatch = state.selectedType == 'all' ||
          (mc.streamType != null && mc.streamType == state.selectedType);

      final countryMatch = state.selectedCountry == null ||
          (mc.countryName != null && mc.countryName == state.selectedCountry);

      final cityMatch = state.selectedCity == null ||
          (mc.city != null && mc.city == state.selectedCity);

      final venueMatch = state.selectedVenue == null ||
          (mc.venue != null && mc.venue == state.selectedVenue);

      return typeMatch && countryMatch && cityMatch && venueMatch;
    }).toList();

    final events = _buildEvents(filtered);

    _updateState(
        state: state.copyWith(
      filteredMasterclasses: filtered,
      events: events,
    ));
  }

  Map<DateTime, List<Masterclass>> _buildEvents(
      List<Masterclass> masterclasses) {
    final events = <DateTime, List<Masterclass>>{};

    for (final mc in masterclasses) {
      if (mc.startDate == null || mc.endDate == null) continue;

      DateTime day =
          DateTime(mc.startDate!.year, mc.startDate!.month, mc.startDate!.day);
      final end =
          DateTime(mc.endDate!.year, mc.endDate!.month, mc.endDate!.day);

      while (!day.isAfter(end)) {
        final dateKey = DateTime(day.year, day.month, day.day);
        events.putIfAbsent(dateKey, () => []).add(mc);
        day = day.add(const Duration(days: 1));
      }
    }

    return events;
  }

  List<String> _extractCountries(List<Masterclass> list) {
    return list
        .where((e) => e.countryName != null && e.countryName!.isNotEmpty)
        .map((e) => e.countryName!)
        .toSet()
        .toList()
      ..sort();
  }

  List<Masterclass> getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _stateNotifier.value.events[key] ?? [];
  }

  Map<DateTime, List<Masterclass>> getEvents() => _stateNotifier.value.events;

  void refresh() => loadMasterclasses();

  void _scheduleAutoRefresh() {
    if (_isDisposed) return;
    _refreshTimer?.cancel();
    _refreshTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => refresh());
  }

  void _updateState({required MasterclassState state}) {
    if (!_isDisposed) {
      _stateNotifier.value = state;
    }
  }

  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    _stateNotifier.dispose();
  }
}
