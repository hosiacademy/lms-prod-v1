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
    return _buildSearchablePicker<location_models.Country>(
      label: widget.countryLabel ?? 'Country${widget.isRequired ? ' *' : ''}',
      value: _selectedCountry,
      items: _countries,
      isLoading: isLoading,
      icon: Icons.public,
      hint: 'Select country',
      itemBuilder: (country) => Row(
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
      searchMatcher: (country, query) =>
          country.name.toLowerCase().contains(query.toLowerCase()) ||
          country.code.toLowerCase().contains(query.toLowerCase()),
      onChanged: (country) {
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
    );
  }

  Widget _buildStateDropdown(bool isLoading) {
    final bool isEnabled = _selectedCountry != null;
    return _buildSearchablePicker<location_models.State>(
      label: widget.stateLabel ?? 'State/Province${widget.isRequired ? ' *' : ''}',
      value: _selectedState,
      items: _states,
      isLoading: isLoading && _states.isEmpty && isEnabled,
      icon: Icons.map_outlined,
      hint: isEnabled ? 'Select state' : 'Select country first',
      isEnabled: isEnabled,
      itemBuilder: (state) => Text(state.name),
      searchMatcher: (state, query) =>
          state.name.toLowerCase().contains(query.toLowerCase()),
      onChanged: (state) {
        setState(() {
          _selectedState = state;
          _selectedCity = null;
          _cities = [];
        });

        if (state != null) {
          context.read<LocationBloc>().add(SelectState(state));
        }

        _notifyChange();
      },
    );
  }

  Widget _buildCityDropdown(bool isLoading) {
    final bool isEnabled = _selectedState != null;
    return _buildSearchablePicker<location_models.City>(
      label: widget.cityLabel ?? 'City${widget.isRequired ? ' *' : ''}',
      value: _selectedCity,
      items: _cities,
      isLoading: isLoading && _cities.isEmpty && isEnabled,
      icon: Icons.location_city,
      hint: isEnabled ? 'Select city' : 'Select state first',
      isEnabled: isEnabled,
      itemBuilder: (city) => Text(city.name),
      searchMatcher: (city, query) =>
          city.name.toLowerCase().contains(query.toLowerCase()),
      onChanged: (city) {
        setState(() {
          _selectedCity = city;
        });

        if (city != null) {
          context.read<LocationBloc>().add(SelectCity(city));
        }

        _notifyChange();
      },
    );
  }

  Widget _buildSearchablePicker<T>({
    required String label,
    required T? value,
    required List<T> items,
    required bool isLoading,
    required IconData icon,
    required String hint,
    required Widget Function(T) itemBuilder,
    required bool Function(T, String) searchMatcher,
    required ValueChanged<T?> onChanged,
    bool isEnabled = true,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: isEnabled ? () => _showSearchableDialog<T>(
        label: label,
        items: items,
        itemBuilder: itemBuilder,
        searchMatcher: searchMatcher,
        onSelected: onChanged,
      ) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? colors.outline.withValues(alpha: 0.5) : colors.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(icon, color: isEnabled ? colors.primary : colors.onSurface.withValues(alpha: 0.38), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled ? colors.primary : colors.onSurface.withValues(alpha: 0.38),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? _getItemText(value) : hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null 
                        ? colors.onSurface 
                        : colors.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isEnabled ? colors.onSurface.withValues(alpha: 0.6) : colors.onSurface.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  String _getItemText(dynamic item) {
    if (item is location_models.Country) return item.name;
    if (item is location_models.State) return item.name;
    if (item is location_models.City) return item.name;
    return item.toString();
  }

  void _showSearchableDialog<T>({
    required String label,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required bool Function(T, String) searchMatcher,
    required ValueChanged<T?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchablePickerSheet<T>(
        label: label,
        items: items,
        itemBuilder: itemBuilder,
        searchMatcher: searchMatcher,
        onSelected: (val) {
          onSelected(val);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _notifyChange() {
    widget.onLocationChanged
        ?.call(_selectedCountry, _selectedState, _selectedCity);
  }
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final bool Function(T, String) searchMatcher;
  final ValueChanged<T?> onSelected;

  const _SearchablePickerSheet({
    required this.label,
    required this.items,
    required this.itemBuilder,
    required this.searchMatcher,
    required this.onSelected,
  });

  @override
  State<_SearchablePickerSheet<T>> createState() => _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  late List<T> _filteredItems;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => widget.searchMatcher(item, query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final padding = MediaQuery.of(context).viewInsets;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: padding.bottom),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select ${widget.label}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              autofocus: true,
            ),
          ),
          // List
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: colors.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No results found', style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredItems.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: colors.outlineVariant),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        title: widget.itemBuilder(item),
                        onTap: () => widget.onSelected(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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

class HorizontalCascadingLocationDropdowns extends StatelessWidget {
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
