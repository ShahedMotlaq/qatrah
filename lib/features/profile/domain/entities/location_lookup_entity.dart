import 'package:equatable/equatable.dart';

class LocationLookupEntity extends Equatable {
  const LocationLookupEntity({required this.id, required this.name});

  final int id;
  final String name;

  @override
  String toString() => name;

  @override
  List<Object?> get props => [id, name];
}
