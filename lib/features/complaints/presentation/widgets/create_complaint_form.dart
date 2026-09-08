// lib/features/complaints/presentation/widgets/create_complaint_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/widgets/appdialog/dynamic_form_dialog.dart';
import 'package:qatrah/core/widgets/formField_wrappers/app_dropdown_widget.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_bloc.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_event.dart';

Future<void> showCreateComplaintDialog(BuildContext context) async {
  final complaintsBloc = context.read<ComplaintsBloc>();

  return showDialog(
    context: context,
    builder: (dialogContext) => BlocProvider<ComplaintsBloc>.value(
      value: complaintsBloc,
      child: const _CreateComplaintForm(),
    ),
  );
}

class _CreateComplaintForm extends StatefulWidget {
  const _CreateComplaintForm();

  @override
  State<_CreateComplaintForm> createState() => _CreateComplaintFormState();
}

class _CreateComplaintFormState extends State<_CreateComplaintForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  String? _selectedCategoryLocalized;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final localizedCategories = [
      l10n.categoryNoWater,
      l10n.categoryWaterQuality,
      l10n.categoryLowPressure,
      l10n.categoryScheduleIssue,
      l10n.categoryOther,
    ];

    return DynamicFormDialog(
      title: l10n.createComplaintTitle,
      confirmBtnText: l10n.submitComplaint,
      cancelBtnText: l10n.cancel,
      onConfirm: () {
        if (_formKey.currentState!.validate()) {
          final categoryMap = {
            l10n.categoryNoWater: 'NO_WATER',
            l10n.categoryWaterQuality: 'WATER_QUALITY',
            l10n.categoryLowPressure: 'LOW_PRESSURE',
            l10n.categoryScheduleIssue: 'SCHEDULE_ISSUE',
            l10n.categoryOther: 'OTHER',
          };

          context.read<ComplaintsBloc>().add(
            CreateComplaintSubmittedEvent(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              category: categoryMap[_selectedCategoryLocalized] ?? 'OTHER',
            ),
          );
          Navigator.pop(context);
        }
      },
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDropdownField<String>(
              hintText: l10n.complaintCategoryLabel,
              value: _selectedCategoryLocalized,
              items: localizedCategories,
              onChanged: (val) =>
                  setState(() => _selectedCategoryLocalized = val),
              validator: (val) => val == null ? l10n.requiredField : null,
            ),
            16.verticalSpace,
            AppTextField(
              controller: _titleController,
              hintText: l10n.complaintTitleHint,
              prefixIcon: const AppIconWidget(
                icon: HugeIcons.strokeRoundedTask01,
              ),
              validator: (val) =>
                  (val == null || val.isEmpty) ? l10n.requiredField : null,
            ),
            16.verticalSpace,
            AppTextField(
              controller: _descController,
              hintText: l10n.complaintDescLabel,
              prefixIcon: const AppIconWidget(
                icon: HugeIcons.strokeRoundedNote,
              ),
              maxLines: 4,
              minLines: 2,
              keyboardType: TextInputType.multiline,
              validator: (val) =>
                  (val == null || val.isEmpty) ? l10n.requiredField : null,
            ),
          ],
        ),
      ),
    );
  }
}
