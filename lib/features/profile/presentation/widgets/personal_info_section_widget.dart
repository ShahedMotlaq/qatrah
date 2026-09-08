import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_state.dart';

class PersonalInfoSectionWidget extends StatefulWidget {
  const PersonalInfoSectionWidget({
    super.key,
    this.isNameReadOnly = false,
    this.isPhoneReadOnly = true,
    this.hidePhone = false,
  });

  final bool isNameReadOnly;
  final bool isPhoneReadOnly;
  final bool hidePhone;

  @override
  State<PersonalInfoSectionWidget> createState() =>
      _PersonalInfoSectionWidgetState();
}

class _PersonalInfoSectionWidgetState extends State<PersonalInfoSectionWidget> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final state = context.read<EditProfileBloc>().state;
    _nameController = TextEditingController(text: state.user?.fullName ?? '');
    _phoneController = TextEditingController(
      text: state.user?.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocListener<EditProfileBloc, EditProfileState>(
      listenWhen: (prev, curr) => prev.user != curr.user,
      listener: (context, state) {
        if (state.user != null) {
          _nameController.text = state.user!.fullName;
          _phoneController.text = state.user!.phoneNumber;
        }
      },
      child: Column(
        children: [
          10.verticalSpace,
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12.r),
                    ),
                    color: theme.colorScheme.primary,
                  ),
                  width: double.maxFinite,
                  child: Row(
                    children: [
                      AppIconWidget(
                        icon: HugeIcons.strokeRoundedUser03,
                        color: theme.colorScheme.secondary,
                      ),
                      Text(
                        l10n.personalInformation,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                10.verticalSpace,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AppTextField(
                    prefixIcon: const AppIconWidget(
                      icon: HugeIcons.strokeRoundedUser03,
                    ),
                    controller: _nameController,
                    hintText: l10n.fullName,
                    readOnly: widget.isNameReadOnly,
                    onChanged: (val) => context.read<EditProfileBloc>().add(
                      NameChangedEvent(val.trim()),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? l10n.requiredField
                        : null,
                  ),
                ),
                if (!widget.hidePhone) ...[
                  16.verticalSpace,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AppTextField(
                      prefixIcon: const AppIconWidget(
                        icon: HugeIcons.strokeRoundedSmartPhone01,
                      ),
                      controller: _phoneController,
                      hintText: l10n.phoneNumber,
                      readOnly: widget.isPhoneReadOnly,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
                16.verticalSpace,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
