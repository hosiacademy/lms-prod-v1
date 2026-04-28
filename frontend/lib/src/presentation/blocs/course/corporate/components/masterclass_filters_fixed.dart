// lib/src/presentation/blocs/course/corporate/components/masterclass_filters.dart
import 'package:flutter/material.dart';

class MasterclassFilters extends StatelessWidget {
  final String selectedType;
  final String? selectedCountry;
  final String? selectedCity;
  final String? selectedVenue;

  const MasterclassFilters({
    super.key,
    required this.selectedType,
    this.selectedCountry,
    this.selectedCity,
    this.selectedVenue,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Implement build method
    return Container();
  }
}
