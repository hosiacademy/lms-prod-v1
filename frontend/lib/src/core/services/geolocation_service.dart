import 'package:http/http.dart' as http;
import 'dart:convert';

class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();
  static GeolocationService get instance => _instance;
  
  GeolocationService._internal();
  
  Future<Map<String, dynamic>> detectLocation() async {
    try {
      final response = await http.get(Uri.parse('/api/v1/payments/detect-country/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'country_code': data['country_code'] ?? '',
          'country_name': data['country_name'] ?? '',
          'is_african': data['is_african'] ?? false,
          'currency': data['currency'] ?? 'USD',
        };
      }
    } catch (e) {
      // Ignore errors
    }
    
    return {
      'country_code': '',
      'country_name': '',
      'is_african': false,
      'currency': 'USD',
    };
  }
}
