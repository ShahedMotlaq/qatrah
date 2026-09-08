import 'package:equatable/equatable.dart';
import 'package:qatrah/features/profile/domain/entities/address_entity.dart';

class AddressesState extends Equatable {
  const AddressesState({
    this.isLoading = false,
    this.isSaving = false,
    this.addresses = const <AddressEntity>[],
    this.selectedAddressId,
    this.errorMessage,
  });
  final bool isLoading;
  final bool isSaving;
  final List<AddressEntity> addresses;
  final int? selectedAddressId;
  final String? errorMessage;

  AddressesState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<AddressEntity>? addresses,
    int? selectedAddressId,
    String? errorMessage,
    bool clearError = false,
    bool clearSelectedAddress = false,
  }) {
    return AddressesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      addresses: addresses ?? this.addresses,
      selectedAddressId: clearSelectedAddress
          ? null
          : (selectedAddressId ?? this.selectedAddressId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSaving,
    addresses,
    selectedAddressId,
    errorMessage,
  ];
}
