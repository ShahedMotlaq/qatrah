import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/utils/app_url_launcher.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/appdialog/showApp_bottom_sheet_widget.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_bloc.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_event.dart';
import 'package:qatrah/features/complaints/presentation/widgets/complaint_status_badge.dart';

class ComplaintCardWidget extends StatelessWidget {
  const ComplaintCardWidget({
    required this.complaintId,
    required this.title,
    required this.description,
    required this.status,
    required this.date,
    super.key,
    this.adminResponse,
    this.userName,
    this.userPhone,
    this.isAdminView = false,
  });

  final int complaintId;
  final String title;
  final String description;
  final String status;
  final String date;
  final String? adminResponse;
  final String? userName;
  final String? userPhone;
  final bool isAdminView;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              8.horizontalSpace,
              ComplaintStatusBadge(status: status),
            ],
          ),
          8.verticalSpace,
          Text(
            date,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          // ── Admin-only: Complainant info ──
          if (isAdminView &&
              (userName != null && userName!.isNotEmpty ||
                  userPhone != null && userPhone!.isNotEmpty)) ...[
            12.verticalSpace,
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withValues(
                  alpha: 0.25,
                ),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIconWidget(
                        icon: HugeIcons.strokeRoundedUser,
                        color: theme.colorScheme.tertiary,
                        size: 16,
                      ),
                      6.horizontalSpace,
                      Text(
                        l10n.complainantInfo,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  8.verticalSpace,
                  if (userName != null && userName!.isNotEmpty)
                    Text(
                      '${l10n.name}: $userName',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  if (userPhone != null && userPhone!.isNotEmpty) ...[
                    6.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.phoneNumber}: $userPhone',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        8.horizontalSpace,
                        FilledButton.icon(
                          onPressed: () =>
                              AppUrlLauncher.makePhoneCall(context, userPhone!),
                          icon: const Icon(Icons.phone, size: 16),
                          label: Text(l10n.call),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.tertiary,
                            foregroundColor: theme.colorScheme.onTertiary,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          12.verticalSpace,
          const Divider(height: 1),
          12.verticalSpace,
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),

          // ── Official Response — visible to all when present ──
          if (adminResponse != null && adminResponse!.isNotEmpty) ...[
            16.verticalSpace,
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppIconWidget(
                        icon: HugeIcons.strokeRoundedBuilding03,
                        color: Color(0xFF1B4D3E),
                        size: 18,
                      ),
                      8.horizontalSpace,
                      Text(
                        l10n.officialResponse,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B4D3E),
                        ),
                      ),
                    ],
                  ),
                  8.verticalSpace,
                  Text(
                    adminResponse!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Admin respond button ──
          if (isAdminView && status != 'RESOLVED' && status != 'REJECTED') ...[
            12.verticalSpace,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => _showRespondDialog(context),
                icon: const Icon(Icons.reply_rounded, size: 18),
                label: Text(l10n.respondToComplaint),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRespondDialog(BuildContext context) {
    final bloc = context.read<ComplaintsBloc>();
    final theme = Theme.of(context);
    showAppBottomSheet(
      context: context,
      title: context.l10n.respondToComplaint,
      titleIcon: Icon(
        Icons.reply_rounded,
        size: 20,
        color: theme.colorScheme.primary,
      ),
      content: BlocProvider<ComplaintsBloc>.value(
        value: bloc,
        child: _ComplaintResponseSheet(
          complaintId: complaintId,
          initialResponse: adminResponse,
          initialStatus: status,
        ),
      ),
    );
  }
}

class _ComplaintResponseSheet extends StatefulWidget {
  const _ComplaintResponseSheet({
    required this.complaintId,
    required this.initialStatus,
    this.initialResponse,
  });

  final int complaintId;
  final String initialStatus;
  final String? initialResponse;

  @override
  State<_ComplaintResponseSheet> createState() =>
      _ComplaintResponseSheetState();
}

class _ComplaintResponseSheetState extends State<_ComplaintResponseSheet> {
  late final TextEditingController _controller;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialResponse);
    _selectedStatus = widget.initialStatus == 'PENDING'
        ? 'IN_PROGRESS'
        : widget.initialStatus;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statuses = <String, String>{
      'IN_PROGRESS': l10n.statusInProgress,
      'RESOLVED': l10n.statusResolved,
      'REJECTED': l10n.statusRejected,
    };

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            items: statuses.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedStatus = value);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          12.verticalSpace,
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.complaintResponseHint,
              border: const OutlineInputBorder(),
            ),
          ),
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.sendResponse),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final text = _controller.text.trim();
    final originalResponse = widget.initialResponse?.trim() ?? '';

    // If nothing actually changed, just close without calling API.
    if (text == originalResponse && _selectedStatus == widget.initialStatus) {
      Navigator.of(context).pop();
      return;
    }

    if (text.isEmpty) return;

    context.read<ComplaintsBloc>().add(
      RespondToComplaintEvent(
        complaintId: widget.complaintId,
        response: text,
        status: _selectedStatus,
      ),
    );
    Navigator.of(context).pop();
  }
}
