/// Administrator and Admin Chat System models for HR and executive admin relationships

/// Administrator Profile model - represents admin users from 'administrators' table
class Administrator {
  final int id;
  final String adminId;
  final int userId;
  final String adminType; // 'hr', 'executive', 'sales', 'marketing', 'payment', 'system', 'general'
  final bool isExecutiveAdmin;
  final bool isSalesAdmin;
  final bool isMarketingAdmin;
  final bool isActive;
  final Map<String, dynamic>? permissions;
  final List<int>? assignedCountryIds;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Cached user info
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;

  Administrator({
    required this.id,
    required this.adminId,
    required this.userId,
    required this.adminType,
    this.isExecutiveAdmin = false,
    this.isSalesAdmin = false,
    this.isMarketingAdmin = false,
    this.isActive = true,
    this.permissions,
    this.assignedCountryIds,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
  });

  factory Administrator.fromJson(Map<String, dynamic> json) {
    return Administrator(
      id: json['id'] ?? 0,
      adminId: json['admin_id'] ?? '',
      userId: json['user'] ?? 0,
      adminType: json['admin_type'] ?? 'general',
      isExecutiveAdmin: json['is_executive_admin'] ?? false,
      isSalesAdmin: json['is_sales_admin'] ?? false,
      isMarketingAdmin: json['is_marketing_admin'] ?? false,
      isActive: json['is_active'] ?? true,
      permissions: json['permissions'] != null ? Map<String, dynamic>.from(json['permissions']) : null,
      assignedCountryIds: json['assigned_country_ids'] != null ? List<int>.from(json['assigned_country_ids']) : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      userName: json['user_name'],
      userEmail: json['user_email'],
      userAvatarUrl: json['user_avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'user': userId,
      'admin_type': adminType,
      'is_executive_admin': isExecutiveAdmin,
      'is_sales_admin': isSalesAdmin,
      'is_marketing_admin': isMarketingAdmin,
      'is_active': isActive,
      'permissions': permissions,
      'assigned_country_ids': assignedCountryIds,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get displayName => userName ?? adminId;

  bool get isHrAdmin => adminType == 'hr';
  bool get isExecutive => adminType == 'executive' || isExecutiveAdmin;
  bool get isSalesAdminType => adminType == 'sales' || isSalesAdmin;
  bool get isMarketingAdminType => adminType == 'marketing' || isMarketingAdmin;
  bool get isSystemAdmin => adminType == 'system';
}

/// Executive Country Assignment - executive admin assigned to a country
class ExecutiveCountryAssignment {
  final int id;
  final int executiveAdminId;
  final String? executiveAdminCode;
  final int countryId;
  final String? countryName;
  final String regionLevel; // 'country', 'region', 'subregion', 'province'
  final String assignmentType; // 'executive_coverage', 'supervision', etc.
  final int? assignedById;
  final DateTime assignedAt;
  final bool isActive;
  final String? coverageArea;
  final List<dynamic>? responsibilities;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExecutiveCountryAssignment({
    required this.id,
    required this.executiveAdminId,
    this.executiveAdminCode,
    required this.countryId,
    this.countryName,
    this.regionLevel = 'country',
    this.assignmentType = 'executive_coverage',
    this.assignedById,
    required this.assignedAt,
    this.isActive = true,
    this.coverageArea,
    this.responsibilities,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory ExecutiveCountryAssignment.fromJson(Map<String, dynamic> json) {
    return ExecutiveCountryAssignment(
      id: json['id'] ?? 0,
      executiveAdminId: json['executive_admin'] ?? 0,
      executiveAdminCode: json['executive_admin_code'],
      countryId: json['country'] ?? 0,
      countryName: json['country_name'],
      regionLevel: json['region_level'] ?? 'country',
      assignmentType: json['assignment_type'] ?? 'executive_coverage',
      assignedById: json['assigned_by'],
      assignedAt: json['assigned_at'] != null 
          ? DateTime.parse(json['assigned_at'])
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
      coverageArea: json['coverage_area'],
      responsibilities: json['responsibilities'] != null ? List<dynamic>.from(json['responsibilities']) : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'executive_admin': executiveAdminId,
      'country': countryId,
      'region_level': regionLevel,
      'assignment_type': assignmentType,
      'assigned_by': assignedById,
      'assigned_at': assignedAt.toIso8601String(),
      'is_active': isActive,
      'coverage_area': coverageArea,
      'responsibilities': responsibilities,
      'notes': notes,
    };
  }

  String get coverageType {
    switch (regionLevel) {
      case 'country':
        return 'Country Coverage';
      case 'region':
        return 'Regional Coverage';
      case 'subregion':
        return 'Sub-Regional Coverage';
      default:
        return 'Specific Area Coverage';
    }
  }
}

/// Sales/Marketing Country Assignment - sales/marketing admin assigned to a country
class SalesMarketingCountryAssignment {
  final int id;
  final int salesMarketingAdminId;
  final String? adminCode;
  final int countryId;
  final String? countryName;
  final String adminType; // 'sales', 'marketing', 'both'
  final String assignmentType;
  final int? assignedById;
  final DateTime assignedAt;
  final bool isActive;
  final double? salesTarget;
  final double? marketingBudget;
  final Map<String, dynamic>? performanceMetrics;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SalesMarketingCountryAssignment({
    required this.id,
    required this.salesMarketingAdminId,
    this.adminCode,
    required this.countryId,
    this.countryName,
    this.adminType = 'sales',
    this.assignmentType = 'sales_coverage',
    this.assignedById,
    required this.assignedAt,
    this.isActive = true,
    this.salesTarget,
    this.marketingBudget,
    this.performanceMetrics,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory SalesMarketingCountryAssignment.fromJson(Map<String, dynamic> json) {
    return SalesMarketingCountryAssignment(
      id: json['id'] ?? 0,
      salesMarketingAdminId: json['sales_marketing_admin'] ?? 0,
      adminCode: json['admin_code'],
      countryId: json['country'] ?? 0,
      countryName: json['country_name'],
      adminType: json['admin_type'] ?? 'sales',
      assignmentType: json['assignment_type'] ?? 'sales_coverage',
      assignedById: json['assigned_by'],
      assignedAt: json['assigned_at'] != null 
          ? DateTime.parse(json['assigned_at'])
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
      salesTarget: json['sales_target'] != null ? double.tryParse(json['sales_target'].toString()) : null,
      marketingBudget: json['marketing_budget'] != null ? double.tryParse(json['marketing_budget'].toString()) : null,
      performanceMetrics: json['performance_metrics'] != null ? Map<String, dynamic>.from(json['performance_metrics']) : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sales_marketing_admin': salesMarketingAdminId,
      'country': countryId,
      'admin_type': adminType,
      'assignment_type': assignmentType,
      'assigned_by': assignedById,
      'assigned_at': assignedAt.toIso8601String(),
      'is_active': isActive,
      'sales_target': salesTarget,
      'marketing_budget': marketingBudget,
      'performance_metrics': performanceMetrics,
      'notes': notes,
    };
  }

  bool get isSales => adminType == 'sales' || adminType == 'both';
  bool get isMarketing => adminType == 'marketing' || adminType == 'both';
}

/// Admin Chat Relationship - direct chat connection between admins
class AdminChatRelationship {
  final int id;
  final int admin1Id;
  final String admin1Code;
  final String? admin1Name;
  final String? admin1Type;
  final int admin2Id;
  final String admin2Code;
  final String? admin2Name;
  final String? admin2Type;
  final String relationshipType; // 'country_linked', 'hierarchical', 'functional', etc.
  final int? countryId;
  final String? countryName;
  final bool canChatDirectly;
  final Map<String, dynamic>? chatPermissions;
  final String? chatRoomId;
  final DateTime? lastChatAt;
  final int chatCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminChatRelationship({
    required this.id,
    required this.admin1Id,
    required this.admin1Code,
    this.admin1Name,
    this.admin1Type,
    required this.admin2Id,
    required this.admin2Code,
    this.admin2Name,
    this.admin2Type,
    this.relationshipType = 'country_linked',
    this.countryId,
    this.countryName,
    this.canChatDirectly = true,
    this.chatPermissions,
    this.chatRoomId,
    this.lastChatAt,
    this.chatCount = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminChatRelationship.fromJson(Map<String, dynamic> json) {
    return AdminChatRelationship(
      id: json['id'] ?? 0,
      admin1Id: json['admin1'] ?? 0,
      admin1Code: json['admin1_code'] ?? '',
      admin1Name: json['admin1_name'],
      admin1Type: json['admin1_type'],
      admin2Id: json['admin2'] ?? 0,
      admin2Code: json['admin2_code'] ?? '',
      admin2Name: json['admin2_name'],
      admin2Type: json['admin2_type'],
      relationshipType: json['relationship_type'] ?? 'country_linked',
      countryId: json['country_id'],
      countryName: json['country_name'],
      canChatDirectly: json['can_chat_directly'] ?? true,
      chatPermissions: json['chat_permissions'] != null ? Map<String, dynamic>.from(json['chat_permissions']) : null,
      chatRoomId: json['chat_room_id'],
      lastChatAt: json['last_chat_at'] != null ? DateTime.tryParse(json['last_chat_at']) : null,
      chatCount: json['chat_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin1': admin1Id,
      'admin2': admin2Id,
      'relationship_type': relationshipType,
      'country_id': countryId,
      'can_chat_directly': canChatDirectly,
      'chat_permissions': chatPermissions,
      'chat_room_id': chatRoomId,
      'last_chat_at': lastChatAt?.toIso8601String(),
      'chat_count': chatCount,
      'is_active': isActive,
    };
  }

  List<dynamic> get chatPartners => [
        {'id': admin1Id, 'code': admin1Code, 'name': admin1Name},
        {'id': admin2Id, 'code': admin2Code, 'name': admin2Name},
      ];
}

/// System Admin Chat Access - direct chat to system admin for issue reporting
class SystemAdminChatAccess {
  final int id;
  final int adminId;
  final String adminCode;
  final String? adminName;
  final int systemAdminId;
  final String systemAdminCode;
  final String? systemAdminName;
  final String? chatRoomId;
  final String? issueCategory;
  final String issuePriority; // 'critical', 'high', 'normal', 'low'
  final String? issueDescription;
  final DateTime? lastReportAt;
  final int reportCount;
  final String resolutionStatus; // 'open', 'in_progress', 'resolved', 'escalated', 'closed'
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SystemAdminChatAccess({
    required this.id,
    required this.adminId,
    required this.adminCode,
    this.adminName,
    required this.systemAdminId,
    required this.systemAdminCode,
    this.systemAdminName,
    this.chatRoomId,
    this.issueCategory,
    this.issuePriority = 'normal',
    this.issueDescription,
    this.lastReportAt,
    this.reportCount = 0,
    this.resolutionStatus = 'open',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SystemAdminChatAccess.fromJson(Map<String, dynamic> json) {
    return SystemAdminChatAccess(
      id: json['id'] ?? 0,
      adminId: json['admin'] ?? 0,
      adminCode: json['admin_code'] ?? '',
      adminName: json['admin_name'],
      systemAdminId: json['system_admin'] ?? 0,
      systemAdminCode: json['system_admin_code'] ?? '',
      systemAdminName: json['system_admin_name'],
      chatRoomId: json['chat_room_id'],
      issueCategory: json['issue_category'],
      issuePriority: json['issue_priority'] ?? 'normal',
      issueDescription: json['issue_description'],
      lastReportAt: json['last_report_at'] != null ? DateTime.tryParse(json['last_report_at']) : null,
      reportCount: json['report_count'] ?? 0,
      resolutionStatus: json['resolution_status'] ?? 'open',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin': adminId,
      'system_admin': systemAdminId,
      'issue_category': issueCategory,
      'issue_priority': issuePriority,
      'issue_description': issueDescription,
      'last_report_at': lastReportAt?.toIso8601String(),
      'report_count': reportCount,
      'resolution_status': resolutionStatus,
      'is_active': isActive,
    };
  }

  bool get isResolved => resolutionStatus == 'resolved' || resolutionStatus == 'closed';
}

/// HR Admin Assignment for Instructor
class HrAdminAssignment {
  final int? hrAdminId;
  final String? hrAdminCode;
  final String? hrAdminName;
  final DateTime? assignmentDate;
  final String? assignmentType; // 'country_based', 'specialization', 'performance', 'manual', 'auto'
  final int? assignmentCountryId;
  final String? assignmentCountryName;
  final String? assignmentNotes;

  HrAdminAssignment({
    this.hrAdminId,
    this.hrAdminCode,
    this.hrAdminName,
    this.assignmentDate,
    this.assignmentType,
    this.assignmentCountryId,
    this.assignmentCountryName,
    this.assignmentNotes,
  });

  factory HrAdminAssignment.fromJson(Map<String, dynamic> json) {
    return HrAdminAssignment(
      hrAdminId: json['hr_admin_id'],
      hrAdminCode: json['hr_admin_code'],
      hrAdminName: json['hr_admin_name'],
      assignmentDate: json['assignment_date'] != null ? DateTime.tryParse(json['assignment_date']) : null,
      assignmentType: json['assignment_type'],
      assignmentCountryId: json['assignment_country_id'],
      assignmentCountryName: json['assignment_country_name'],
      assignmentNotes: json['assignment_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hr_admin_id': hrAdminId,
      'assignment_date': assignmentDate?.toIso8601String(),
      'assignment_type': assignmentType,
      'assignment_country_id': assignmentCountryId,
      'assignment_notes': assignmentNotes,
    };
  }

  bool get hasHrAdmin => hrAdminId != null;
}