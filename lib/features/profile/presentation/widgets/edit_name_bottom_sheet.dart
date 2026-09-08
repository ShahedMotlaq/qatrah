import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_state.dart';
import 'package:qatrah/features/profile/presentation/widgets/profile_error_message.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';

class EditNameBottomSheet extends StatefulWidget {
  const EditNameBottomSheet({required this.initialName, super.key});

  final String initialName;

  @override
  State<EditNameBottomSheet> createState() => _EditNameBottomSheetState();
}

class _EditNameBottomSheetState extends State<EditNameBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: BlocConsumer<EditProfileBloc, EditProfileState>(
        listenWhen: (previous, current) =>
            previous.isSuccess != current.isSuccess ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.isSuccess) {
            getIt<ToastService>().showSuccess(l10n.profileUpdatedSuccessfully);
            context.pop();
          }
          final error = state.errorMessage;
          if (error != null && error.isNotEmpty) {
            getIt<ToastService>().showError(profileErrorMessage(l10n, error));
          }
        },
        builder: (context, state) => Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _controller,
                hintText: l10n.fullName,
                onChanged: (value) => context.read<EditProfileBloc>().add(
                  NameChangedEvent(value),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.requiredField
                    : null,
              ),
              12.verticalSpace,
              AppButton(
                text: l10n.confirm,
                isLoading: state.isLoading,
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final trimmed = _controller.text.trim();
                          if (trimmed == widget.initialName.trim()) {
                            // Nothing changed – just close.
                            context.pop();
                            return;
                          }
                          context.read<EditProfileBloc>().add(
                            const SubmitProfileEvent(),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
