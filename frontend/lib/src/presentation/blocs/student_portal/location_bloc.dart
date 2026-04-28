// lib/src/presentation/blocs/student_portal/location_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/location.dart';
import '../../../core/api/student_portal_api_service.dart';

// ===================================
// EVENTS
// ===================================

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LoadCountries extends LocationEvent {
  final bool includeStates;

  const LoadCountries({this.includeStates = false});

  @override
  List<Object?> get props => [includeStates];
}

class LoadStates extends LocationEvent {
  final int? countryId;
  final String? countryCode;
  final bool includeCities;

  const LoadStates({
    this.countryId,
    this.countryCode,
    this.includeCities = false,
  });

  @override
  List<Object?> get props => [countryId, countryCode, includeCities];
}

class LoadCities extends LocationEvent {
  final int? stateId;
  final int? countryId;

  const LoadCities({
    this.stateId,
    this.countryId,
  });

  @override
  List<Object?> get props => [stateId, countryId];
}

class SelectCountry extends LocationEvent {
  final Country country;

  const SelectCountry(this.country);

  @override
  List<Object?> get props => [country];
}

class SelectState extends LocationEvent {
  final State state;

  const SelectState(this.state);

  @override
  List<Object?> get props => [state];
}

class SelectCity extends LocationEvent {
  final City city;

  const SelectCity(this.city);

  @override
  List<Object?> get props => [city];
}

class ResetLocation extends LocationEvent {}

// ===================================
// STATES
// ===================================

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class CountriesLoaded extends LocationState {
  final List<Country> countries;
  final Country? selectedCountry;

  const CountriesLoaded(this.countries, {this.selectedCountry});

  @override
  List<Object?> get props => [countries, selectedCountry];
}

class StatesLoaded extends LocationState {
  final List<Country> countries;
  final Country selectedCountry;
  final List<State> states;
  final State? selectedState;

  const StatesLoaded(
    this.countries,
    this.selectedCountry,
    this.states, {
    this.selectedState,
  });

  @override
  List<Object?> get props =>
      [countries, selectedCountry, states, selectedState];
}

class CitiesLoaded extends LocationState {
  final List<Country> countries;
  final Country selectedCountry;
  final List<State> states;
  final State? selectedState;
  final List<City> cities;
  final City? selectedCity;

  const CitiesLoaded(
    this.countries,
    this.selectedCountry,
    this.states,
    this.selectedState,
    this.cities, {
    this.selectedCity,
  });

  @override
  List<Object?> get props => [
        countries,
        selectedCountry,
        states,
        selectedState,
        cities,
        selectedCity,
      ];
}

class LocationError extends LocationState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}

// ===================================
// BLOC
// ===================================

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  List<Country> _countries = [];
  Country? _selectedCountry;
  List<State> _states = [];
  State? _selectedState;
  List<City> _cities = [];
  City? _selectedCity;

  LocationBloc() : super(LocationInitial()) {
    on<LoadCountries>(_onLoadCountries);
    on<LoadStates>(_onLoadStates);
    on<LoadCities>(_onLoadCities);
    on<SelectCountry>(_onSelectCountry);
    on<SelectState>(_onSelectState);
    on<SelectCity>(_onSelectCity);
    on<ResetLocation>(_onResetLocation);
  }

  Future<void> _onLoadCountries(
    LoadCountries event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    try {
      _countries = await LearnerPortalApiService.getCountries(
        includeStates: event.includeStates,
      );
      emit(CountriesLoaded(_countries));
    } catch (e) {
      emit(LocationError('Failed to load countries: ${e.toString()}'));
    }
  }

  Future<void> _onLoadStates(
    LoadStates event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    try {
      _states = await LearnerPortalApiService.getStates(
        countryId: event.countryId,
        countryCode: event.countryCode,
        includeCities: event.includeCities,
      );

      if (_selectedCountry != null) {
        emit(StatesLoaded(_countries, _selectedCountry!, _states));
      } else {
        emit(LocationError('Country not selected'));
      }
    } catch (e) {
      emit(LocationError('Failed to load states: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCities(
    LoadCities event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    try {
      _cities = await LearnerPortalApiService.getCities(
        stateId: event.stateId,
        countryId: event.countryId,
      );

      if (_selectedCountry != null) {
        emit(CitiesLoaded(
          _countries,
          _selectedCountry!,
          _states,
          _selectedState,
          _cities,
        ));
      } else {
        emit(LocationError('Country not selected'));
      }
    } catch (e) {
      emit(LocationError('Failed to load cities: ${e.toString()}'));
    }
  }

  Future<void> _onSelectCountry(
    SelectCountry event,
    Emitter<LocationState> emit,
  ) async {
    _selectedCountry = event.country;
    _selectedState = null;
    _selectedCity = null;
    _states = [];
    _cities = [];

    // Emit state with empty lists first to signal reset to the UI
    emit(CitiesLoaded(
      _countries,
      _selectedCountry!,
      _states,
      _selectedState,
      _cities,
    ));

    try {
      // Load states and cities for selected country in parallel
      final results = await Future.wait([
        LearnerPortalApiService.getStates(countryId: event.country.id),
        LearnerPortalApiService.getCities(countryId: event.country.id),
      ]);

      _states = results[0] as List<State>;
      _cities = results[1] as List<City>;

      emit(CitiesLoaded(
        _countries,
        _selectedCountry!,
        _states,
        _selectedState,
        _cities,
      ));
    } catch (e) {
      emit(LocationError('Failed to load location data: ${e.toString()}'));
    }
  }

  Future<void> _onSelectState(
    SelectState event,
    Emitter<LocationState> emit,
  ) async {
    _selectedState = event.state;
    _selectedCity = null;
    _cities = [];

    // Stay in CitiesLoaded state but with empty cities and current states
    if (_selectedCountry != null) {
      emit(CitiesLoaded(
        _countries,
        _selectedCountry!,
        _states,
        _selectedState,
        _cities,
      ));
    }

    try {
      _cities =
          await LearnerPortalApiService.getCities(stateId: event.state.id);
      if (_selectedCountry != null) {
        emit(CitiesLoaded(
          _countries,
          _selectedCountry!,
          _states,
          _selectedState,
          _cities,
        ));
      }
    } catch (e) {
      emit(LocationError('Failed to load cities: ${e.toString()}'));
    }
  }

  void _onSelectCity(
    SelectCity event,
    Emitter<LocationState> emit,
  ) {
    _selectedCity = event.city;

    if (_selectedCountry != null) {
      emit(CitiesLoaded(
        _countries,
        _selectedCountry!,
        _states,
        _selectedState,
        _cities,
        selectedCity: _selectedCity,
      ));
    }
  }

  void _onResetLocation(
    ResetLocation event,
    Emitter<LocationState> emit,
  ) {
    _selectedCountry = null;
    _selectedState = null;
    _selectedCity = null;
    _states = [];
    _cities = [];

    emit(CountriesLoaded(_countries));
  }
}
