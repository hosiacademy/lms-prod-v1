// lib/src/data/models/location.dart

import 'package:equatable/equatable.dart';

class Country extends Equatable {
  final int id;
  final String name;
  final String code;
  final String? phoneCode;
  final int? phoneLength;
  final List<State>? states;

  const Country({
    required this.id,
    required this.name,
    required this.code,
    this.phoneCode,
    this.phoneLength,
    this.states,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      phoneCode: json['phone_code'] as String?,
      phoneLength: json['phone_length'] as int?,
      states: json['states'] != null
          ? (json['states'] as List)
              .map((state) => State.fromJson(state as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'phone_code': phoneCode,
      'phone_length': phoneLength,
    };
  }

  @override
  List<Object?> get props => [id, name, code, phoneCode, phoneLength];
}

class State extends Equatable {
  final int id;
  final String name;
  final String? code;
  final int countryId;
  final List<City>? cities;

  const State({
    required this.id,
    required this.name,
    this.code,
    required this.countryId,
    this.cities,
  });

  factory State.fromJson(Map<String, dynamic> json) {
    return State(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      countryId: (json['country'] is Map)
          ? (json['country']['id'] as int)
          : (json['country'] as int),
      cities: json['cities'] != null
          ? (json['cities'] as List)
              .map((city) => City.fromJson(city as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'country': countryId,
    };
  }

  @override
  List<Object?> get props => [id, name, code, countryId];
}

class City extends Equatable {
  final int id;
  final String name;
  final int stateId;

  const City({
    required this.id,
    required this.name,
    required this.stateId,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int,
      name: json['name'] as String,
      stateId: (json['state'] != null)
          ? (json['state'] is Map
              ? (json['state']['id'] as int? ?? 0)
              : (json['state'] as int? ?? 0))
          : (json['country_id'] as int? ??
              (json['country'] is Map
                  ? (json['country']['id'] as int? ?? 0)
                  : 0)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': stateId,
    };
  }

  @override
  List<Object?> get props => [id, name, stateId];
}
