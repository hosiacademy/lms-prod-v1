// lib/src/presentation/widgets/modals/aicerts/shared/aicerts_form_data.dart

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
      'full_name': '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'phone_iso_code': phoneIsoCode,
      'id_number': idNumberController.text.trim(),
      'date_of_birth': dobController.text.trim(),
      'gender': selectedGender,
      'address': addressController.text.trim(),
      'postal_code': postalCodeController.text.trim(),
      'city': cityController.text.trim(),
      'country_id': selectedCountry?.id,
      'state_id': selectedState?.id,
      'city_id': selectedCity?.id,
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
    };
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