// lib/features/profile/presentation/widgets/save_profile_button_widget.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_state.dart';

class SaveProfileButtonWidget extends StatelessWidget {
  const SaveProfileButtonWidget({required this.formKey, super.key});

  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<EditProfileBloc, EditProfileState>(
      buildWhen: (previous, current) => previous.isLoading != current.isLoading,
      builder: (context, state) {
        return AppButton(
          text: l10n.save,
          isLoading: state.isLoading, // Loading indicator shows when saving
          onPressed: () {
            if (formKey.currentState!.validate()) {
              context.read<EditProfileBloc>().add(
                const SubmitProfileEvent(),
              );
            }
          },
        );
      },
    );
  }
}
