import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/core/widgets/water_icon_avatar_widget.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_state.dart';
import 'package:qatrah/features/profile/presentation/widgets/hierarchy_breadcrumb_selector.dart';
import 'package:qatrah/features/profile/presentation/widgets/profile_error_message.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';

class CompleteProfileFormWidget extends StatefulWidget {
  const CompleteProfileFormWidget({super.key});

  @override
  State<CompleteProfileFormWidget> createState() =>
      _CompleteProfileFormWidgetState();
}

class _CompleteProfileFormWidgetState extends State<CompleteProfileFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    context.read<EditProfileBloc>().add(GetRegionsEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<EditProfileBloc, EditProfileState>(
      listener: (context, state) {
        if (state.isSuccess) {
          // Trigger HomeBloc to refresh the default location from updated profile
          try {
            context.read<HomeBloc>().add(RefreshProfileDefaultLocationEvent());
          } catch (e) {
            // HomeBloc might not be available in some contexts
          }

          getIt<ToastService>().showSuccess(l10n.profileCompletedSuccessfully);
          context.goNamed(Routes.navbar);
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          getIt<ToastService>().showError(
            profileErrorMessage(l10n, state.errorMessage!),
          );
        }
      },
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              20.verticalSpace,
              const WaterDropAvatarWidget(),
              20.verticalSpace,
              AppTextField(
                controller: _nameController,
                hintText: l10n.fullNameLabel,
                prefixIcon: const AppIconWidget(
                  icon: HugeIcons.strokeRoundedUser03,
                ),
                onChanged: (val) => context.read<EditProfileBloc>().add(
                  NameChangedEvent(val.trim()),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? l10n.requiredField
                    : null,
              ),

              if (state.user == null || state.isCitizen) ...[
                10.verticalSpace,
                // Region → Unit → Neighborhood → Zone, as a smart breadcrumb.
                const HierarchyBreadcrumbSelector(),
              ],

              20.verticalSpace,
              AppButton(
                isLoading: state.isLoading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<EditProfileBloc>().add(
                      const SubmitProfileEvent(isCompleteProfile: true),
                    );
                  }
                },
                text: l10n.saveAndContinue,
              ),
            ],
          ),
        );
      },
    );
  }
}
