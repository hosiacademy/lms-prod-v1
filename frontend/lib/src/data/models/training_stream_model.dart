// lib/src/data/models/training_stream_model.dart

import 'package:equatable/equatable.dart';

class TrainingStreamModel extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool active;

  const TrainingStreamModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.active,
  });

  factory TrainingStreamModel.fromJson(Map<String, dynamic> json) {
    return TrainingStreamModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'active': active,
    };
  }

  @override
  List<Object?> get props => [id, name, slug, description, active];
}

class MasterclassModel extends Equatable {
  final int id;
  final int streamId;
  final String masterclassType;
  final String title;
  final String slug;
  final String tier;
  final String focusArea;
  final String targetAudience;
  final String description;
  final double priceUsd;
  final int? aicertsCourseId;
  final bool isFeatured;
  final String launchPhase;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TrainingStreamModel? stream;

  const MasterclassModel({
    required this.id,
    required this.streamId,
    required this.masterclassType,
    required this.title,
    required this.slug,
    required this.tier,
    required this.focusArea,
    required this.targetAudience,
    required this.description,
    required this.priceUsd,
    this.aicertsCourseId,
    required this.isFeatured,
    required this.launchPhase,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.stream,
  });

  factory MasterclassModel.fromJson(Map<String, dynamic> json) {
    return MasterclassModel(
      id: json['id'],
      streamId: json['stream'],
      masterclassType: json['masterclass_type'],
      title: json['title'],
      slug: json['slug'],
      tier: json['tier'],
      focusArea: json['focus_area'] ?? '',
      targetAudience: json['target_audience'] ?? '',
      description: json['description'] ?? '',
      priceUsd: (json['price_usd'] as num).toDouble(),
      aicertsCourseId: json['aicerts_course'],
      isFeatured: json['is_featured'] ?? false,
      launchPhase: json['launch_phase'],
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      stream: json['stream_object'] != null
          ? TrainingStreamModel.fromJson(json['stream_object'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stream': streamId,
      'masterclass_type': masterclassType,
      'title': title,
      'slug': slug,
      'tier': tier,
      'focus_area': focusArea,
      'target_audience': targetAudience,
      'description': description,
      'price_usd': priceUsd,
      'aicerts_course': aicertsCourseId,
      'is_featured': isFeatured,
      'launch_phase': launchPhase,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isProfessional => priceUsd == 990.0;
  bool get isTechnical => priceUsd == 2310.0;

  String get tierDisplayName {
    switch (tier) {
      case 'tier_1':
        return isProfessional ? 'Foundational' : 'Core Technical';
      case 'tier_2':
        return isProfessional ? 'Functional Specialists' : 'Advanced Technical';
      case 'tier_3':
        return isProfessional ? 'Specialized Roles' : 'Specialized Technical';
      default:
        return tier;
    }
  }

  String get launchPhaseDisplay {
    switch (launchPhase) {
      case 'phase_1':
        return 'Phase 1 (Mar-May 2026)';
      case 'phase_2':
        return 'Phase 2 (Jun-Aug 2026)';
      case 'phase_3':
        return 'Phase 3 (Sep 2026-Feb 2027)';
      default:
        return launchPhase;
    }
  }

  String get priceDisplay => '\$${priceUsd.toStringAsFixed(0)} USD';

  @override
  List<Object?> get props => [
        id,
        streamId,
        masterclassType,
        title,
        slug,
        tier,
        focusArea,
        targetAudience,
        description,
        priceUsd,
        aicertsCourseId,
        isFeatured,
        launchPhase,
        active,
        createdAt,
        updatedAt,
        stream,
      ];
}

// lib/src/data/models/masterclass_schedule_model.dart

class MasterclassScheduleModel extends Equatable {
  final int id;
  final int masterclassId;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String country;
  final String status;
  final int currentParticipants;
  final int maxParticipants;
  final String notes;

  const MasterclassScheduleModel({
    required this.id,
    required this.masterclassId,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.country,
    required this.status,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.notes,
  });

  factory MasterclassScheduleModel.fromJson(Map<String, dynamic> json) {
    return MasterclassScheduleModel(
      id: json['id'] as int,
      masterclassId: json['masterclass'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      location: json['location'] as String? ?? '',
      country: json['country'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      currentParticipants: json['current_participants'] as int? ?? 0,
      maxParticipants: json['max_participants'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'masterclass': masterclassId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'location': location,
      'country': country,
      'status': status,
      'current_participants': currentParticipants,
      'max_participants': maxParticipants,
      'notes': notes,
    };
  }

  bool get hasAvailableSpots => currentParticipants < maxParticipants;
  int get availableSpots => maxParticipants - currentParticipants;

  @override
  List<Object?> get props => [
        id,
        masterclassId,
        startDate,
        endDate,
        location,
        country,
        status,
        currentParticipants,
        maxParticipants,
        notes,
      ];
}
