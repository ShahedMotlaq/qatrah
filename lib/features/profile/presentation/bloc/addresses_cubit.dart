import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/events/profile_event_bus.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/services/connectivity_service.dart';
import 'package:qatrah/features/auth/domain/entities/user_entity.dart';
import 'package:qatrah/features/profile/domain/entities/address_entity.dart';
import 'package:qatrah/features/profile/domain/repositories/i_address_repository.dart';
import 'package:qatrah/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:qatrah/features/profile/presentation/bloc/addresses_state.dart';

class AddressesCubit extends Cubit<AddressesState> {
  AddressesCubit(
    this._repository,
    this._profileRepository,
    this._storage,
    this._connectivity,
  ) : super(const AddressesState());

  final IAddressRepository _repository;
  final IProfileRepository _profileRepository;
  final SecureStorage _storage;
  final ConnectivityService _connectivity;

  Future<void> loadAddresses() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final hasInternet = await _connectivity.hasInternetConnection();
    if (!hasInternet) {
      emit(state.copyWith(isLoading: false, errorMessage: 'no_internet'));
      return;
    }

    final selectedAddressId = await _storage.getSelectedHomeAddressId();
    final profileResult = await _profileRepository.getProfile();
    final defaultAddress = profileResult.fold<AddressEntity?>(
      (_) => null,
      _defaultAddressFromProfile,
    );

    final result = await _repository.getAddresses();
    await result.fold(
      (failure) async => emit(
        state.copyWith(isLoading: false, errorMessage: failure.errMessage),
      ),
      (addresses) async {
        final merged = _mergeDefaultAddress(defaultAddress, addresses);
        var normalized = _normalizeDefaults(merged);
        var normalizedDefault = normalized
            .where((a) => a.isDefault)
            .firstOrNull;

        // The default is resolved from the profile's default LOCATION. If the
        // server still flags a *different* address as default (e.g. the user
        // just changed their default location in the profile to a place they
        // had saved under another name), realign the server so the addresses
        // table matches the profile and the two can never diverge.
        final rawServerDefaultId = addresses
            .where((a) => a.isDefault && a.id > 0)
            .map((a) => a.id)
            .firstOrNull;
        if (normalizedDefault != null &&
            normalizedDefault.id > 0 &&
            normalizedDefault.id != rawServerDefaultId) {
          final serverDefault = await _setDefaultOnServer(normalizedDefault);
          normalized = _normalizeDefaults(
            normalized
                .map((a) => a.id == serverDefault.id ? serverDefault : a)
                .toList(),
          );
          normalizedDefault = normalized.where((a) => a.isDefault).firstOrNull;
        }

        // Home must follow the server default, not a stale local selection.
        final selectedId = normalizedDefault?.id;
        if (normalizedDefault != null && normalizedDefault.id > 0) {
          await _persistHomeAddress(normalizedDefault);
        } else if (selectedAddressId != null) {
          await _storage.clearSelectedHomeAddress();
        }

        emit(
          state.copyWith(
            isLoading: false,
            addresses: normalized,
            selectedAddressId: selectedId,
          ),
        );
      },
    );
  }

  Future<void> createAddress({
    required String title,
    required int regionId,
    required int unitId,
    required int neighborhoodId,
    required int zoneId,
  }) async {
    // Check for duplicate location
    if (_hasDuplicateLocation(
      regionId: regionId,
      unitId: unitId,
      neighborhoodId: neighborhoodId,
      zoneId: zoneId,
    )) {
      emit(state.copyWith(errorMessage: 'duplicate_address_found'));
      return;
    }

    final hasInternet = await _connectivity.hasInternetConnection();
    if (!hasInternet) {
      emit(state.copyWith(errorMessage: 'no_internet'));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _repository.createAddress(
      title: title,
      regionId: regionId,
      unitId: unitId,
      neighborhoodId: neighborhoodId,
      zoneId: zoneId,
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(isSaving: false, errorMessage: failure.errMessage),
      ),
      (address) async {
        final hadDefault = state.addresses.any((a) => a.isDefault && a.id > 0);
        final effectiveAddress =
            !hadDefault && !address.isDefault && address.id > 0
            ? await _setDefaultOnServer(address)
            : address;

        final normalized = _normalizeDefaults([
          ...state.addresses.where((a) => a.id != effectiveAddress.id),
          effectiveAddress,
        ]);
        final normalizedDefault = normalized
            .where((a) => a.isDefault)
            .firstOrNull;

        var newSelectedId = state.selectedAddressId;
        if (normalizedDefault != null && normalizedDefault.id > 0) {
          newSelectedId = normalizedDefault.id;
          await _persistHomeAddress(normalizedDefault);
          ProfileEventBus.instance.notifyProfileUpdated();
        }

        emit(
          state.copyWith(
            isSaving: false,
            addresses: normalized,
            selectedAddressId: newSelectedId,
          ),
        );
      },
    );
  }

  Future<void> updateAddress({
    required int id,
    required String title,
    required int regionId,
    required int unitId,
    required int neighborhoodId,
    required int zoneId,
  }) async {
    // Check for duplicate location (excluding current address)
    if (_hasDuplicateLocation(
      regionId: regionId,
      unitId: unitId,
      neighborhoodId: neighborhoodId,
      zoneId: zoneId,
      exceptAddressId: id,
    )) {
      emit(state.copyWith(errorMessage: 'duplicate_address_found'));
      return;
    }

    final hasInternet = await _connectivity.hasInternetConnection();
    if (!hasInternet) {
      emit(state.copyWith(errorMessage: 'no_internet'));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _repository.updateAddress(
      id: id,
      title: title,
      regionId: regionId,
      unitId: unitId,
      neighborhoodId: neighborhoodId,
      zoneId: zoneId,
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(isSaving: false, errorMessage: failure.errMessage),
      ),
      (updated) async {
        final next = state.addresses
            .map((a) => a.id == updated.id ? updated : a)
            .toList();
        final normalized = _normalizeDefaults(next);
        final defaultAddr = normalized.where((a) => a.isDefault).firstOrNull;
        if (defaultAddr != null && defaultAddr.id > 0) {
          await _persistHomeAddress(defaultAddr);
          ProfileEventBus.instance.notifyProfileUpdated();
        }
        emit(
          state.copyWith(
            isSaving: false,
            addresses: normalized,
            selectedAddressId: defaultAddr?.id,
          ),
        );
      },
    );
  }

  Future<void> deleteAddress(int id) async {
    final hasInternet = await _connectivity.hasInternetConnection();
    if (!hasInternet) {
      emit(state.copyWith(errorMessage: 'no_internet'));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _repository.deleteAddress(id);
    await result.fold(
      (failure) async => emit(
        state.copyWith(isSaving: false, errorMessage: failure.errMessage),
      ),
      (_) async {
        // Remove, then normalize. If the deleted address was the default,
        // normalization promotes a new one (newest remaining real address) so
        // the user is never left without a default while addresses remain.
        final remaining = state.addresses.where((a) => a.id != id).toList();
        final normalized = _normalizeDefaults(remaining);
        final normalizedDefault = normalized
            .where((a) => a.isDefault)
            .firstOrNull;

        var selectedId = state.selectedAddressId;
        if (state.selectedAddressId == id) {
          selectedId = normalizedDefault?.id;
          if (normalizedDefault == null || normalizedDefault.id <= 0) {
            await _storage.clearSelectedHomeAddress();
          } else {
            await _storage.setSelectedHomeAddress(
              addressId: normalizedDefault.id,
              regionId: normalizedDefault.regionId,
              unitId: normalizedDefault.unitId,
              neighborhoodId: normalizedDefault.neighborhoodId,
              zoneId: normalizedDefault.zoneId,
              locationName: normalizedDefault.homeLocationName,
            );
          }
          ProfileEventBus.instance.notifyProfileUpdated();
        }

        emit(
          state.copyWith(
            isSaving: false,
            addresses: normalized,
            selectedAddressId: selectedId,
            clearSelectedAddress: selectedId == null,
          ),
        );
      },
    );
  }

  Future<bool> submitAddress({
    required String title,
    required int? regionId,
    required int? unitId,
    required int? neighborhoodId,
    required int? zoneId,
    int? existingId,
  }) async {
    if (title.trim().isEmpty ||
        (regionId == null || regionId == 0) ||
        (unitId == null || unitId == 0) ||
        (neighborhoodId == null || neighborhoodId == 0) ||
        (zoneId == null || zoneId == 0)) {
      emit(state.copyWith(errorMessage: 'required_field'));
      return false;
    }

    if (existingId == null) {
      await createAddress(
        title: title.trim(),
        regionId: regionId,
        unitId: unitId,
        neighborhoodId: neighborhoodId,
        zoneId: zoneId,
      );
    } else {
      await updateAddress(
        id: existingId,
        title: title.trim(),
        regionId: regionId,
        unitId: unitId,
        neighborhoodId: neighborhoodId,
        zoneId: zoneId,
      );
    }
    return state.errorMessage == null || state.errorMessage!.trim().isEmpty;
  }

  bool _hasDuplicateLocation({
    required int regionId,
    required int unitId,
    required int neighborhoodId,
    required int zoneId,
    int? exceptAddressId,
  }) {
    return state.addresses.any(
      (address) =>
          address.regionId == regionId &&
          address.unitId == unitId &&
          address.neighborhoodId == neighborhoodId &&
          address.zoneId == zoneId &&
          (exceptAddressId == null || address.id != exceptAddressId),
    );
  }

  /// Resolves the default address from the profile's default LOCATION.
  ///
  /// The profile is the single source of truth for the default (it can only be
  /// changed there). We therefore match by location, not id: the saved address
  /// sitting at the profile's default location becomes the one and only
  /// default, and every other address is demoted. This is what resolves the
  /// conflict when the user changes their profile default to a place they had
  /// also saved under a custom name — that saved address simply becomes the
  /// default instead of producing a duplicate or a mismatched flag.
  ///
  /// When the profile's default location isn't saved as an address yet, the
  /// profile-derived entry is surfaced as a synthetic default and any stale
  /// server-side default flags are cleared.
  List<AddressEntity> _mergeDefaultAddress(
    AddressEntity? defaultAddress,
    List<AddressEntity> addresses,
  ) {
    if (defaultAddress == null || addresses.isEmpty) return addresses;

    final matchesProfileLocation = addresses.any(
      (a) => _sameLocation(a, defaultAddress),
    );

    if (matchesProfileLocation) {
      return addresses
          .map(
            (a) => a.copyWith(isDefault: _sameLocation(a, defaultAddress)),
          )
          .toList();
    }

    return [
      defaultAddress,
      ...addresses.map((a) => a.copyWith(isDefault: false)),
    ];
  }

  bool _sameLocation(AddressEntity a, AddressEntity b) =>
      a.regionId == b.regionId &&
      a.unitId == b.unitId &&
      a.neighborhoodId == b.neighborhoodId &&
      a.zoneId == b.zoneId;

  /// Guarantees exactly one address is marked default.
  ///
  /// Fixes "multiple defaults" whether they come from the server returning
  /// several `isDefault: true` rows or from merging the profile default with a
  /// saved default. The winner is the highest-priority default: a real saved
  /// address (id > 0) over the synthetic profile entry, and the newest (highest
  /// id) among those. If nothing is flagged, the newest real address is
  /// promoted so the list always has a single, well-defined default.
  List<AddressEntity> _normalizeDefaults(List<AddressEntity> addresses) {
    if (addresses.isEmpty) return addresses;

    final defaults = addresses.where((a) => a.isDefault).toList();
    final candidates = defaults.isNotEmpty ? defaults : addresses;
    final realCandidates = candidates.where((a) => a.id > 0).toList();
    final pool = realCandidates.isNotEmpty ? realCandidates : candidates;
    final winner = pool.reduce((a, b) => a.id >= b.id ? a : b);

    final normalized = addresses
        .map((a) => a.copyWith(isDefault: a.id == winner.id))
        .toList();

    // Default address always appears first
    normalized.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });

    return normalized;
  }

  AddressEntity? _defaultAddressFromProfile(UserEntity user) {
    if (!user.isCitizen || user.effectiveZoneId <= 0) return null;

    return AddressEntity(
      id: user.defaultAddressId > 0 ? user.defaultAddressId : -1,
      title: 'Default address',
      regionId: user.effectiveRegionId,
      regionName: user.effectiveRegionName ?? '',
      unitId: user.effectiveUnitId,
      unitName: user.effectiveUnitName ?? '',
      neighborhoodId: user.effectiveNeighborhoodId,
      neighborhoodName: user.effectiveNeighborhoodName ?? '',
      zoneId: user.effectiveZoneId,
      zoneName: user.effectiveZoneName ?? '',
      createdAt: '',
      isDefault: true,
    );
  }

  Future<void> _persistHomeAddress(AddressEntity address) async {
    if (address.id <= 0) return;
    await _storage.setSelectedHomeAddress(
      addressId: address.id,
      regionId: address.regionId,
      unitId: address.unitId,
      neighborhoodId: address.neighborhoodId,
      zoneId: address.zoneId,
      locationName: address.homeLocationName,
    );
  }

  Future<AddressEntity> _setDefaultOnServer(AddressEntity fallback) async {
    final result = await _repository.setDefaultAddress(fallback.id);
    return result.fold(
      (_) => fallback.copyWith(isDefault: true),
      (address) => address.copyWith(isDefault: true),
    );
  }
}
