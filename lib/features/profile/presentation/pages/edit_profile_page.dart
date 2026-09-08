import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/widgets/edit_profile_form_widget.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider(
      create: (context) =>
          getIt<EditProfileBloc>()..add(LoadInitialProfileData()),
      child: Scaffold(
        appBar: QatrahAppBarWidget(title: Text(l10n.editProfile)),
        body: const AppBackground(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: EditProfileFormWidget(),
          ),
        ),
      ),
    );
  }
}
