import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../../data/models/promotion.dart';

class PromotionService {
  static final PromotionService instance = PromotionService._();
  PromotionService._();

  List<Promotion> _cached = [];
  DateTime? _lastFetch;

  /// Fetch active promotions for a country code.
  /// Results are cached for 5 minutes to avoid repeated network calls.
  Future<List<Promotion>> fetchForOnboarding({String countryCode = 'ZA'}) async {
    final now = DateTime.now();
    if (_lastFetch != null && now.difference(_lastFetch!).inMinutes < 5 && _cached.isNotEmpty) {
      return _cached;
    }

    try {
      final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/v1/localization/promotions/'
        '?country=$countryCode&placement=onboarding',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        _cached = data
            .map((e) => Promotion.fromJson(e as Map<String, dynamic>))
            .where((p) => p.isCurrentlyActive)
            .toList();
        _lastFetch = now;
        return _cached;
      }
    } catch (_) {
      // silently fail — promos are non-critical
    }
    return [];
  }

  void clearCache() {
    _cached = [];
    _lastFetch = null;
  }
}
