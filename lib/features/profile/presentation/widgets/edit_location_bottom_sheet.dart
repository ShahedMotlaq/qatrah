import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_state.dart';
import 'package:qatrah/features/profile/presentation/widgets/hierarchy_breadcrumb_selector.dart';
import 'package:qatrah/features/profile/presentation/widgets/profile_error_message.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';

class EditLocationBottomSheet extends StatefulWidget {
  const EditLocationBottomSheet({super.key});

  @override
  State<EditLocationBottomSheet> createState() =>
      _EditLocationBottomSheetState();
}

class _EditLocationBottomSheetState extends State<EditLocationBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: BlocListener<EditProfileBloc, EditProfileState>(
        listenWhen: (previous, current) =>
            previous.isSuccess != current.isSuccess ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.isSuccess) {
            try {
              context.read<HomeBloc>().add(
                RefreshProfileDefaultLocationEvent(),
              );
            } catch (_) {}

            getIt<ToastService>().showSuccess(l10n.profileUpdatedSuccessfully);

            context.read<EditProfileBloc>().add(LoadInitialProfileData());
            context.read<EditProfileBloc>().add(LoadUserLocationsEvent());
            context.pop();
          }

          final error = state.errorMessage;
          if (error != null && error.isNotEmpty) {
            getIt<ToastService>().showError(profileErrorMessage(l10n, error));
          }
        },
        child: BlocBuilder<EditProfileBloc, EditProfileState>(
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Same smooth chip breadcrumb used by add/edit address and
                    // complete-profile, so the location selector loads once and
                    // renders consistently across every screen.
                    const HierarchyBreadcrumbSelector(),
                    16.verticalSpace,
                    AppButton(
                      text: l10n.confirm,
                      isLoading: state.isLoading,
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          context.read<EditProfileBloc>().add(
                            const SubmitProfileEvent(),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
