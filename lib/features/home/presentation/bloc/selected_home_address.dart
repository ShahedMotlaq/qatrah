import 'package:qatrah/core/local_storage/secure_storage.dart'
    show SecureStorage;

/// Holds the IDs and display name of the user's selected home address.
///
/// This is read from [SecureStorage] on bloc initialisation so the Home screen
/// can default to the address the citizen explicitly chose (e.g. in
/// My Addresses) rather than always falling back to the profile's
/// default location.
class SelectedHomeAddress {
  const SelectedHomeAddress({
    required this.addressId,
    required this.regionId,
    required this.unitId,
    required this.neighborhoodId,
    required this.locationName,
    this.zoneId,
  });

  final int addressId;
  final int regionId;
  final int unitId;
  final int neighborhoodId;
  final int? zoneId;
  final String locationName;
}
