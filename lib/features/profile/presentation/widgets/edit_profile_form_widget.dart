// lib/features/profile/presentation/widgets/edit_profile_form_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_state.dart';
import 'package:qatrah/features/profile/presentation/widgets/location_section_widget.dart';
import 'package:qatrah/features/profile/presentation/widgets/personal_info_section_widget.dart';
import 'package:qatrah/features/profile/presentation/widgets/profile_error_message.dart';
import 'package:qatrah/features/profile/presentation/widgets/save_profile_button_widget.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';

class EditProfileFormWidget extends StatefulWidget {
  const EditProfileFormWidget({super.key});

  @override
  State<EditProfileFormWidget> createState() => _EditProfileFormWidgetState();
}

class _EditProfileFormWidgetState extends State<EditProfileFormWidget> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<EditProfileBloc, EditProfileState>(
      listenWhen: (previous, current) =>
          previous.isSuccess != current.isSuccess ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.isSuccess) {
          // Trigger HomeBloc to refresh the default location from updated profile
          try {
            context.read<HomeBloc>().add(RefreshProfileDefaultLocationEvent());
          } catch (e) {
            // HomeBloc might not be available in some contexts
          }

          getIt<ToastService>().showSuccess(l10n.profileUpdatedSuccessfully);

          // Refresh the profile data in the current EditProfileBloc
          context.read<EditProfileBloc>().add(LoadInitialProfileData());
          context.read<EditProfileBloc>().add(LoadUserLocationsEvent());

          // Close the bottom sheet instead of navigating to a new page
          context.pop();
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          getIt<ToastService>().showError(
            profileErrorMessage(l10n, state.errorMessage!),
          );
        }
      },
      child: BlocBuilder<EditProfileBloc, EditProfileState>(
        builder: (context, state) {
          final isEmployee = state.isEmployee;
          final isCitizen = state.isCitizen;

          return Form(
            key: _formKey,
            child: Column(
              children: [
                PersonalInfoSectionWidget(
                  isNameReadOnly: isEmployee, // Employee can't edit anything
                  hidePhone: isEmployee, // Hide phone for employee
                ),
                20.verticalSpace,
                LocationSectionWidget(
                  title: isEmployee
                      ? l10n.watchedLocation
                      : l10n.myDefaultLocation,
                  isDefaultLocation: isCitizen,
                  isReadOnly:
                      isEmployee, // Only employees can't edit location; citizens can
                ),
                20.verticalSpace,
                if (!isEmployee)
                  SaveProfileButtonWidget(
                    formKey: _formKey,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
