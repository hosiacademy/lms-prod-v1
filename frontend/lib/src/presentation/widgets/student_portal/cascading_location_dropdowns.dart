// lib/src/presentation/widgets/student_portal/cascading_location_dropdowns.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/student_portal/location_bloc.dart';
import '../../../data/models/location.dart' as location_models;
import '../../../core/utils/responsive_utils.dart';

class CascadingLocationDropdowns extends StatefulWidget {
  final Function(location_models.Country? country, location_models.State? state,
      location_models.City? city)? onLocationChanged;
  final location_models.Country? initialCountry;
  final location_models.State? initialState;
  final location_models.City? initialCity;
  final bool isRequired;
  final String? countryLabel;
  final String? stateLabel;
  final String? cityLabel;

  const CascadingLocationDropdowns({
    super.key,
    this.onLocationChanged,
    this.initialCountry,
    this.initialState,
    this.initialCity,
    this.isRequired = false,
    this.countryLabel,
    this.stateLabel,
    this.cityLabel,
  });

  @override
  State<CascadingLocationDropdowns> createState() =>
      _CascadingLocationDropdownsState();
}

class _CascadingLocationDropdownsState
    extends State<CascadingLocationDropdowns> {
  location_models.Country? _selectedCountry;
  location_models.State? _selectedState;
  location_models.City? _selectedCity;
  List<location_models.Country> _countries = [];
  List<location_models.State> _states = [];
  List<location_models.City> _cities = [];
  bool _isLoadingInitialData = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _selectedState = widget.initialState;
    _selectedCity = widget.initialCity;

    // Load countries when widget initializes
    context.read<LocationBloc>().add(const LoadCountries());
    
    // Mark that we need to process initial values
    _isLoadingInitialData = widget.initialCountry != null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationBloc, LocationState>(
      listener: (context, state) {
        // Process initial values cascade: country -> state -> city
        if (_isLoadingInitialData) {
          if (state is CountriesLoaded && _selectedCountry != null) {
            _countries = state.countries;
            // Select the initial country to load its states
            context.read<LocationBloc>().add(SelectCountry(_selectedCountry!));
          } else if (state is StatesLoaded && _selectedState != null) {
            _countries = state.countries;
            _states = state.states;
            // Check if the selected state is in the loaded states
            final stateExists = _states.any((s) => s.id == _selectedState!.id);
            if (stateExists) {
              // Select the initial state to load its cities
              context.read<LocationBloc>().add(SelectState(_selectedState!));
            } else {
              _isLoadingInitialData = false;
            }
          } else if (state is CitiesLoaded && _selectedCity != null) {
            _countries = state.countries;
            _states = state.states;
            _cities = state.cities;
            // Check if the selected city is in the loaded cities
            final cityExists = _cities.any((c) => c.id == _selectedCity!.id);
            if (cityExists) {
              context.read<LocationBloc>().add(SelectCity(_selectedCity!));
            }
            _isLoadingInitialData = false;
          } else if (state is LocationError) {
            _isLoadingInitialData = false;
          }
        } else {
          // Normal operation (not loading initial data)
          if (state is CountriesLoaded) {
            _countries = state.countries;
          } else if (state is StatesLoaded) {
            _countries = state.countries;
            _states = state.states;
          } else if (state is CitiesLoaded) {
            _countries = state.countries;
            _states = state.states;
            _cities = state.cities;
          }
        }
      },
      builder: (context, state) {
        final bool isLoading = state is LocationLoading;

        // Responsive layout logic
        final isDesktop = context.isDesktop;
        final isMobileLandscape = context.isMobile && context.isLandscape;
        final spacing = ResponsiveUtils.getResponsiveSpacing(context);

        Widget content;
        if (isDesktop || isMobileLandscape) {
          // Horizontal layout for wider screens
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCountryDropdown(isLoading)),
              SizedBox(width: spacing),
              Expanded(child: _buildStateDropdown(isLoading)),
              SizedBox(width: spacing),
              Expanded(child: _buildCityDropdown(isLoading)),
            ],
          );
        } else {
          // Vertical layout for narrower screens
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCountryDropdown(isLoading),
              SizedBox(height: spacing),
              _buildStateDropdown(isLoading),
              SizedBox(height: spacing),
              _buildCityDropdown(isLoading),
            ],
          );
        }

        if (isLoading && _countries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return content;
      },
    );
  }

  Widget _buildCountryDropdown(bool isLoading) {
    final countries = _countries;

    if (_selectedCountry != null && countries.isNotEmpty) {
      try {
        _selectedCountry =
            countries.firstWhere((c) => c.id == _selectedCountry!.id);
      } catch (_) {}
    }

    return DropdownButtonFormField<location_models.Country>(
      key: ValueKey('country_${_selectedCountry?.id}'),
      value: _selectedCountry,
      decoration: InputDecoration(
        labelText:
            widget.countryLabel ?? 'Country${widget.isRequired ? ' *' : ''}',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.public),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      hint: const Text('Select country'),
      isExpanded: true,
      items: countries.map((country) {
        return DropdownMenuItem<location_models.Country>(
          value: country,
          child: Row(
            children: [
              Image.network(
                'https://flagcdn.com/w20/${country.code.toLowerCase()}.png',
                width: 20,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.flag, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(country.name)),
            ],
          ),
        );
      }).toList(),
      onChanged: (location_models.Country? country) {
        setState(() {
          _selectedCountry = country;
          _selectedState = null;
          _selectedCity = null;
          _states = [];
          _cities = [];
        });

        if (country != null) {
          context.read<LocationBloc>().add(SelectCountry(country));
        } else {
          context.read<LocationBloc>().add(ResetLocation());
        }

        _notifyChange();
      },
      validator: widget.isRequired
          ? (value) => value == null ? 'Please select a country' : null
          : null,
    );
  }

  Widget _buildStateDropdown(bool isLoading) {
    final states = _states;
    final bool isEnabled = _selectedCountry != null;

    if (_selectedState != null && states.isNotEmpty) {
      try {
        _selectedState = states.firstWhere((s) => s.id == _selectedState!.id);
      } catch (_) {}
    }

    return DropdownButtonFormField<location_models.State>(
      key: ValueKey('state_${_selectedCountry?.id}_${_selectedState?.id}'),
      value: _selectedState,
      decoration: InputDecoration(
        labelText: widget.stateLabel ??
            'State/Province${widget.isRequired ? ' *' : ''}',
        border: const OutlineInputBorder(),
        prefixIcon: isLoading && states.isEmpty && isEnabled
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.map_outlined),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        enabled: isEnabled,
      ),
      hint: Text(isEnabled ? 'Select state' : 'Select country first'),
      isExpanded: true,
      items: states.map((state) {
        return DropdownMenuItem<location_models.State>(
          value: state,
          child: Text(state.name),
        );
      }).toList(),
      onChanged: isEnabled
          ? (location_models.State? state) {
              setState(() {
                _selectedState = state;
                _selectedCity = null;
                _cities = [];
              });

              if (state != null) {
                context.read<LocationBloc>().add(SelectState(state));
              }

              _notifyChange();
            }
          : null,
      validator: widget.isRequired && isEnabled
          ? (value) => value == null ? 'Please select a state' : null
          : null,
    );
  }

  Widget _buildCityDropdown(bool isLoading) {
    final cities = _cities;
    final bool isEnabled = _selectedState != null;

    if (_selectedCity != null && cities.isNotEmpty) {
      try {
        _selectedCity = cities.firstWhere((c) => c.id == _selectedCity!.id);
      } catch (_) {}
    }

    return DropdownButtonFormField<location_models.City>(
      key: ValueKey('city_${_selectedState?.id}_${_selectedCity?.id}'),
      value: _selectedCity,
      decoration: InputDecoration(
        labelText: widget.cityLabel ?? 'City${widget.isRequired ? ' *' : ''}',
        border: const OutlineInputBorder(),
        prefixIcon: isLoading && cities.isEmpty && isEnabled
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.location_city),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        enabled: isEnabled,
      ),
      hint: Text(
        isEnabled
            ? 'Select city'
            : (_selectedCountry == null
                ? 'Select country first'
                : 'Select state first'),
      ),
      isExpanded: true,
      items: cities.map((city) {
        return DropdownMenuItem<location_models.City>(
          value: city,
          child: Text(city.name),
        );
      }).toList(),
      onChanged: isEnabled
          ? (location_models.City? city) {
              setState(() {
                _selectedCity = city;
              });

              if (city != null) {
                context.read<LocationBloc>().add(SelectCity(city));
              }

              _notifyChange();
            }
          : null,
      validator: widget.isRequired && isEnabled
          ? (value) => value == null ? 'Please select a city' : null
          : null,
    );
  }

  void _notifyChange() {
    widget.onLocationChanged
        ?.call(_selectedCountry, _selectedState, _selectedCity);
  }
}

class CompactCascadingLocationDropdowns extends StatelessWidget {
  final Function(location_models.Country? country, location_models.State? state,
      location_models.City? city)? onLocationChanged;
  final location_models.Country? initialCountry;
  final location_models.State? initialState;
  final location_models.City? initialCity;
  final bool isRequired;

  const CompactCascadingLocationDropdowns({
    super.key,
    this.onLocationChanged,
    this.initialCountry,
    this.initialState,
    this.initialCity,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return CascadingLocationDropdowns(
      onLocationChanged: onLocationChanged,
      initialCountry: initialCountry,
      initialState: initialState,
      initialCity: initialCity,
      isRequired: isRequired,
    );
  }
}

class HorizontalCascadingLocationDropdowns extends StatefulWidget {
  final Function(location_models.Country? country, location_models.State? state,
      location_models.City? city)? onLocationChanged;
  final location_models.Country? initialCountry;
  final location_models.State? initialState;
  final location_models.City? initialCity;
  final bool isRequired;

  const HorizontalCascadingLocationDropdowns({
    super.key,
    this.onLocationChanged,
    this.initialCountry,
    this.initialState,
    this.initialCity,
    this.isRequired = false,
  });

  @override
  State<HorizontalCascadingLocationDropdowns> createState() =>
      _HorizontalCascadingLocationDropdownsState();
}

class _HorizontalCascadingLocationDropdownsState
    extends State<HorizontalCascadingLocationDropdowns> {
  location_models.Country? _selectedCountry;
  location_models.State? _selectedState;
  location_models.City? _selectedCity;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _selectedState = widget.initialState;
    _selectedCity = widget.initialCity;
    context.read<LocationBloc>().add(const LoadCountries());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        if (state is LocationLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<location_models.Country> countries = [];
        List<location_models.State> states = [];
        List<location_models.City> cities = [];

        if (state is CountriesLoaded) {
          countries = state.countries;
        } else if (state is StatesLoaded) {
          countries = state.countries;
          states = state.states;
        } else if (state is CitiesLoaded) {
          countries = state.countries;
          states = state.states;
          cities = state.cities;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildCountryDropdown(countries),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStateDropdown(states),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCityDropdown(cities),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCountryDropdown(List<location_models.Country> countries) {
    return DropdownButtonFormField<location_models.Country>(
      value: _selectedCountry,
      decoration: const InputDecoration(
        labelText: 'Country',
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: countries.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text(c.name),
        );
      }).toList(),
      onChanged: (country) {
        setState(() {
          _selectedCountry = country;
          _selectedState = null;
          _selectedCity = null;
        });
        if (country != null) {
          context.read<LocationBloc>().add(SelectCountry(country));
        }
        _notifyChange();
      },
    );
  }

  Widget _buildStateDropdown(List<location_models.State> states) {
    return DropdownButtonFormField<location_models.State>(
      value: _selectedState,
      decoration: const InputDecoration(
        labelText: 'State',
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: states.map((s) {
        return DropdownMenuItem(
          value: s,
          child: Text(s.name),
        );
      }).toList(),
      onChanged: _selectedCountry != null
          ? (state) {
              setState(() {
                _selectedState = state;
                _selectedCity = null;
              });
              if (state != null) {
                context.read<LocationBloc>().add(SelectState(state));
              }
              _notifyChange();
            }
          : null,
    );
  }

  Widget _buildCityDropdown(List<location_models.City> cities) {
    return DropdownButtonFormField<location_models.City>(
      value: _selectedCity,
      decoration: const InputDecoration(
        labelText: 'City',
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: cities.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text(c.name),
        );
      }).toList(),
      onChanged: _selectedState != null
          ? (city) {
              setState(() => _selectedCity = city);
              if (city != null) {
                context.read<LocationBloc>().add(SelectCity(city));
              }
              _notifyChange();
            }
          : null,
    );
  }

  void _notifyChange() {
    widget.onLocationChanged
        ?.call(_selectedCountry, _selectedState, _selectedCity);
  }
}
