// country_selector.dart
import 'package:flutter/material.dart';
import '../../core/constants/african_currencies.dart';
import '../../core/services/currency_service.dart';

class CountrySelector extends StatefulWidget {
  final String? selectedCountryCode;
  final Function(String countryCode) onCountrySelected;
  final bool showCurrencyInfo;
  
  const CountrySelector({
    super.key,
    this.selectedCountryCode,
    required this.onCountrySelected,
    this.showCurrencyInfo = true,
  });
  
  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  final TextEditingController _searchController = TextEditingController();
  List<AfricanCountry> _filteredCountries = AfricanCurrencies.countries;
  String? _selectedCountryCode;
  
  @override
  void initState() {
    super.initState();
    _selectedCountryCode = widget.selectedCountryCode;
    _filteredCountries = AfricanCurrencies.countries;
    
    _searchController.addListener(() {
      _filterCountries(_searchController.text);
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = AfricanCurrencies.countries;
      } else {
        _filteredCountries = AfricanCurrencies.countries.where((country) {
          return country.name.toLowerCase().contains(query.toLowerCase()) ||
                 country.code.toLowerCase().contains(query.toLowerCase()) ||
                 country.currencyName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
  
  void _selectCountry(AfricanCountry country) {
    setState(() {
      _selectedCountryCode = country.code;
    });
    widget.onCountrySelected(country.code);
    Navigator.pop(context);
  }
  
  Future<void> _showCountryPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search country...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    return ListTile(
                      leading: Text(
                        _getFlagEmoji(country.code),
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(country.name),
                      subtitle: widget.showCurrencyInfo
                          ? Text('${country.currencyName} (${country.currencyCode})')
                          : null,
                      trailing: _selectedCountryCode == country.code
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () => _selectCountry(country),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _getFlagEmoji(String countryCode) {
    final codePoints = countryCode
        .toUpperCase()
        .split('')
        .map((char) => 127397 + char.codeUnitAt(0))
        .toList();
    return String.fromCharCodes(codePoints);
  }
  
  @override
  Widget build(BuildContext context) {
    final selectedCountry = _selectedCountryCode != null
        ? AfricanCurrencies.getCountryByCode(_selectedCountryCode!)
        : null;
    
    return GestureDetector(
      onTap: () => _showCountryPicker(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (selectedCountry != null) ...[
              Text(
                _getFlagEmoji(selectedCountry.code),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCountry.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.showCurrencyInfo)
                      Text(
                        '${selectedCountry.currencyName} • ${selectedCountry.currencyCode} ${selectedCountry.currencySymbol}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              const Icon(Icons.public, color: Colors.grey),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Select Country',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class CurrencyDisplay extends StatelessWidget {
  final String countryCode;
  final double amount;
  final TextStyle? amountStyle;
  final bool showCurrencyName;
  
  const CurrencyDisplay({
    super.key,
    required this.countryCode,
    required this.amount,
    this.amountStyle,
    this.showCurrencyName = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final country = AfricanCurrencies.getCountryByCode(countryCode);
    if (country == null) {
      return Text(CurrencyService.instance.formatPrice(amount, currencyCode: 'USD'), style: amountStyle);
    }
    
    final formattedAmount = AfricanCurrencies.formatAmount(amount, countryCode);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(formattedAmount, style: amountStyle),
        if (showCurrencyName)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              country.currencyCode,
              style: TextStyle(
                fontSize: amountStyle?.fontSize != null 
                    ? (amountStyle!.fontSize! * 0.8) 
                    : 12,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
}
