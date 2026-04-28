// lib/src/core/api/student_portal_api_service.dart

import 'api_client.dart';
import '../../data/models/student_profile.dart';
import '../../data/models/wishlist.dart';
import '../../data/models/course_cart.dart';
import '../../data/models/course_catalog.dart';
import '../../data/models/location.dart';

class LearnerPortalApiService {
  static const String _baseUrl = '/api/v1/student-portal';

  // ===================================
  // LEARNER PROFILE
  // ===================================

  static Future<StudentProfile> getMyProfile() async {
    final response = await ApiClient.get('$_baseUrl/profile/me/');
    return StudentProfile.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> getCompanyDetails() async {
    final response = await ApiClient.get('$_baseUrl/profile/company_details/');
    return response.data as Map<String, dynamic>;
  }

  static Future<StudentProfile> updateCompanyDetails(
    Map<String, dynamic> companyDetails,
  ) async {
    final response = await ApiClient.post(
      '$_baseUrl/profile/update_company_details/',
      data: {'company_details': companyDetails},
    );
    return StudentProfile.fromJson(response.data as Map<String, dynamic>);
  }

  // ===================================
  // WISHLIST
  // ===================================

  static Future<List<Wishlist>> getWishlist() async {
    final response = await ApiClient.get('$_baseUrl/wishlist/');
    final items = _extractList(response.data);
    return items
        .map((item) => Wishlist.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Wishlist> addToWishlist({
    required int contentTypeId,
    required int objectId,
    required String trainingType,
    required String interestLevel,
    required String intendedStart,
    String? notes,
  }) async {
    final response = await ApiClient.post(
      '$_baseUrl/wishlist/',
      data: {
        'content_type': contentTypeId,
        'object_id': objectId,
        'training_type': trainingType,
        'interest_level': interestLevel,
        'intended_start': intendedStart,
        if (notes != null) 'notes': notes,
      },
    );
    return Wishlist.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<void> removeFromWishlist(int wishlistId) async {
    await ApiClient.removeFromWishlist(wishlistId);
  }

  static Future<Map<String, dynamic>> moveWishlistToCart(int wishlistId) async {
    final response = await ApiClient.post(
      '$_baseUrl/wishlist/$wishlistId/move_to_cart/',
      data: {},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<List<Wishlist>> getWishlistByTrainingType(
      String trainingType) async {
    final response = await ApiClient.get(
      '$_baseUrl/wishlist/by_training_type/',
      queryParameters: {'type': trainingType},
    );
    final items = _extractList(response.data);
    return items
        .map((item) => Wishlist.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Wishlist>> getUnconvertedWishlist() async {
    final response = await ApiClient.get('$_baseUrl/wishlist/unconverted/');
    final items = _extractList(response.data);
    return items
        .map((item) => Wishlist.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ===================================
  // COURSE CART
  // ===================================

  static Future<CourseCart> getActiveCart() async {
    final response = await ApiClient.get('$_baseUrl/cart/active/');
    return CourseCart.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<List<CourseCart>> getMyCarts() async {
    final response = await ApiClient.get('$_baseUrl/cart/');
    final items = _extractList(response.data);
    return items
        .map((item) => CourseCart.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<CourseCartItem> addToCart({
    required int cartId,
    required int contentTypeId,
    required int objectId,
    required String trainingType,
    bool fromWishlist = false,
  }) async {
    final response = await ApiClient.post(
      '$_baseUrl/cart/$cartId/add_item/',
      data: {
        'content_type_id': contentTypeId,
        'object_id': objectId,
        'training_type': trainingType,
        'from_wishlist': fromWishlist,
      },
    );
    return CourseCartItem.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<void> removeFromCart({
    required int cartId,
    required int itemId,
  }) async {
    await ApiClient.removeFromCart(cartId, itemId);
  }

  static Future<void> clearCart(int cartId) async {
    await ApiClient.post('$_baseUrl/cart/$cartId/clear/', data: {});
  }

  static Future<Map<String, dynamic>> checkoutCart({
    required int cartId,
    required bool usePreviousCompanyDetails,
    required bool isCorporateEnrollment,
  }) async {
    final response = await ApiClient.post(
      '$_baseUrl/cart/$cartId/checkout/',
      data: {
        'use_previous_company_details': usePreviousCompanyDetails,
        'is_corporate_enrollment': isCorporateEnrollment,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ===================================
  // COURSE CATALOG
  // ===================================

  static Future<List<CourseCatalogItem>> getCourseCatalog({
    String? trainingType,
    int? providerId,
    bool? featured,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (trainingType != null) queryParams['training_type'] = trainingType;
    if (providerId != null) queryParams['provider'] = providerId;
    if (featured != null) queryParams['featured'] = featured.toString();
    if (search != null) queryParams['search'] = search;

    final response = await ApiClient.get(
      '$_baseUrl/catalog/',
      queryParameters: queryParams,
    );
    final items = _extractList(response.data);
    return items
        .map((item) => CourseCatalogItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<CourseCatalogItem> getCatalogItem(int catalogId) async {
    final response = await ApiClient.get('$_baseUrl/catalog/$catalogId/');
    return CourseCatalogItem.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<List<CourseCatalogItem>> getCatalogByTrainingType(
      String trainingType) async {
    final response = await ApiClient.get(
      '$_baseUrl/catalog/by_training_type/',
      queryParameters: {'type': trainingType},
    );
    final items = _extractList(response.data);
    return items
        .map((item) => CourseCatalogItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Wishlist> addCatalogItemToWishlist(int catalogId) async {
    final response = await ApiClient.post(
      '$_baseUrl/catalog/$catalogId/add_to_wishlist/',
      data: {},
    );
    return Wishlist.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<CourseCartItem> addCatalogItemToCart(int catalogId) async {
    final response = await ApiClient.post(
      '$_baseUrl/catalog/$catalogId/add_to_cart/',
      data: {},
    );
    return CourseCartItem.fromJson(response.data as Map<String, dynamic>);
  }

  // ===================================
  // COURSE PROVIDERS
  // ===================================

  static Future<List<CourseProvider>> getCourseProviders() async {
    final response = await ApiClient.get('$_baseUrl/providers/');
    final items = _extractList(response.data);
    return items
        .map((item) => CourseProvider.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<CourseProvider> getCourseProvider(int providerId) async {
    final response = await ApiClient.get('$_baseUrl/providers/$providerId/');
    return CourseProvider.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<List<CourseCatalogItem>> getProviderCourses(
      int providerId) async {
    final response =
        await ApiClient.get('$_baseUrl/providers/$providerId/courses/');
    final items = _extractList(response.data);
    return items
        .map((item) => CourseCatalogItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ===================================
  // CASCADING DROPDOWNS (LOCATION)
  // ===================================

  static Future<List<Country>> getCountries(
      {bool includeStates = false}) async {
    final response = await ApiClient.get(
      '/api/v1/localization/countries/',
      queryParameters: includeStates ? {'include_states': 'true'} : null,
    );
    final items = _extractList(response.data);
    return items
        .map((item) => Country.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<State>> getStates({
    int? countryId,
    String? countryCode,
    bool includeCities = false,
  }) async {
    final queryParams = <String, dynamic>{};
    if (countryId != null) queryParams['country_id'] = countryId;
    if (countryCode != null) queryParams['country_code'] = countryCode;
    if (includeCities) queryParams['include_cities'] = 'true';

    final response = await ApiClient.get(
      '/api/v1/localization/states/',
      queryParameters: queryParams,
    );
    final items = _extractList(response.data);
    return items
        .map((item) => State.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<City>> getCities({
    int? stateId,
    int? countryId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (stateId != null) queryParams['state_id'] = stateId;
    if (countryId != null) queryParams['country_id'] = countryId;

    final response = await ApiClient.get(
      '/api/v1/localization/cities/',
      queryParameters: queryParams,
    );
    final items = _extractList(response.data);
    return items
        .map((item) => City.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ===================================
  // UTILITY
  // ===================================

  static List<dynamic> _extractList(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('results')) return body['results'] as List<dynamic>;
      if (body.containsKey('data')) return body['data'] as List<dynamic>;
      if (body.containsKey('countries'))
        return body['countries'] as List<dynamic>;
      if (body.containsKey('states')) return body['states'] as List<dynamic>;
      if (body.containsKey('cities')) return body['cities'] as List<dynamic>;
    }
    if (body is List<dynamic>) return body;
    return [];
  }
}
