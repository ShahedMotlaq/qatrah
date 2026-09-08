import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/network/network_status_cubit.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_empty_state_widget.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_loading_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/core/widgets/appdialog/dynamic_confirm_dialog.dart';
import 'package:qatrah/core/widgets/appdialog/showApp_bottom_sheet_widget.dart';
import 'package:qatrah/core/widgets/offline_state_widget.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/address_pumping_status_sheet.dart';
import 'package:qatrah/features/profile/domain/entities/address_entity.dart';
import 'package:qatrah/features/profile/presentation/bloc/addresses_cubit.dart';
import 'package:qatrah/features/profile/presentation/bloc/addresses_state.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/widgets/address_bottom_sheet_widget.dart';
import 'package:qatrah/features/profile/presentation/widgets/address_card_widget.dart';

class MyAddressesPage extends StatefulWidget {
  const MyAddressesPage({super.key});

  @override
  State<MyAddressesPage> createState() => _MyAddressesPageState();
}

class _MyAddressesPageState extends State<MyAddressesPage> {
  late final EditProfileBloc _profileBloc;
  late final AddressesCubit _addressesCubit;

  @override
  void initState() {
    super.initState();
    _profileBloc = getIt<EditProfileBloc>()..add(GetRegionsEvent());
    _addressesCubit = getIt<AddressesCubit>()..loadAddresses();
  }

  @override
  void dispose() {
    _profileBloc.close();
    _addressesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _profileBloc),
        BlocProvider.value(value: _addressesCubit),
      ],
      child: Builder(
        builder: (context) {
          return MultiBlocListener(
            listeners: [
              // When connectivity is restored, automatically retry loading
              BlocListener<NetworkStatusCubit, NetworkStatusState>(
                listenWhen: (prev, curr) =>
                    !curr.isInitial &&
                    !curr.isChecking &&
                    prev.isOffline &&
                    curr.isOnline,
                listener: (context, _) =>
                    context.read<AddressesCubit>().loadAddresses(),
              ),
              // Snackbar for mutation errors (create / update / delete).
              // Validation errors (required_field, duplicate_address_found) are
              // already handled directly inside the bottom sheet widget.
              BlocListener<AddressesCubit, AddressesState>(
                listenWhen: (prev, curr) {
                  final msg = curr.errorMessage;
                  if (msg == null || msg == prev.errorMessage) return false;
                  if (!curr.addresses.isNotEmpty) return false;
                  return msg != 'required_field' &&
                      msg != 'duplicate_address_found';
                },
                listener: (context, state) {
                  final msg = state.errorMessage == 'no_internet'
                      ? context.l10n.noInternetConnection
                      : context.l10n.networkError;
                  getIt<ToastService>().showError(msg);
                },
              ),
            ],
            child: Scaffold(
              appBar: QatrahAppBarWidget(
                title: Text(context.l10n.myAddresses),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _openAddressSheet(context),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addNewAddress),
              ),
              body: AppBackground(
                child: BlocBuilder<AddressesCubit, AddressesState>(
                  buildWhen: (p, c) =>
                      p.isLoading != c.isLoading ||
                      p.errorMessage != c.errorMessage ||
                      p.addresses != c.addresses,
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: AppLoadingWidget(size: 60));
                    }

                    // Initial load failed → show branded offline/error view
                    if (state.errorMessage != null && state.addresses.isEmpty) {
                      return OfflineStateWidget(
                        onRetry: () =>
                            context.read<AddressesCubit>().loadAddresses(),
                      );
                    }

                    if (state.addresses.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.only(top: 20.h),
                        child: AppEmptyState(
                          message: context.l10n.noSavedAddresses,
                          icon: HugeIcons.strokeRoundedLocation01,
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(12.w, 20.h, 12.w, 12.h),
                      itemCount: state.addresses.length,
                      separatorBuilder: (_, _) => 10.verticalSpace,
                      itemBuilder: (context, index) {
                        final address = state.addresses[index];
                        return AddressCardWidget(
                          address: address,
                          isSelected: state.selectedAddressId == address.id,
                          onEdit: () => _openAddressSheet(
                            context,
                            initialAddress: address,
                          ),
                          onDelete: () => _deleteAddress(context, address.id),
                          onViewStatus: () =>
                              _openPumpingStatus(context, address),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAddressSheet(
    BuildContext context, {
    AddressEntity? initialAddress,
  }) async {
    final bloc = context.read<EditProfileBloc>();
    final addressesCubit = context.read<AddressesCubit>();
    if (initialAddress == null) {
      bloc.add(ResetLocationSelectionEvent());
    } else {
      bloc.add(
        ApplySavedLocationSelection(
          regionId: initialAddress.regionId,
          unitId: initialAddress.unitId,
          neighborhoodId: initialAddress.neighborhoodId,
          zoneId: initialAddress.zoneId,
        ),
      );
    }

    await showAppBottomSheet(
      context: context,
      title: initialAddress == null
          ? context.l10n.addNewAddress
          : '${context.l10n.edit} ${context.l10n.myAddresses}',
      titleIcon: AppIconWidget(
        icon: HugeIcons.strokeRoundedLocation04,
        color: Theme.of(context).colorScheme.primary,
      ),
      content: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: addressesCubit),
        ],
        child: AddressBottomSheetWidget(initialAddress: initialAddress),
      ),
    );
  }

  Future<void> _openPumpingStatus(
    BuildContext context,
    AddressEntity address,
  ) async {
    await showAppBottomSheet(
      context: context,
      title:
          '${context.l10n.currentPumpingStatus} · ${address.homeLocationName}',
      titleIcon: AppIconWidget(
        icon: HugeIcons.strokeRoundedDroplet,
        color: Theme.of(context).colorScheme.primary,
      ),
      content: AddressPumpingStatusSheet(
        zoneId: address.zoneId,
        neighborhoodId: address.neighborhoodId,
      ),
    );
  }

  void _deleteAddress(BuildContext context, int id) {
    showDialog<void>(
      context: context,
      builder: (_) => DynamicConfirmDialog(
        title: context.l10n.deleteAddressTitle,
        message: context.l10n.deleteAddressMessage,
        confirmBtnText: context.l10n.delete,
        cancelBtnText: context.l10n.cancel,
        isDangerousAction: true,
        onConfirm: () => context.read<AddressesCubit>().deleteAddress(id),
      ),
    );
  }
}
