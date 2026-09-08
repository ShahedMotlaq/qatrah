// lib/features/profile/presentation/bloc/profile_event.dart

import 'package:equatable/equatable.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadInitialProfileData extends ProfileEvent {}

class LoadUserLocationsEvent extends ProfileEvent {}

class GetRegionsEvent extends ProfileEvent {}

class ResetLocationSelectionEvent extends ProfileEvent {}

class LocationSelectionChanged extends ProfileEvent {
  const LocationSelectionChanged({
    required this.fieldType,
    required this.value,
    required this.isDefaultLocation,
    this.fromSavedLocation = false,
  });
  final String fieldType;
  final LocationLookupEntity value;
  final bool isDefaultLocation;
  final bool fromSavedLocation;

  @override
  List<Object?> get props => [
    fieldType,
    value,
    isDefaultLocation,
    fromSavedLocation,
  ];
}

class NameChangedEvent extends ProfileEvent {
  const NameChangedEvent(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

class SubmitProfileEvent extends ProfileEvent {
  const SubmitProfileEvent({this.isCompleteProfile = false});
  final bool isCompleteProfile;
  @override
  List<Object?> get props => [isCompleteProfile];
}

class NavigateAfterCompleteEvent extends ProfileEvent {
  const NavigateAfterCompleteEvent();
  @override
  List<Object?> get props => [];
}

class ResetFormEvent extends ProfileEvent {}

class ApplySavedLocationSelection extends ProfileEvent {
  const ApplySavedLocationSelection({
    required this.regionId,
    required this.unitId,
    required this.neighborhoodId,
    required this.zoneId,
  });
  final int regionId;
  final int unitId;
  final int neighborhoodId;
  final int zoneId;

  @override
  List<Object?> get props => [regionId, unitId, neighborhoodId, zoneId];
}
