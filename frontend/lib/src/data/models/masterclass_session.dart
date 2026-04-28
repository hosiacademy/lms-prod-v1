// lib/src/data/models/masterclass_session.dart

class MasterclassSession {
  final String title;
  final String dates;
  final String city;
  final String country;
  final String flag;
  final bool isProfessional;
  final String? focusArea;
  final double? priceUsd;
  final String? priceFormatted;
  final int? seatsRemaining;
  final bool isFull;

  const MasterclassSession({
    required this.title,
    required this.dates,
    required this.city,
    required this.country,
    required this.flag,
    required this.isProfessional,
    this.focusArea,
    this.priceUsd,
    this.priceFormatted,
    this.seatsRemaining,
    this.isFull = false,
  });
}
