import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/features/profile/domain/entities/address_entity.dart';
import 'package:qatrah/features/profile/presentation/bloc/addresses_cubit.dart';
import 'package:qatrah/features/profile/presentation/bloc/addresses_state.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_state.dart';
import 'package:qatrah/features/profile/presentation/widgets/hierarchy_breadcrumb_selector.dart';

class AddressBottomSheetWidget extends StatefulWidget {
  const AddressBottomSheetWidget({this.initialAddress, super.key});

  final AddressEntity? initialAddress;

  @override
  State<AddressBottomSheetWidget> createState() =>
      _AddressBottomSheetWidgetState();
}

class _AddressBottomSheetWidgetState extends State<AddressBottomSheetWidget> {
  late final TextEditingController _titleController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialAddress?.title ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: BlocBuilder<EditProfileBloc, EditProfileState>(
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: _titleController,
                    hintText: context.l10n.addressName,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  10.verticalSpace,
                  const HierarchyBreadcrumbSelector(),
                  14.verticalSpace,
                  BlocBuilder<AddressesCubit, AddressesState>(
                    buildWhen: (p, c) => p.isSaving != c.isSaving,
                    builder: (context, addressState) {
                      return AppButton(
                        text: context.l10n.confirm,
                        isLoading: addressState.isSaving,
                        onPressed: addressState.isSaving
                            ? null
                            : () => _save(context, state),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(BuildContext context, EditProfileState state) async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedTitle = _titleController.text.trim();

    // If editing and nothing actually changed, just close without calling API.
    if (widget.initialAddress != null &&
        trimmedTitle == widget.initialAddress!.title.trim() &&
        state.selectedRegionId == widget.initialAddress!.regionId &&
        state.selectedUnitId == widget.initialAddress!.unitId &&
        state.selectedNeighborhoodId == widget.initialAddress!.neighborhoodId &&
        state.selectedZoneId == widget.initialAddress!.zoneId) {
      Navigator.of(context).pop();
      return;
    }

    final cubit = context.read<AddressesCubit>();
    final success = await cubit.submitAddress(
      title: trimmedTitle,
      regionId: state.selectedRegionId,
      unitId: state.selectedUnitId,
      neighborhoodId: state.selectedNeighborhoodId,
      zoneId: state.selectedZoneId,
      existingId: widget.initialAddress?.id,
    );

    if (!context.mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      final error = cubit.state.errorMessage ?? '';
      if (error == 'required_field') {
        getIt<ToastService>().showError(context.l10n.requiredField);
      } else if (error == 'duplicate_address_found') {
        getIt<ToastService>().showError(context.l10n.duplicateAddressFound);
      }
    }
  }
}
