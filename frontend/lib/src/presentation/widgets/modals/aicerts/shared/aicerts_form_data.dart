import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../../../../data/models/location.dart' as location_models;
import '../../../../../core/utils/african_phone_validator.dart';

/// AICERTS-specific form data with additional fields for AI training pathways
class AicertsLearnerFormData {
  // Core learner information
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  String phoneIsoCode = 'ZA';
  String? formattedPhoneNumber;
  bool isPhoneValid = false;
  bool emailVerified = false;
  bool phoneVerified = true; // SMS OTP removed, default to true

  // Legal & identification
  final idNumberController = TextEditingController();
  final dobController = TextEditingController();
  String? selectedGender;

  // Location
  final addressController = TextEditingController();
  final postalCodeController = TextEditingController();
  final cityController = TextEditingController();
  
  location_models.Country? selectedCountry;
  location_models.State? selectedState;
  location_models.City? selectedCity;
  String? selectedCountryName;

  // Education & professional background
  final occupationController = TextEditingController();
  String? selectedEducationLevel;
  final institutionController = TextEditingController();
  
  // AICERTS-specific fields
  String? selectedExperienceLevel; // Beginner, Intermediate, Advanced
  List<String> selectedAiTools = []; // AI tools user is interested in
  String? selectedStreamType; // Technical or Professional
  String? selectedSpecialization; // Optional specialization area
  
  // Emergency contact
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  String emergencyPhoneIsoCode = 'ZA';
  String? formattedEmergencyPhone;
  bool isEmergencyPhoneValid = false;
  String? selectedEmergencyRelationship;

  // Additional information
  final dietaryController = TextEditingController(text: 'n/a');
  final accessibilityController = TextEditingController(text: 'n/a');
  final notesController = TextEditingController(text: 'n/a');

  // Terms
  bool termsAccepted = false;
  bool aicertsPlatformAgreement = false; // Specific agreement for AICERTS platform

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    idNumberController.dispose();
    dobController.dispose();
    addressController.dispose();
    postalCodeController.dispose();
    cityController.dispose();
    occupationController.dispose();
    institutionController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    dietaryController.dispose();
    accessibilityController.dispose();
    notesController.dispose();
  }

  bool validate() {
    // Core validation
    if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty) return false;
    if (emailController.text.trim().isEmpty) return false;
    if (phoneController.text.trim().isEmpty) return false;

    // Phone validation
    final info = AfricanPhoneValidator.getInfoForCountry(phoneIsoCode);
    if (info != null) {
      final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < info.minDigits || digits.length > info.maxDigits) {
        return false;
      }
    }
    
    if (!emailVerified) return false;

    if (idNumberController.text.trim().isEmpty) return false;
    if (dobController.text.trim().isEmpty) return false;
    if (selectedGender == null) return false;
    if (selectedCountry == null) return false;
    if (selectedState == null) return false;
    
    // AICERTS-specific validation
    if (!termsAccepted) return false;
    if (!aicertsPlatformAgreement) return false;
    if (selectedStreamType == null) return false;

    return true;
  }

  /// Get AICERTS-specific form data for API submission
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'phone_iso_code': phoneIsoCode,
      'id_number': idNumberController.text.trim(),
      'date_of_birth': dobController.text.trim(),
      'gender': selectedGender,
      'address': addressController.text.trim(),
      'postal_code': postalCodeController.text.trim(),
      'city_id': selectedCity?.id,
      'state_id': selectedState?.id,
      'country_id': selectedCountry?.id,
      'occupation': occupationController.text.trim(),
      'education_level': selectedEducationLevel,
      'institution': institutionController.text.trim(),
      'experience_level': selectedExperienceLevel,
      'ai_tools_interested': selectedAiTools,
      'stream_type': selectedStreamType,
      'specialization': selectedSpecialization,
      'emergency_name': emergencyNameController.text.trim(),
      'emergency_phone': emergencyPhoneController.text.trim(),
      'emergency_relationship': selectedEmergencyRelationship,
      'dietary_requirements': dietaryController.text.trim(),
      'accessibility_requirements': accessibilityController.text.trim(),
      'additional_notes': notesController.text.trim(),
      'terms_accepted': termsAccepted,
      'aicerts_platform_agreement': aicertsPlatformAgreement,
      'email_verified': emailVerified,
    };
  }

  /// Restore state from JSON
  void fromJson(Map<String, dynamic> json) {
    firstNameController.text = json['first_name'] ?? '';
    lastNameController.text = json['last_name'] ?? '';
    emailController.text = json['email'] ?? '';
    phoneController.text = json['phone'] ?? '';
    phoneIsoCode = json['phone_iso_code'] ?? 'ZA';
    idNumberController.text = json['id_number'] ?? '';
    dobController.text = json['date_of_birth'] ?? '';
    selectedGender = json['gender'];
    addressController.text = json['address'] ?? '';
    postalCodeController.text = json['postal_code'] ?? '';
    occupationController.text = json['occupation'] ?? '';
    selectedEducationLevel = json['education_level'];
    institutionController.text = json['institution'] ?? '';
    selectedExperienceLevel = json['experience_level'];
    selectedAiTools = List<String>.from(json['ai_tools_interested'] ?? []);
    selectedStreamType = json['stream_type'];
    selectedSpecialization = json['specialization'];
    emergencyNameController.text = json['emergency_name'] ?? '';
    emergencyPhoneController.text = json['emergency_phone'] ?? '';
    selectedEmergencyRelationship = json['emergency_relationship'];
    dietaryController.text = json['dietary_requirements'] ?? 'n/a';
    accessibilityController.text = json['accessibility_requirements'] ?? 'n/a';
    notesController.text = json['additional_notes'] ?? 'n/a';
    termsAccepted = json['terms_accepted'] ?? false;
    aicertsPlatformAgreement = json['aicerts_platform_agreement'] ?? false;
    emailVerified = json['email_verified'] ?? false;
  }

  /// Save current form state to local storage
  Future<void> saveToStorage(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(toJson()));
    } catch (e) {
      debugPrint('Error saving AICERTS learner data: $e');
    }
  }

  /// Load form state from local storage
  Future<void> loadFromStorage(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(key);
      if (data != null) {
        fromJson(jsonDecode(data));
      }
    } catch (e) {
      debugPrint('Error loading AICERTS learner data: $e');
    }
  }
}


/// Corporate enrollment data for AICERTS courses
class AicertsCorporateLearnerData {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  String? selectedRole; // Role in company
  String? selectedDepartment; // Department
  
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
  }
  
  bool validate() {
    return firstNameController.text.trim().isNotEmpty && lastNameController.text.trim().isNotEmpty &&
           emailController.text.trim().isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'email': emailController.text.trim(),
      'role': selectedRole,
      'department': selectedDepartment,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    firstNameController.text = json['first_name'] ?? '';
    lastNameController.text = json['last_name'] ?? '';
    emailController.text = json['email'] ?? '';
    selectedRole = json['role'];
    selectedDepartment = json['department'];
  }

  Future<void> saveToStorage(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(toJson()));
    } catch (e) {
      debugPrint('Error saving AICERTS corporate data: $e');
    }
  }

  Future<void> loadFromStorage(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(key);
      if (data != null) {
        fromJson(jsonDecode(data));
      }
    } catch (e) {
      debugPrint('Error loading AICERTS corporate data: $e');
    }
  }
}

/// Evidence upload for AICERTS prerequisites
class AicertsEvidenceUploadData {
  final String prerequisiteName;
  String? fileName;
  String? fileUrl;
  bool isUploaded = false;
  
  AicertsEvidenceUploadData({
    required this.prerequisiteName,
  });
}