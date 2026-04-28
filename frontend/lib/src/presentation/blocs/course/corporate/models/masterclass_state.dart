import '../../../../../data/models/masterclass.dart';
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
  final List<AICertsCourse> aicertsCourses;
  final bool isLoadingCourses;

  const MasterclassState({
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
    List<AICertsCourse>? aicertsCourses,
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
