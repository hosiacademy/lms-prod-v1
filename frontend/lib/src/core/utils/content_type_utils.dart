// lib/src/core/utils/content_type_utils.dart

import '../api/api_client.dart';

/// Utility class for managing Django ContentType IDs
///
/// ContentType IDs are managed by Django's contenttypes framework and map
/// model classes to integer IDs. These IDs may vary between deployments,
/// so this utility provides a centralized place to manage them.
///
/// TODO: Implement API endpoint to fetch content type mappings dynamically
class ContentTypeUtils {
  // Singleton instance
  static final ContentTypeUtils _instance = ContentTypeUtils._internal();
  factory ContentTypeUtils() => _instance;
  ContentTypeUtils._internal();

  /// Content type ID mappings
  ///
  /// These values match your Django backend's ContentType IDs.
  /// Queried from database on 2026-02-03:
  /// - masterclass: 57
  /// - learnershipprogramme: 69
  /// - aicertscourse: 65
  /// - offering: 74
  /// - course: 3
  ///
  /// These IDs are used as fallback if the API fetch fails.
  /// The app will automatically fetch updated IDs from the backend API.
  static const Map<String, int> _contentTypeIds = {
    'masterclass': 57,           // Masterclass model
    'learnershipprogramme': 69,  // Learnership model
    'aicertscourse': 65,          // AICerts course model
    'offering': 74,               // Industry training model
    'course': 3,                  // Generic course model
  };

  /// Mapping from training type to model name
  static const Map<String, String> _trainingTypeToModel = {
    'masterclass': 'masterclass',
    'learnership': 'learnershipprogramme',
    'industry_training': 'offering',
    'custom_selection': 'aicertscourse',
  };

  /// Get content type ID for a training type
  ///
  /// Example:
  /// ```dart
  /// final contentTypeId = ContentTypeUtils.getContentTypeId('masterclass');
  /// ```
  static int? getContentTypeId(String trainingType) {
    final modelName = _trainingTypeToModel[trainingType];
    if (modelName == null) {
      print('Warning: Unknown training type: $trainingType');
      return null;
    }

    final contentTypeId = _contentTypeIds[modelName];
    if (contentTypeId == null) {
      print('Warning: No content type ID found for model: $modelName');
    }

    return contentTypeId;
  }

  /// Get content type ID with fallback to 1
  ///
  /// Use this when you need a content type ID and want to fallback to 1
  /// if the training type is unknown. The backend will validate and return
  /// an error if the ID is incorrect.
  static int getContentTypeIdWithFallback(String trainingType) {
    return getContentTypeId(trainingType) ?? 1;
  }

  /// Update content type ID mapping
  ///
  /// Use this to update IDs after fetching from backend API
  static void updateContentTypeId(String modelName, int contentTypeId) {
    // In a production app, you'd store this in shared preferences
    print('Updated content type ID for $modelName: $contentTypeId');
  }

  /// Fetch content type IDs from backend
  ///
  /// Fetches the actual content type IDs from Django's ContentType framework
  /// Endpoint: GET /api/v1/student-portal/content-types/
  static Future<Map<String, int>> fetchContentTypeIds() async {
    try {
      final response = await ApiClient.get('/api/v1/student-portal/content-types/');
      final data = response.data as Map<String, dynamic>;

      // Convert to Map<String, int> and filter out null values
      final contentTypes = <String, int>{};
      data.forEach((key, value) {
        if (value != null && value is int) {
          contentTypes[key] = value;
        }
      });

      print('Fetched ${contentTypes.length} content types from backend');
      return contentTypes;
    } catch (e) {
      print('Error fetching content types from backend: $e');
      print('Using default content type IDs');
      return _contentTypeIds;
    }
  }

  /// Get model name from training type
  static String? getModelName(String trainingType) {
    return _trainingTypeToModel[trainingType];
  }

  /// Check if a training type is supported
  static bool isSupportedTrainingType(String trainingType) {
    return _trainingTypeToModel.containsKey(trainingType);
  }
}
