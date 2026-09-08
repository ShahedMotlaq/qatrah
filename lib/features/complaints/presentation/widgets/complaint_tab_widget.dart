import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

class ComplaintTabWidget extends StatelessWidget {
  const ComplaintTabWidget({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inheritedIconColor = IconTheme.of(context).color;

    List<List> iconData;
    String tabText;

    switch (status) {
      case 'IN_PROGRESS':
        iconData = HugeIcons.strokeRoundedLoading03;
        tabText = l10n.statusInProgress;
      case 'RESOLVED':
        iconData = HugeIcons.strokeRoundedTaskDone01;
        tabText = l10n.statusResolved;
      case 'REJECTED':
        iconData = HugeIcons.strokeRoundedTaskRemove01;
        tabText = l10n.statusRejected;
      case 'PENDING':
      default:
        iconData = HugeIcons.strokeRoundedBookOpen01;
        tabText = l10n.statusPending;
    }

    // Return the tab widget built to best standards
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppIconWidget(
            applyPadding: false,
            icon: iconData,
            color: inheritedIconColor,
          ),
          4.verticalSpace,
          Flexible(
            child: Text(
              tabText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
