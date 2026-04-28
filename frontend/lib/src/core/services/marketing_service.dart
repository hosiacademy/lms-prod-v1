// lib/src/core/services/marketing_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';

class MarketingService {
  static const String _mailingListKey = 'hosi_local_mailing_lists';

  /// Save a mailing list locally in the frontend
  static Future<void> saveLocalMailingList(String name, List<String> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final existingRaw = prefs.getString(_mailingListKey);
    List<Map<String, dynamic>> lists = [];
    
    if (existingRaw != null) {
      lists = List<Map<String, dynamic>>.from(json.decode(existingRaw));
    }
    
    lists.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': name,
      'contacts': contacts,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_mailingListKey, json.encode(lists));
  }

  /// Get all locally saved mailing lists
  static Future<List<Map<String, dynamic>>> getLocalMailingLists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mailingListKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(raw));
  }

  /// Sync a local mailing list to the database
  static Future<void> syncToDatabase(Map<String, dynamic> localList) async {
    await ApiClient.post('/api/v1/payments/admin/mailing-lists/', data: {
      'name': localList['name'],
      'contacts': localList['contacts'],
    });
  }
  
  /// Delete a local mailing list
  static Future<void> deleteLocalList(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mailingListKey);
    if (raw == null) return;
    
    List<Map<String, dynamic>> lists = List<Map<String, dynamic>>.from(json.decode(raw));
    lists.removeWhere((l) => l['id'] == id);
    
    await prefs.setString(_mailingListKey, json.encode(lists));
  }
}
